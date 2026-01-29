---
title: Argument Matching in Mockito
impact: HIGH
impactDescription: ensures meaningful verification of method arguments
tags: java, tests, mockito, argument-captor, verification
---

## Argument Matching in Mockito

Capture and verify actual arguments instead of using `any()` matchers for DTOs and model objects.

### Rules

- **Do NOT** use `any(...)` for DTO/model objects in stubbing or verify calls
- Capture the real argument with `ArgumentCaptor` and assert relevant fields

**Incorrect:**

```java
@Test
void createOrder_validRequest_callsRepository() {
    // Using any() - doesn't verify actual data passed
    orderService.createOrder(new OrderRequest("product-1", 5));

    verify(orderRepository).save(any(Order.class));
}

@Test
void sendNotification_validUser_sendsEmail() {
    // any() hides what's actually being sent
    userService.notifyUser(user);

    verify(emailService).send(any(EmailMessage.class));
}
```

**Correct:**

```java
@Test
void createOrder_validRequest_savesCorrectOrder() {
    // Given
    var request = new OrderRequest("product-1", 5);
    var captor = ArgumentCaptor.forClass(Order.class);

    // When
    orderService.createOrder(request);

    // Then
    verify(orderRepository).save(captor.capture());

    Order actualOrder = captor.getValue();
    assertThat(actualOrder.getProductId()).isEqualTo("product-1");
    assertThat(actualOrder.getQuantity()).isEqualTo(5);
}

@Test
void sendNotification_validUser_sendsCorrectEmail() {
    // Given
    var user = new User("john@test.com", "John");
    var captor = ArgumentCaptor.forClass(EmailMessage.class);

    // When
    userService.notifyUser(user);

    // Then
    verify(emailService).send(captor.capture());

    EmailMessage actualMessage = captor.getValue();
    assertThat(actualMessage.getTo()).isEqualTo("john@test.com");
    assertThat(actualMessage.getSubject()).contains("John");
}
```

### When `any()` is Acceptable

Use `any()` only for:
- Primitive types where the exact value doesn't matter
- Simple types (String, Integer) when focus is on other behavior
- Verify that method was called at all (existence check)

```java
// OK - verifying call count, not data
verify(logger, times(3)).log(anyString());

// OK - primitive doesn't affect test focus
when(cache.get(anyString())).thenReturn(Optional.empty());
```

### ArgumentCaptor Best Practices

```java
// Declare at class level for reuse
@Captor
private ArgumentCaptor<Order> orderCaptor;

// Or create inline
var captor = ArgumentCaptor.forClass(Order.class);

// For collections
var listCaptor = ArgumentCaptor.forClass(List.class);

// Verify multiple calls
verify(repository, times(2)).save(captor.capture());
List<Order> allOrders = captor.getAllValues();
assertThat(allOrders).hasSize(2);
```