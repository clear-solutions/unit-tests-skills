---
title: Redis Cache Test Rules
impact: HIGH
impactDescription: ensures proper testing of Spring Cache with Redis backend
tags: java, tests, integration, redis, cache, testcontainers, spring-cache
---

## Redis Cache Test Rules

Use Testcontainers with GenericContainer for Redis cache tests. Verify caching behavior properly.

### Rules

- Use `@Testcontainers` with `GenericContainer` for Redis (image `"redis:7-alpine"` or latest)
- Use `@ImportAutoConfiguration(CacheAutoConfiguration.class)` to enable cache infrastructure
- Use `@SpringJUnitConfig({ClassName}.class)` to include class under test
- Use `@EnableCaching` to activate Spring Cache abstraction
- Use `@DirtiesContext` to reset context after each test method
- Use `@DynamicPropertySource` to inject container connection properties
- Autowire `CacheManager` to verify cache state in tests
- Autowire class under test (annotated with `@Cacheable`, `@CacheEvict`, `@CachePut`)
- Use `OutputCapture` (via `@ExtendWith(OutputCaptureExtension.class)`) to verify cache hits/misses via logging
- Verify cache behavior: first call = miss (method invoked), second call = hit (method NOT invoked)
- Test `@CachePut`, `@CacheEvict`, `@CacheEvict(allEntries=true)` operations
- Do NOT use `@SpringBootTest`
- Always verify cache state via `cacheManager.getCache("cacheName").get(key)`

**Incorrect:**

```java
// Using @SpringBootTest - too heavy
@SpringBootTest
class CachingServiceIT {
    // ...
}

// Not verifying actual cache behavior
@Test
void getData_called_returnsData() {
    var result = service.getData("key");
    assertThat(result).isNotNull();
    // Not testing caching!
}
```

**Correct:**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.ImportAutoConfiguration;
import org.springframework.boot.autoconfigure.cache.CacheAutoConfiguration;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.springframework.test.context.junit.jupiter.SpringJUnitConfig;
import org.testcontainers.containers.GenericContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;
import org.testcontainers.utility.DockerImageName;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@ImportAutoConfiguration(CacheAutoConfiguration.class)
@EnableCaching
@SpringJUnitConfig(DataService.class)
@DirtiesContext(classMode = DirtiesContext.ClassMode.AFTER_EACH_TEST_METHOD)
@ExtendWith(OutputCaptureExtension.class)
class DataServiceIT {

    @Container
    static final GenericContainer<?> redis = new GenericContainer<>(DockerImageName.parse("redis:7-alpine"))
            .withExposedPorts(6379);

    @DynamicPropertySource
    static void redisProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.data.redis.host", redis::getHost);
        registry.add("spring.data.redis.port", redis::getFirstMappedPort);
        registry.add("spring.cache.type", () -> "redis");
    }

    @Autowired
    private CacheManager cacheManager;

    @Autowired
    private DataService dataService;

    @Test
    void getData_firstCall_cacheMiss(CapturedOutput output) {
        // When - first call (cache miss)
        dataService.getData("key1");

        // Then - method was invoked (logged)
        assertThat(output.getOut()).contains("Loading data for key: key1");
    }

    @Test
    void getData_secondCall_cacheHit(CapturedOutput output) {
        // Given - first call to populate cache
        dataService.getData("key1");

        // Clear output
        output.getOut(); // consume previous output

        // When - second call (cache hit)
        dataService.getData("key1");

        // Then - method was NOT invoked again
        long callCount = output.getOut().lines()
                .filter(line -> line.contains("Loading data for key: key1"))
                .count();
        assertThat(callCount).isEqualTo(1); // Only from first call
    }

    @Test
    void getData_cachedValue_retrievedFromCache() {
        // Given
        var expectedData = dataService.getData("key1");

        // When
        var cachedValue = cacheManager.getCache("dataCache").get("key1");

        // Then
        assertThat(cachedValue).isNotNull();
        assertThat(cachedValue.get()).isEqualTo(expectedData);
    }

    @Test
    void deleteData_existingKey_evictsFromCache() {
        // Given - populate cache
        dataService.getData("key1");
        assertThat(cacheManager.getCache("dataCache").get("key1")).isNotNull();

        // When
        dataService.deleteData("key1");

        // Then
        assertThat(cacheManager.getCache("dataCache").get("key1")).isNull();
    }

    @Test
    void updateData_existingKey_updatesCacheEntry() {
        // Given - populate cache
        dataService.getData("key1");

        // When
        var updatedData = new Data("key1", "updated-value");
        dataService.updateData("key1", updatedData);

        // Then
        var cachedValue = cacheManager.getCache("dataCache").get("key1");
        assertThat(cachedValue).isNotNull();
        assertThat(((Data) cachedValue.get()).getValue()).isEqualTo("updated-value");
    }

    @Test
    void clearCache_evictsAllEntries() {
        // Given - populate cache with multiple entries
        dataService.getData("key1");
        dataService.getData("key2");
        assertThat(cacheManager.getCache("dataCache").get("key1")).isNotNull();
        assertThat(cacheManager.getCache("dataCache").get("key2")).isNotNull();

        // When
        dataService.clearAllData();

        // Then
        assertThat(cacheManager.getCache("dataCache").get("key1")).isNull();
        assertThat(cacheManager.getCache("dataCache").get("key2")).isNull();
    }
}
```

### Key Points

1. Use `@EnableCaching` to activate cache abstraction
2. Use `@ImportAutoConfiguration(CacheAutoConfiguration.class)`
3. Set `spring.cache.type=redis` in properties
4. Use `OutputCaptureExtension` to verify method invocation
5. Use `CacheManager` to inspect cache state
6. Test all cache operations: `@Cacheable`, `@CacheEvict`, `@CachePut`
7. Verify both cache miss (method called) and cache hit (method NOT called)