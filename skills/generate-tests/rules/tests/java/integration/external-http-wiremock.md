---
title: External HTTP Client Test Rules (WireMock)
impact: HIGH
impactDescription: ensures proper HTTP client testing without mocking clients
tags: java, tests, integration, wiremock, http-client, resttemplate, webclient
---

## External HTTP Client Test Rules (WireMock)

Use WireMock for testing code that makes external HTTP calls. Never mock HTTP clients directly.

### Rules

- **DO NOT** mock HTTP clients (RestTemplate/WebClient/java.net.http.HttpClient/OkHttp)
- Tests **MUST** use `@WireMockTest` with setup method signature: `void setUp(WireMockRuntimeInfo runtimeInfo)`
- Obtain base URL from `runtimeInfo.getHttpBaseUrl()` and pass it to SUT via constructor/setter
- **DO NOT** use `wireMock.baseUrl()` - use `runtimeInfo.getHttpBaseUrl()`
- Prefer DI/config to control base URL
- **DO NOT** subclass or override SUT methods in tests to change base URL
- If you must mutate a private field, use `ReflectionTestUtils`
- **FORBID** manual server lifecycle: do NOT call `new ...Server().start()/stop()`
- Always include expected JSON body and Content-Type header matcher for request stubs

**Incorrect:**

```java
// Mocking the HTTP client - WRONG
@Test
void fetchData_validResponse_returnsData() {
    var mockRestTemplate = mock(RestTemplate.class);
    when(mockRestTemplate.getForObject(anyString(), eq(Data.class)))
            .thenReturn(new Data("test"));

    var result = service.fetchData();

    assertThat(result.getValue()).isEqualTo("test");
}

// Manual server lifecycle - WRONG
@Test
void fetchData_validResponse_returnsData() {
    WireMockServer server = new WireMockServer();
    server.start();
    // ...
    server.stop();
}

// Using wireMock.baseUrl() - WRONG
void setUp(WireMockRuntimeInfo runtimeInfo, WireMock wireMock) {
    service = new ExternalService(wireMock.baseUrl());
}
```

**Correct:**

```java
import com.github.tomakehurst.wiremock.junit5.WireMockRuntimeInfo;
import com.github.tomakehurst.wiremock.junit5.WireMockTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import static com.github.tomakehurst.wiremock.client.WireMock.*;
import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

@WireMockTest
class ExternalServiceTest {

    private ExternalService externalService;

    @BeforeEach
    void setUp(WireMockRuntimeInfo runtimeInfo) {
        // Pass base URL via constructor or setter
        externalService = new ExternalService(runtimeInfo.getHttpBaseUrl());
    }

    @Test
    void fetchData_validResponse_returnsData() {
        // Given
        stubFor(get("/api/data")
                .willReturn(aResponse()
                        .withStatus(200)
                        .withHeader("Content-Type", "application/json")
                        .withBody("""
                                {
                                    "id": "123",
                                    "value": "test-data"
                                }
                                """)));

        // When
        Data actualData = externalService.fetchData();

        // Then
        assertThat(actualData.getId()).isEqualTo("123");
        assertThat(actualData.getValue()).isEqualTo("test-data");

        // Verify request was made
        verify(getRequestedFor(urlEqualTo("/api/data")));
    }

    @Test
    void createResource_validRequest_sendsCorrectBody() {
        // Given
        stubFor(post("/api/resources")
                .withHeader("Content-Type", equalTo("application/json"))
                .withRequestBody(equalToJson("""
                        {
                            "name": "test-resource",
                            "type": "A"
                        }
                        """))
                .willReturn(aResponse()
                        .withStatus(201)
                        .withHeader("Content-Type", "application/json")
                        .withBody("""
                                {
                                    "id": "new-123",
                                    "name": "test-resource"
                                }
                                """)));

        // When
        var request = new CreateRequest("test-resource", "A");
        Resource actualResource = externalService.createResource(request);

        // Then
        assertThat(actualResource.getId()).isEqualTo("new-123");

        verify(postRequestedFor(urlEqualTo("/api/resources"))
                .withHeader("Content-Type", equalTo("application/json")));
    }

    @Test
    void fetchData_serverError_throwsServiceException() {
        // Given
        stubFor(get("/api/data")
                .willReturn(aResponse()
                        .withStatus(500)
                        .withBody("Internal Server Error")));

        // When-Then
        assertThatThrownBy(() -> externalService.fetchData())
                .isInstanceOf(ServiceException.class)
                .hasMessageContaining("Failed to fetch data");
    }

    @Test
    void fetchData_timeout_throwsServiceException() {
        // Given
        stubFor(get("/api/data")
                .willReturn(aResponse()
                        .withStatus(200)
                        .withFixedDelay(5000))); // Simulate timeout

        // When-Then
        assertThatThrownBy(() -> externalService.fetchData())
                .isInstanceOf(ServiceException.class);
    }
}
```

### Using ReflectionTestUtils for Private Fields

When you cannot modify the SUT constructor:

```java
@BeforeEach
void setUp(WireMockRuntimeInfo runtimeInfo) {
    externalService = new ExternalService();
    ReflectionTestUtils.setField(externalService, "baseUrl", runtimeInfo.getHttpBaseUrl());
}
```

### Key Points

1. Let WireMock extension manage server lifecycle
2. Always verify requests were made as expected
3. Include Content-Type headers in stubs
4. Use explicit JSON bodies, not serializers
5. Test error scenarios (500, timeout, etc.)