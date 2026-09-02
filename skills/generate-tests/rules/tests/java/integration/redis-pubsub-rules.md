---
title: Redis Pub/Sub Test Rules
impact: HIGH
impactDescription: ensures proper testing of Redis pub/sub messaging with containers
tags: java, tests, integration, redis, pubsub, testcontainers, messaging
---

## Redis Pub/Sub Test Rules

Use Testcontainers with GenericContainer for Redis pub/sub tests. Configure listener containers properly.

### Rules

- Use `@Testcontainers` with `GenericContainer` for Redis (image `"redis:7-alpine"` or latest)
- Use `@SpringJUnitConfig` to load only the component under test and inline TestConfig
- Use `@ImportAutoConfiguration(RedisAutoConfiguration.class)` to enable Redis infrastructure
- Use `@DynamicPropertySource` to inject container connection properties (host, port)
- Use `@DirtiesContext` to reset context after each test method
- Declare `ChannelTopic` and `RedisMessageListenerContainer` beans in inline `@TestConfiguration`
- Autowire `RedisTemplate<String, String>` for sending/receiving messages
- For Consumer tests: use `RedisTemplate.convertAndSend()` to send test messages
- For Producer tests: use Jedis subscriber or `RedisTemplate` for verification
- Use Awaitility for async assertions
- Set `spring.data.redis.host` and `spring.data.redis.port` via `@DynamicPropertySource`
- Do NOT use `@SpringBootTest`
- Do NOT use `@DataRedisTest` (it's for repositories, not Pub/Sub)
- Always set `ConnectionFactory` on `RedisTemplate` and `RedisMessageListenerContainer` beans

**Incorrect:**

```java
// Using @DataRedisTest for Pub/Sub - wrong!
@DataRedisTest
class NotificationPublisherIT {
    // DataRedisTest is for repositories
}

// Using @SpringBootTest - too heavy
@SpringBootTest
class NotificationPublisherIT {
    // ...
}
```

**Correct:**

```java
import org.awaitility.Awaitility;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.data.redis.RedisAutoConfiguration;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.listener.ChannelTopic;
import org.springframework.data.redis.listener.RedisMessageListenerContainer;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;
import redis.clients.jedis.Jedis;
import redis.clients.jedis.JedisPubSub;

import java.time.Duration;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@SpringJUnitConfig(classes = {NotificationPublisher.class, NotificationPublisherIT.TestConfig.class})
@ImportAutoConfiguration(RedisAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class NotificationPublisherIT {

    @Container
    static final GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void redisProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
    }

    @Autowired
    private ChannelTopic notificationTopic;

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Autowired
    private NotificationPublisher notificationPublisher;

    @Test
    void publish_validMessage_sendsToChannel() {
        // Given
        String[] receivedMessage = new String[1];

        Thread subscriberThread = new Thread(() -> {
            try (Jedis jedis = new Jedis(redis.getHost(), redis.getFirstMappedPort())) {
                jedis.subscribe(new JedisPubSub() {
                    @Override
                    public void onMessage(String channel, String message) {
                        receivedMessage[0] = message;
                        this.unsubscribe();
                    }
                }, notificationTopic.getTopic());
            }
        });
        subscriberThread.start();

        // Wait for subscriber to be ready
        Awaitility.await().pollDelay(Duration.ofMillis(500)).until(() -> true);

        // When
        notificationPublisher.publish("test notification message");

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> assertThat(receivedMessage[0]).isEqualTo("test notification message"));
    }

    @TestConfiguration
    static class TestConfig {

        @Bean
        public ChannelTopic notificationTopic() {
            return new ChannelTopic("notifications");
        }

        @Bean
        public RedisMessageListenerContainer redisMessageListenerContainer(
                RedisConnectionFactory connectionFactory) {
            RedisMessageListenerContainer container = new RedisMessageListenerContainer();
            container.setConnectionFactory(connectionFactory);
            return container;
        }
    }
}
```

### Consumer Test Template

```java
@Testcontainers
@SpringJUnitConfig(classes = {NotificationConsumer.class, NotificationConsumerIT.TestConfig.class})
@ImportAutoConfiguration(RedisAutoConfiguration.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
class NotificationConsumerIT {

    @Container
    static final GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void redisProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
    }

    @Autowired
    private ChannelTopic notificationTopic;

    @Autowired
    private RedisTemplate<String, String> redisTemplate;

    @Autowired
    private NotificationConsumer notificationConsumer;

    @Test
    void onMessage_validMessage_processesSuccessfully() {
        // When
        redisTemplate.convertAndSend(notificationTopic.getTopic(), "test message");

        // Then
        Awaitility.await()
                .atMost(Duration.ofSeconds(10))
                .untilAsserted(() -> {
                    // Verify consumer behavior
                    assertThat(true).isTrue(); // Replace with actual assertion
                });
    }

    @TestConfiguration
    static class TestConfig {

        @Bean
        public ChannelTopic notificationTopic() {
            return new ChannelTopic("notifications");
        }

        @Bean
        public RedisMessageListenerContainer redisMessageListenerContainer(
                RedisConnectionFactory connectionFactory) {
            RedisMessageListenerContainer container = new RedisMessageListenerContainer();
            container.setConnectionFactory(connectionFactory);
            return container;
        }
    }
}
```

### Key Points

1. Use `GenericContainer` with `redis:7-alpine` image
2. Configure `ChannelTopic` and `RedisMessageListenerContainer` in `@TestConfiguration`
3. Set `ConnectionFactory` on `RedisMessageListenerContainer`
4. Use Jedis for producer verification (subscribing)
5. Use `RedisTemplate.convertAndSend()` for consumer testing
6. Use Awaitility for async assertions