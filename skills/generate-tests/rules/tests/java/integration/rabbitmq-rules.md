---
title: RabbitMQ Test Rules
impact: HIGH
impactDescription: ensures proper testing of RabbitMQ producers and consumers with containers
tags: java, tests, integration, rabbitmq, testcontainers, messaging
---

## RabbitMQ Test Rules

Use Testcontainers with RabbitMQContainer for integration tests. Never use embedded or mocked brokers.

### Rules

- Use `@Testcontainers` with `RabbitMQContainer` for integration tests
- Use `@SpringJUnitConfig` to load only the component under test and inline QueueConfig
- Use `@ImportAutoConfiguration(RabbitAutoConfiguration.class)` to enable RabbitMQ infrastructure
- Use `RabbitMQContainer` with image `"rabbitmq:3-management"` (use latest)
- Use `@DynamicPropertySource` to inject container connection properties (host, port, username, password)
- Use `@DirtiesContext` to reset context after each test method
- Declare Queue beans in inline `@TestConfiguration` (not `@Configuration`)
- Set queue `durable=false` for tests (faster creation, auto-cleanup)
- Use `QueueBuilder.nonDurable().autoDelete()` for test queues
- For Consumer tests: autowire `RabbitTemplate` to send test messages
- For Producer tests: use `RabbitTemplate.receive()` for verification
- Use Awaitility for async assertions
- Do NOT use `@SpringBootTest`
- Do NOT manually create RabbitMQ connection/channel
- Do NOT use raw `com.rabbitmq.client` classes for verification

**Incorrect:**

```java
// Using @SpringBootTest - too heavy
@SpringBootTest
class OrderConsumerIT {
    // ...
}

// Manual connection management
@Test
void test() {
    ConnectionFactory factory = new ConnectionFactory();
    Connection connection = factory.newConnection();
    Channel channel = connection.createChannel();
    // ...
}
```

**Correct:**

```java
import org.junit.jupiter.api.Test;
import org.springframework.amqp.core.Message;
import org.springframework.amqp.core.Queue;
import org.springframework.amqp.core.QueueBuilder;
import org.springframework.amqp.rabbit.core.RabbitTemplate;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.amqp.RabbitAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.testcontainers.containers.RabbitMQContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import java.nio.charset.StandardCharsets;
import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;
import static org.awaitility.Awaitility.await;

@Testcontainers
@SpringJUnitConfig(classes = {OrderProducer.class, OrderProducerIT.QueueConfig.class})
@ImportAutoConfiguration(RabbitAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderProducerIT {

    @Container
    static final RabbitMQContainer rabbitMQ = new RabbitMQContainer(
            DockerImageName.parse("rabbitmq:3-management"));

    @DynamicPropertySource
    static void dynamicProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.rabbitmq.host", rabbitMQ::getHost);
        registry.add("spring.rabbitmq.port", rabbitMQ::getAmqpPort);
        registry.add("spring.rabbitmq.username", rabbitMQ::getAdminUsername);
        registry.add("spring.rabbitmq.password", rabbitMQ::getAdminPassword);
    }

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private OrderProducer orderProducer;

    @Test
    void sendMessage_validOrder_publishesToQueue() {
        // When
        orderProducer.sendMessage("test order message");

        // Then
        await().atMost(Duration.ofSeconds(10))
                .pollInterval(Duration.ofMillis(200))
                .untilAsserted(() -> {
                    Message message = rabbitTemplate.receive("orders-queue", 500);
                    assertThat(message).isNotNull();
                    String body = new String(message.getBody(), StandardCharsets.UTF_8);
                    assertThat(body).isEqualTo("test order message");
                });
    }

    @Test
    void sendMessage_multipleMessages_allDelivered() {
        // When
        orderProducer.sendMessage("message-1");
        orderProducer.sendMessage("message-2");

        // Then
        await().atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> {
                    Message msg1 = rabbitTemplate.receive("orders-queue", 500);
                    Message msg2 = rabbitTemplate.receive("orders-queue", 500);
                    assertThat(msg1).isNotNull();
                    assertThat(msg2).isNotNull();
                });
    }

    @TestConfiguration
    static class QueueConfig {

        @Bean
        public Queue ordersQueue() {
            return QueueBuilder.nonDurable("orders-queue")
                    .autoDelete()
                    .build();
        }
    }
}
```

### Consumer Test Template

```java
@Testcontainers
@SpringJUnitConfig(classes = {OrderConsumer.class, OrderConsumerIT.QueueConfig.class})
@ImportAutoConfiguration(RabbitAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class OrderConsumerIT {

    @Container
    static final RabbitMQContainer rabbitMQ = new RabbitMQContainer(
            DockerImageName.parse("rabbitmq:3-management"));

    @DynamicPropertySource
    static void dynamicProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.rabbitmq.host", rabbitMQ::getHost);
        registry.add("spring.rabbitmq.port", rabbitMQ::getAmqpPort);
        registry.add("spring.rabbitmq.username", rabbitMQ::getAdminUsername);
        registry.add("spring.rabbitmq.password", rabbitMQ::getAdminPassword);
    }

    @Autowired
    private RabbitTemplate rabbitTemplate;

    @Autowired
    private OrderConsumer orderConsumer;

    @Test
    void receiveMessage_validMessage_processesSuccessfully() {
        // When
        rabbitTemplate.convertAndSend("orders-queue", "test message");

        // Then
        await().atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> {
                    // Verify consumer behavior (logs, database state, etc.)
                    assertThat(true).isTrue(); // Replace with actual assertion
                });
    }

    @TestConfiguration
    static class QueueConfig {

        @Bean
        public Queue ordersQueue() {
            return QueueBuilder.nonDurable("orders-queue")
                    .autoDelete()
                    .build();
        }
    }
}
```

### Key Points

1. Use `RabbitMQContainer` with `rabbitmq:3-management` image
2. Declare test queues in inline `@TestConfiguration`
3. Use `QueueBuilder.nonDurable().autoDelete()` for test queues
4. Use `RabbitTemplate` for sending and receiving
5. Use Awaitility for async assertions
6. Clean context with `@DirtiesContext`