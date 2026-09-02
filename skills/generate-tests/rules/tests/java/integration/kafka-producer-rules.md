---
title: Kafka Producer Test Rules
impact: HIGH
impactDescription: ensures proper testing of Kafka producers with consumer verification
tags: java, tests, integration, kafka, producer, testcontainers, embedded-kafka
---

## Kafka Producer Test Rules

Generate TWO test classes for Kafka producers: one with @EmbeddedKafka and one with @Testcontainers.

### Rules

- Use `@EmbeddedKafka` for unit tests and `@Testcontainers` with `ConfluentKafkaContainer` for integration tests
- Use `@SpringJUnitConfig` to load only the producer component under test
- Use `@ImportAutoConfiguration(KafkaAutoConfiguration.class)` to enable Kafka infrastructure
- Autowire `ConsumerFactory<String, String>` to create test consumer for verification
- Create test consumer via `consumerFactory.createConsumer()` in `@BeforeEach`
- Subscribe test consumer to the producer's target topic
- Use `KafkaTestUtils.getSingleRecord()` or manual polling for message verification
- Close test consumer in `@AfterEach` to prevent resource leaks
- Do NOT use `@SpringBootTest` or `MockitoExtension`
- Do NOT manually create KafkaConsumer via new operator (use ConsumerFactory)

### 1. Unit Test with @EmbeddedKafka

```java
import org.apache.kafka.clients.consumer.Consumer;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.test.context.EmbeddedKafka;
import org.springframework.kafka.test.utils.KafkaTestUtils;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.TestPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;

import java.time.Duration;
import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;

@EmbeddedKafka(partitions = 1, topics = {"orders-topic"})
@SpringJUnitConfig(classes = {OrderProducer.class})
@ImportAutoConfiguration(KafkaAutoConfiguration.class)
@TestPropertySource(properties = {
        "spring.kafka.bootstrap-servers=${spring.embedded.kafka.brokers}",
        "spring.kafka.consumer.auto-offset-reset=earliest"
})
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderProducerTest {

    @Autowired
    private OrderProducer orderProducer;

    @Autowired
    private ConsumerFactory<String, String> consumerFactory;

    private Consumer<String, String> kafkaConsumer;

    @BeforeEach
    void setUp() {
        kafkaConsumer = consumerFactory.createConsumer("test-group", "client-id");
        kafkaConsumer.subscribe(Collections.singletonList("orders-topic"));
    }

    @AfterEach
    void tearDown() {
        if (kafkaConsumer != null) {
            kafkaConsumer.close();
        }
    }

    @Test
    void send_validMessage_publishesToTopic() {
        // Given
        String key = "order-123";
        String value = """
                {"orderId": "123", "product": "test"}
                """;

        // When
        orderProducer.send(key, value);

        // Then
        ConsumerRecord<String, String> record = KafkaTestUtils.getSingleRecord(
                kafkaConsumer, "orders-topic", Duration.ofSeconds(10));

        assertThat(record.key()).isEqualTo(key);
        assertThat(record.value()).isEqualTo(value);
    }

    @Test
    void send_multipleMessages_publishesAll() {
        // When
        orderProducer.send("key-1", "value-1");
        orderProducer.send("key-2", "value-2");

        // Then
        var records = KafkaTestUtils.getRecords(kafkaConsumer, Duration.ofSeconds(10));

        assertThat(records.count()).isGreaterThanOrEqualTo(2);
    }
}
```

### 2. Integration Test with @Testcontainers

```java
import org.apache.kafka.clients.consumer.Consumer;
import org.awaitility.Awaitility;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.kafka.KafkaAutoConfiguration;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.kafka.ConfluentKafkaContainer;
import org.testcontainers.utility.DockerImageName;

import java.time.Duration;
import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@SpringJUnitConfig(OrderProducer.class)
@ImportAutoConfiguration(KafkaAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderProducerIT {

    @Container
    static final ConfluentKafkaContainer kafka = new ConfluentKafkaContainer(
            DockerImageName.parse("confluentinc/cp-kafka:7.5.0"));

    @DynamicPropertySource
    static void registerKafkaProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.kafka.bootstrap-servers", kafka::getBootstrapServers);
        registry.add("spring.kafka.consumer.auto-offset-reset", () -> "earliest");
    }

    @Autowired
    private OrderProducer orderProducer;

    @Autowired
    private ConsumerFactory<String, String> consumerFactory;

    private Consumer<String, String> kafkaConsumer;

    @BeforeEach
    void setUp() {
        kafkaConsumer = consumerFactory.createConsumer("test-group", "client-id");
        kafkaConsumer.subscribe(Collections.singletonList("orders-topic"));
    }

    @AfterEach
    void tearDown() {
        if (kafkaConsumer != null) {
            kafkaConsumer.close();
        }
    }

    @Test
    void send_validMessage_publishesToTopic() {
        // Given
        String key = "order-123";
        String value = """
                {"orderId": "123", "product": "test"}
                """;

        // When
        orderProducer.send(key, value);

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .untilAsserted(() -> {
                    var records = kafkaConsumer.poll(Duration.ofMillis(500));
                    assertThat(records).isNotEmpty();
                    var record = records.iterator().next();
                    assertThat(record.key()).isEqualTo(key);
                    assertThat(record.value()).isEqualTo(value);
                });
    }

    @Test
    void send_withCallback_executesOnSuccess() {
        // Given
        var callbackInvoked = new java.util.concurrent.atomic.AtomicBoolean(false);

        // When
        orderProducer.sendWithCallback("key", "value", (metadata, exception) -> {
            if (exception == null) {
                callbackInvoked.set(true);
            }
        });

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> assertThat(callbackInvoked.get()).isTrue());
    }
}
```

### Key Points

1. Use `ConsumerFactory` to create test consumers (not `new KafkaConsumer()`)
2. Always close consumers in `@AfterEach`
3. Subscribe to the correct topic before sending
4. Use `KafkaTestUtils` for convenient record retrieval
5. Use Awaitility for async assertions in integration tests
6. Clean context with `@DirtiesContext` after each test