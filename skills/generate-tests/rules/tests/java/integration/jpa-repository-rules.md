---
title: JPA Repository Test Rules
impact: HIGH
impactDescription: ensures proper database testing with real database containers
tags: java, tests, integration, jpa, repository, testcontainers, database
---

## JPA Repository Test Rules

Use Testcontainers with `@DataJpaTest` for repository tests. Never use embedded databases or mock repositories.

### Rules

- **MUST NOT** use `@SpringBootTest` or `MockitoExtension`
- **MUST** use `@Testcontainers`
- Use `@DataJpaTest` with `@AutoConfigureTestDatabase(replace = Replace.NONE)` to disable embedded DB
- Use `@Container` for static container instance
- Configure via `@DynamicPropertySource`
- Set `spring.jpa.hibernate.ddl-auto` to `"create"` in `@DynamicPropertySource`
- Isolate data per test using `@AfterEach` with `deleteAll()` cleanup

**Incorrect:**

```java
// Using embedded H2 - doesn't test real DB behavior
@DataJpaTest
class UserRepositoryTest {
    // Uses H2 by default - wrong!
}

// Using @SpringBootTest - too heavy
@SpringBootTest
class UserRepositoryTest {
    // Loads entire context - wrong!
}

// Mocking repository - not testing actual queries
@ExtendWith(MockitoExtension.class)
class UserRepositoryTest {
    @Mock
    private UserRepository userRepository;
}
```

**Correct:**

```java
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.test.context.DynamicPropertyRegistry;
import org.springframework.test.context.DynamicPropertySource;
import org.testcontainers.containers.PostgreSQLContainer;
import org.testcontainers.junit.jupiter.Container;
import org.testcontainers.junit.jupiter.Testcontainers;

import static org.assertj.core.api.Assertions.assertThat;

@Testcontainers
@DataJpaTest
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
class UserRepositoryTest {

    @Container
    static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

    @DynamicPropertySource
    static void configureProperties(DynamicPropertyRegistry registry) {
        registry.add("spring.datasource.url", postgres::getJdbcUrl);
        registry.add("spring.datasource.username", postgres::getUsername);
        registry.add("spring.datasource.password", postgres::getPassword);
        registry.add("spring.jpa.hibernate.ddl-auto", () -> "create");
    }

    @Autowired
    private UserRepository userRepository;

    @AfterEach
    void tearDown() {
        userRepository.deleteAll();
    }

    @Test
    void save_validUser_persistsToDatabase() {
        // Given
        var user = new User("john@test.com", "John Doe");

        // When
        User savedUser = userRepository.save(user);

        // Then
        assertThat(savedUser.getId()).isNotNull();
        assertThat(savedUser.getEmail()).isEqualTo("john@test.com");
    }

    @Test
    void findByEmail_existingUser_returnsUser() {
        // Given
        var user = new User("john@test.com", "John Doe");
        userRepository.save(user);

        // When
        var actualUser = userRepository.findByEmail("john@test.com");

        // Then
        assertThat(actualUser).isPresent();
        assertThat(actualUser.get().getName()).isEqualTo("John Doe");
    }

    @Test
    void findByEmail_nonExistentUser_returnsEmpty() {
        // When
        var actualUser = userRepository.findByEmail("unknown@test.com");

        // Then
        assertThat(actualUser).isEmpty();
    }

    @Test
    void findAllByStatus_multipleUsers_returnsMatchingUsers() {
        // Given
        userRepository.save(new User("active1@test.com", "Active 1", UserStatus.ACTIVE));
        userRepository.save(new User("active2@test.com", "Active 2", UserStatus.ACTIVE));
        userRepository.save(new User("inactive@test.com", "Inactive", UserStatus.INACTIVE));

        // When
        var actualUsers = userRepository.findAllByStatus(UserStatus.ACTIVE);

        // Then
        assertThat(actualUsers).hasSize(2);
        assertThat(actualUsers).extracting(User::getEmail)
                .containsExactlyInAnyOrder("active1@test.com", "active2@test.com");
    }

    @Test
    void deleteById_existingUser_removesFromDatabase() {
        // Given
        var user = userRepository.save(new User("john@test.com", "John Doe"));

        // When
        userRepository.deleteById(user.getId());

        // Then
        assertThat(userRepository.findById(user.getId())).isEmpty();
    }
}
```

### Database Containers by Type

```java
// PostgreSQL
@Container
static final PostgreSQLContainer<?> postgres = new PostgreSQLContainer<>("postgres:15-alpine");

// MySQL
@Container
static final MySQLContainer<?> mysql = new MySQLContainer<>("mysql:8.0");

// MariaDB
@Container
static final MariaDBContainer<?> mariadb = new MariaDBContainer<>("mariadb:10.6");

// MongoDB (use @DataMongoTest instead of @DataJpaTest)
@Container
static final MongoDBContainer mongo = new MongoDBContainer("mongo:6.0");
```

### Key Points

1. Use real database container matching production
2. Clean up data after each test for isolation
3. Test custom query methods
4. Verify entity relationships and cascades
5. Test edge cases (empty results, duplicates)