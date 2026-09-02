---
title: Kafka Consumer Test Rules
impact: HIGH
impactDescription: ensures proper testing of Kafka consumers with embedded and container-based brokers
tags: java, tests, integration, kafka, consumer, testcontainers, embedded-kafka
---

## Kafka Consumer Test Rules

Generate TWO test classes for Kafka consumers: one with @EmbeddedKafka and one with @Testcontainers.

### Rules

- Use `@EmbeddedKafka` for unit tests and `@Testcontainers` with `ConfluentKafkaContainer` for integration tests
- Use `@SpringJUnitConfig` to load only the component under test (no `@SpringBootTest`)
- Use `@ImportAutoConfiguration(KafkaAutoConfiguration.class)` to enable Kafka infrastructure
- Use `@DirtiesContext` to reset context after each test
- Autowire `KafkaTemplate` for sending test messages
- For integration tests: use `@MockitoSpyBean` to verify listener method calls
- Use Awaitility for async assertions
- Set `spring.kafka.consumer.auto-offset-reset=earliest` to read from topic start
- Do NOT use `@SpringBootTest` or `MockitoExtension`
- Do NOT manually create topics (rely on auto-creation or `@EmbeddedKafka` topics parameter)

### 1. Unit Test with @EmbeddedKafka

```java
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

@EmbeddedKafka(partitions = 1, topics = {"orders-topic"})
@ImportAutoConfiguration(KafkaAutoConfiguration.class)
@SpringJUnitConfig(OrderConsumer.class)
@TestPropertySource(properties = {
        "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.consumer.auto-offset-reset=earliest"
})
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderConsumerTest {

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Test
    void listen_validMessage_processesSuccessfully() {
        // Given
        String message = """
                {"orderId": "123", "product": "test"}
                """;

        // When
        kafkaTemplate.send("orders-topic", "key-1", message);

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> {
                    // Assert expected behavior (e.g., database state, logs, etc.)
                    assertThat(true).isTrue(); // Replace with actual assertion
                });
    }

    @Test
    void listen_invalidMessage_handlesGracefully() {
        // Given
        String invalidMessage = "invalid-json";

        // When
        kafkaTemplate.send("orders-topic", "key-2", invalidMessage);

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> {
                    // Assert error handling behavior
                });
    }
}
```

### 2. Integration Test with @Testcontainers

```java
import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.bean.override.mockito.MockitoSpyBean;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;

import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.times;
import static org.mockito.Mockito.verify;

@Testcontainers
@SpringJUnitConfig(OrderConsumer.class)
@ImportAutoConfiguration(KafkaAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderConsumerIT {

    @Container
    static final ConfluentKafkaContainer kafka = new ConfluentKafkaContainer(
            DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));

    @DynamicPropertySource
    static void dynamicProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        registry.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
    }

    @MockitoSpyBean
    private OrderConsumer orderConsumer;

    @Autowired
    private KafkaTemplate<String, String> kafkaTemplate;

    @Test
    void listen_validMessage_invokesListener() {
        // Given
        String message = """
                {"orderId": "123", "product": "test"}
                """;

        // When
        kafkaTemplate.send("orders-topic", "key-1", message);

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> verify(orderConsumer, times(1)).listen(anyString()));
    }

    @Test
    void listen_multipleMessages_processesAll() {
        // Given-When
        kafkaTemplate.send("orders-topic", "key-1", "message-1");
        kafkaTemplate.send("orders-topic", "key-2", "message-2");
        kafkaTemplate.send("orders-topic", "key-3", "message-3");

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(15))
                .untilAsserted(() -> verify(orderConsumer, times(3)).listen(anyString()));
    }
}
```

### Key Points

1. Use `@EmbeddedKafka` for fast unit tests
2. Use `@Testcontainers` for realistic integration tests
3. Always set `auto-offset-reset=earliest`
4. Use Awaitility for async assertions
5. Use `@MockitoSpyBean` to verify listener invocations
6. Clean context with `@DirtiesContext` after each test