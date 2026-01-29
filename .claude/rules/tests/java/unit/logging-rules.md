---
title: Logging Output Verification
impact: MEDIUM
impactDescription: enables testing of log output and console messages
tags: java, tests, logging, output-capture, stdout, stderr
---

## Logging Output Verification

Use `OutputCaptureExtension` to capture and verify log output in tests.

### Rules

- When testing log output or stdout/stderr, use `@ExtendWith(OutputCaptureExtension.class)`
- Assert the captured output using the `CapturedOutput` parameter

**Incorrect:**

```java
@Test
void processOrder_success_logsMessage() {
    // No way to verify logs
    orderService.processOrder(order);

    // Can't assert anything about logging
}

// Using manual System.out capture - fragile
@Test
void processOrder_success_logsMessage() {
    ByteArrayOutputStream outContent = new ByteArrayOutputStream();
    System.setOut(new PrintStream(outContent));

    orderService.processOrder(order);

    assertThat(outContent.toString()).contains("Order processed");
    System.setOut(System.out); // Don't forget to reset!
}
```

**Correct:**

```java
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.springframework.boot.test.system.CapturedOutput;
import org.springframework.boot.test.system.OutputCaptureExtension;

@ExtendWith(OutputCaptureExtension.class)
class OrderServiceTest {

    private OrderService orderService = new OrderService();

    @Test
    void processOrder_success_logsOrderId(CapturedOutput output) {
        // Given
        var order = new Order("order-123", "product-1");

        // When
        orderService.processOrder(order);

        // Then
        assertThat(output.getOut()).contains("Processing order: order-123");
    }

    @Test
    void processOrder_failure_logsError(CapturedOutput output) {
        // Given
        var invalidOrder = new Order(null, "product-1");

        // When
        assertThatThrownBy(() -> orderService.processOrder(invalidOrder))
                .isInstanceOf(IllegalArgumentException.class);

        // Then
        assertThat(output.getErr()).contains("Invalid order");
    }

    @Test
    void cacheHit_secondCall_noLogOutput(CapturedOutput output) {
        // Given
        var key = "key-1";

        // When
        cacheService.getData(key); // First call - cache miss
        cacheService.getData(key); // Second call - cache hit

        // Then - verify method was called only once via log
        long callCount = output.getOut().lines()
                .filter(line -> line.contains("Loading from database"))
                .count();
        assertThat(callCount).isEqualTo(1);
    }
}
```

### CapturedOutput Methods

```java
// Get stdout content
output.getOut()

// Get stderr content
output.getErr()

// Get all output (stdout + stderr)
output.getAll()

// Use with standard assertions
assertThat(output.getOut()).contains("expected message");
assertThat(output.getOut()).doesNotContain("error");
assertThat(output.getErr()).isEmpty();
```

### Use Cases

1. **Verifying log messages** - ensure important events are logged
2. **Cache behavior** - verify cache hits/misses via log output
3. **Error logging** - verify errors are properly logged
4. **Debug output** - verify debug information is output correctly