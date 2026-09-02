---
title: ConfigurationProperties Test Rules
impact: MEDIUM
impactDescription: ensures configuration properties are properly loaded and validated
tags: java, tests, integration, configuration, properties, spring-boot
---

## ConfigurationProperties Test Rules

Generate TWO test classes for `@ConfigurationProperties` classes: unit test and integration test.

### Rules

- Generate unit test (no Spring context) for validation and defaults
- Generate integration test with `@SpringBootTest` and custom yml config file
- Integration test file should be named `{PropertiesClassName}IT`
- Create a test YAML file with test configuration data

**Incorrect:**

```java
// Only unit test - doesn't verify Spring binding
@Test
void properties_validValues_setsFields() {
    var props = new AppProperties();
    props.setName("test");
    assertThat(props.getName()).isEqualTo("test");
}

// Using application.yml - affects production config
@SpringBootTest
class AppPropertiesIT {
    // Uses main application.yml - wrong!
}
```

**Correct:**

### 1. Unit Test (No Spring Context)

```java
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;

class AppPropertiesTest {

    @Test
    void defaultValues_notSet_returnsDefaults() {
        // Given
        var properties = new AppProperties();

        // Then
        assertThat(properties.getTimeout()).isEqualTo(30); // default value
        assertThat(properties.isEnabled()).isTrue(); // default value
    }

    @Test
    void setName_validValue_setsField() {
        // Given
        var properties = new AppProperties();

        // When
        properties.setName("test-app");

        // Then
        assertThat(properties.getName()).isEqualTo("test-app");
    }

    @Test
    void setters_allFields_setsCorrectly() {
        // Given
        var properties = new AppProperties();

        // When
        properties.setName("my-app");
        properties.setTimeout(60);
        properties.setEnabled(false);
        properties.setEndpoint("http://localhost:8080");

        // Then
        assertThat(properties.getName()).isEqualTo("my-app");
        assertThat(properties.getTimeout()).isEqualTo(60);
        assertThat(properties.isEnabled()).isFalse();
        assertThat(properties.getEndpoint()).isEqualTo("http://localhost:8080");
    }

    @Test
    void nestedProperties_validValues_setsNestedFields() {
        // Given
        var properties = new AppProperties();
        var security = new AppProperties.SecurityProperties();

        // When
        security.setApiKey("secret-key");
        security.setTokenExpiry(3600);
        properties.setSecurity(security);

        // Then
        assertThat(properties.getSecurity().getApiKey()).isEqualTo("secret-key");
        assertThat(properties.getSecurity().getTokenExpiry()).isEqualTo(3600);
    }
}
```

### 2. Integration Test with Custom YAML

First, create the test YAML file at `src/test/java/{package}/app-properties.yml`:

```yaml
# src/test/java/com/example/config/app-properties.yml
app:
  name: integration-test-app
  timeout: 120
  enabled: true
  endpoint: http://test-endpoint:9090
  security:
    api-key: test-api-key-12345
    token-expiry: 7200
```

Then create the integration test:

```java
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.context.TestConfiguration;

import static org.assertj.core.api.Assertions.assertThat;

@SpringBootTest(
        classes = {AppProperties.class, AppPropertiesIT.TestConfig.class},
        properties = {"spring.config.location=file:src/test/java/com/example/config/app-properties.yml"}
)
class AppPropertiesIT {

    @Autowired
    private AppProperties appProperties;

    @Test
    void name_fromYaml_loadsCorrectly() {
        assertThat(appProperties.getName()).isEqualTo("integration-test-app");
    }

    @Test
    void timeout_fromYaml_loadsCorrectly() {
        assertThat(appProperties.getTimeout()).isEqualTo(120);
    }

    @Test
    void enabled_fromYaml_loadsCorrectly() {
        assertThat(appProperties.isEnabled()).isTrue();
    }

    @Test
    void endpoint_fromYaml_loadsCorrectly() {
        assertThat(appProperties.getEndpoint()).isEqualTo("http://test-endpoint:9090");
    }

    @Test
    void securityApiKey_fromYaml_loadsNestedProperty() {
        assertThat(appProperties.getSecurity().getApiKey()).isEqualTo("test-api-key-12345");
    }

    @Test
    void securityTokenExpiry_fromYaml_loadsNestedProperty() {
        assertThat(appProperties.getSecurity().getTokenExpiry()).isEqualTo(7200);
    }

    @Test
    void allProperties_fromYaml_allLoadedCorrectly() {
        assertThat(appProperties.getName()).isNotNull();
        assertThat(appProperties.getTimeout()).isPositive();
        assertThat(appProperties.getEndpoint()).startsWith("http://");
        assertThat(appProperties.getSecurity()).isNotNull();
        assertThat(appProperties.getSecurity().getApiKey()).isNotEmpty();
    }

    @TestConfiguration
    @EnableConfigurationProperties(AppProperties.class)
    static class TestConfig {
    }
}
```

