---
title: Controller Test Rules
impact: HIGH
impactDescription: ensures correct web layer testing with MockMvc patterns
tags: java, tests, controller, webmvc, mockmvc, spring
---

## Controller Test Rules

Test Spring controllers using `@WebMvcTest` for isolated web layer tests. Keep controller tests focused on HTTP concerns: request mapping, validation, serialization, and status codes.

### Test Setup

Use `@WebMvcTest` to load only the web layer for the target controller.

**FORBIDDEN:** Using `@SpringBootTest` for controller unit tests.

**Incorrect:**

```java
@SpringBootTest
@AutoConfigureMockMvc
class UserControllerTest {
    @Autowired
    private MockMvc mockMvc;
    // Loads the ENTIRE application context - slow!
}
```

**Correct:**

```java
@WebMvcTest(UserController.class)
class UserControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private UserService userService;

    @Test
    void getUser_existingId_returns200WithUser() throws Exception {
        // Given
        var expectedUser = new User("1", "John", "john@test.com");
        when(userService.findById("1")).thenReturn(expectedUser);

        // When-Then
        mockMvc.perform(get("/api/users/1"))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value("1"))
                .andExpect(jsonPath("$.name").value("John"))
                .andExpect(jsonPath("$.email").value("john@test.com"));
    }
}
```

### Key Annotations

| Annotation | Usage |
|------------|-------|
| `@WebMvcTest(Controller.class)` | Loads only web layer for the specified controller |
| `@MockitoBean` | Creates a Mockito mock and registers it in the Spring context (Spring Boot 3.4+) |
| `@MockBean` | Use this instead of `@MockitoBean` for Spring Boot versions below 3.4 |
| `@Autowired MockMvc` | Inject the MockMvc instance for request simulation |

**Note:** Use `@MockitoBean` (Spring Boot 3.4+). For Spring Boot < 3.4, use `@MockBean` from `org.springframework.boot.test.mock.mockito`.

### What to Test in Controllers

1. **Request mapping**: Correct URL, HTTP method, content type
2. **Request validation**: `@Valid` / `@Validated` annotations trigger validation
3. **Response status codes**: 200, 201, 400, 401, 403, 404, etc.
4. **Response body**: JSON structure via `jsonPath()` assertions
5. **Path variables and query parameters**: Correct binding
6. **Exception handling**: `@ControllerAdvice` / `@ExceptionHandler` responses

### Request Validation Testing

```java
@Test
void createUser_blankName_returns400() throws Exception {
    String requestJson = """
            {
                "name": "",
                "email": "john@test.com"
            }
            """;

    mockMvc.perform(post("/api/users")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(requestJson))
            .andExpect(status().isBadRequest());
}

@Test
void createUser_invalidEmail_returns400() throws Exception {
    String requestJson = """
            {
                "name": "John",
                "email": "not-an-email"
            }
            """;

    mockMvc.perform(post("/api/users")
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(requestJson))
            .andExpect(status().isBadRequest());
}
```

### Security Annotation Testing

When the controller uses `@PreAuthorize`, `@Secured`, or `@RolesAllowed`:

```java
@WebMvcTest(AdminController.class)
@Import(SecurityConfig.class) // Import your security configuration
class AdminControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @MockitoBean
    private AdminService adminService;

    @Test
    @WithMockUser(roles = "ADMIN")
    void deleteUser_adminRole_returns204() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
                .andExpect(status().isNoContent());
    }

    @Test
    @WithMockUser(roles = "USER")
    void deleteUser_userRole_returns403() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
                .andExpect(status().isForbidden());
    }

    @Test
    void deleteUser_unauthenticated_returns401() throws Exception {
        mockMvc.perform(delete("/api/admin/users/1"))
                .andExpect(status().isUnauthorized());
    }
}
```

### Service Exception Handling

Test how the controller handles exceptions thrown by the service layer:

```java
@Test
void getUser_nonExistentId_returns404() throws Exception {
    // Given
    when(userService.findById("999")).thenThrow(new UserNotFoundException("999"));

    // When-Then
    mockMvc.perform(get("/api/users/999"))
            .andExpect(status().isNotFound());
}
```

### Pagination and Query Parameters

```java
@Test
void listUsers_withPagination_returns200WithPage() throws Exception {
    // Given
    var page = new PageImpl<>(List.of(new User("1", "John", "john@test.com")));
    when(userService.findAll(any(Pageable.class))).thenReturn(page);

    // When-Then
    mockMvc.perform(get("/api/users")
                    .param("page", "0")
                    .param("size", "10"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.content").isArray())
            .andExpect(jsonPath("$.content[0].id").value("1"));
}
```