### 3. Validation Tests (MANDATORY)

**CRITICAL: Always generate negative test cases for validation annotations!**

For each validation annotation (`@NotBlank`, `@NotNull`, `@Pattern`, `@Valid`, custom validators), create test cases that verify validation FAILS with invalid input.

```java
import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class AppPropertiesValidationTest {

    private Validator validator;

    @BeforeEach
    void setUp() {
        validator = Validation.buildDefaultValidatorFactory().getValidator();
    }

    // @NotBlank validation
    @Test
    void name_blank_failsValidation() {
        // Given
        var properties = new AppProperties();
        properties.setName("   "); // blank

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations)
                .extracting(v -> v.getPropertyPath().toString())
                .contains("name");
    }

    @Test
    void name_null_failsValidation() {
        // Given
        var properties = new AppProperties();
        properties.setName(null);

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations)
                .extracting(v -> v.getPropertyPath().toString())
                .contains("name");
    }

    // @Pattern validation
    @Test
    void currency_invalidPattern_failsValidation() {
        // Given
        var properties = new AppProperties();
        properties.setCurrency("usd"); // lowercase - invalid

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations)
                .extracting(v -> v.getPropertyPath().toString())
                .contains("currency");
    }

    @Test
    void currency_tooShort_failsValidation() {
        // Given
        var properties = new AppProperties();
        properties.setCurrency("US"); // only 2 chars

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations)
                .extracting(v -> v.getPropertyPath().toString())
                .contains("currency");
    }

    // @Valid on nested objects - validation propagates
    @Test
    void nestedCredentials_invalidApiKey_failsValidation() {
        // Given
        var properties = new AppProperties();
        var credentials = new AppProperties.Credentials();
        credentials.setApiKey(""); // blank - invalid
        properties.setCredentials(credentials);

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations)
                .extracting(v -> v.getPropertyPath().toString())
                .contains("credentials.apiKey");
    }

    // Custom validators
    @Test
    void items_duplicateValues_failsCustomValidation() {
        // Given
        var properties = new AppProperties();
        properties.setItems(List.of(
                new Item("key1", "value1"),
                new Item("key1", "value2") // duplicate key - violates @UniqueByProperty
        ));

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations).isNotEmpty();
        assertThat(violations)
                .extracting(ConstraintViolation::getMessage)
                .anyMatch(msg -> msg.contains("unique") || msg.contains("duplicate"));
    }

    // Positive cases - valid values pass
    @Test
    void allFields_validValues_passesValidation() {
        // Given
        var properties = createValidProperties();

        // When
        Set<ConstraintViolation<AppProperties>> violations = validator.validate(properties);

        // Then
        assertThat(violations).isEmpty();
    }

    private AppProperties createValidProperties() {
        var properties = new AppProperties();
        properties.setName("valid-name");
        properties.setCurrency("USD");
        // ... set all required fields with valid values
        return properties;
    }
}
```

### Key Points

1. Unit test verifies setters/getters and default values
2. Integration test verifies Spring binding from YAML
3. **Validation test verifies constraints with invalid input (MANDATORY)**
4. Create separate test YAML file (not main application.yml)
5. Use `spring.config.location` to point to test YAML
6. Test every property to ensure it loads correctly
7. Test nested properties separately
8. Include `@EnableConfigurationProperties` in `@TestConfiguration`

### Validation Test Cases Checklist

For each field, generate test cases based on its annotations:

| Annotation | Negative Test Cases |
|------------|---------------------|
| `@NotBlank` | blank string `"   "`, empty string `""`, `null` |
| `@NotNull` | `null` value |
| `@NotEmpty` | empty collection/string, `null` |
| `@Pattern` | values that don't match regex (wrong case, wrong length, wrong format) |
| `@Min/@Max` | values below min, values above max |
| `@Size` | values shorter than min, values longer than max |
| `@Email` | invalid email format |
| `@Valid` (nested) | nested object with invalid fields |
| Custom validators | values that violate custom logic (duplicates, invalid combinations) |

**CRITICAL: If a class has ANY validation annotation, you MUST generate negative test cases for it.**