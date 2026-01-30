# Unit Test Skills

A collection of AI agent skills for generating high-quality unit tests. These skills encode battle-tested testing principles that work across any programming language, with additional specialized rules for Java.

## Installation

```bash
npx skills add clear-solutions/unit-tests-skills
```

Or install specific skills:

```bash
npx skills add clear-solutions/unit-tests-skills --skill generate-test-cases
npx skills add clear-solutions/unit-tests-skills --skill generate-tests
```

For Claude Code specifically:

```bash
npx skills add clear-solutions/unit-tests-skills -a claude-code
```

## Available Skills

| Skill | Command | Description |
|-------|---------|-------------|
| Generate Test Cases | `/generate-test-cases <target>` | Analyze code and output a list of test cases with Given-When-Then format |
| Generate Tests | `/generate-tests <target>` | Generate actual test code based on previously generated test cases |

## Usage

### Two-Step Process (Recommended)

1. **Generate test cases first:**
   ```
   /generate-test-cases src/services/OrderService.java
   ```
   This analyzes the code and outputs a structured list of test cases.

2. **Generate test code:**
   ```
   /generate-tests src/services/OrderService.java
   ```
   This creates the actual test files based on the test cases.

### Why Two Steps?

- Ensures proper coverage based on INCLUDE/EXCLUDE rules
- Prevents missing edge cases and error scenarios
- Allows review of test strategy before writing code
- Produces more focused, maintainable tests

## Testing Principles

These skills enforce proven testing practices:

### General Rules (All Languages)

| Rule | Description |
|------|-------------|
| **Test Case Strategy** | Strict INCLUDE/EXCLUDE criteria - test each code branch, not collection sizes |
| **Naming Conventions** | `{method}_{state}_{outcome}` format for clarity |
| **Given-When-Then** | Clear structure with `actual`/`expected` prefixes |
| **Keep Tests Focused** | One scenario per test, single responsibility |
| **Test Behaviors** | Test what it does, not how it's implemented |
| **No Logic in Tests** | KISS > DRY - use literal values, avoid calculations |
| **Clean Test Data** | Use helpers and builders, never rely on defaults |
| **Cause-Effect Clarity** | Setup belongs in the test, not in distant `@BeforeEach` |
| **Public APIs First** | Test through public interfaces, not private methods |
| **Verify Relevant Args** | Use `any()` for irrelevant arguments in mocks |

### Language-Specific Rules

#### Java
- JUnit 5 + Mockito + AssertJ
- `@ExtendWith(MockitoExtension.class)` for unit tests
- **FORBIDDEN:** `@SpringBootTest` in unit tests
- Use `ArgumentCaptor` instead of `any()` for DTOs
- Explicit JSON literals (no `objectMapper.writeValueAsString()`)
- `OutputCaptureExtension` for log verification

## Project Structure

```
skills/
├── generate-test-cases/
│   ├── SKILL.md
│   └── rules/general/
└── generate-tests/
    ├── SKILL.md
    └── rules/tests/
        ├── general/
        ├── java/unit/
        └── post-generation/
```

## Test Case Generation Strategy

### INCLUDE
- Each distinct code branch and outcome
- Each unique return value or exception
- Separate cases for HTTP 400, 401, 403 (never merge)
- Negative test cases for validation constraints
- All paths through private methods (via public API)

### EXCLUDE
- Duplicate scenarios with same observable result
- Collection size variations (1, 2, 3 items) unless code has explicit size logic
- Speculative cases (exotic Unicode, massive payloads) unless explicitly handled
- Null arguments unless parameter is `@Nullable`
- Multiple tests for same exception type

## Example Output

### Test Cases
```
## Test Cases for OrderService.calculateTotal

### 1. calculateTotal_validProducts_returnsSum
- **Given:** List with products priced at 50.0 and 100.0
- **When:** calculateTotal() is called
- **Then:** Returns 150.0
- **Code branch:** Happy path

### 2. calculateTotal_emptyList_throwsIllegalArgumentException
- **Given:** Empty product list
- **When:** calculateTotal() is called
- **Then:** Throws IllegalArgumentException
- **Code branch:** Validation - empty input
```

### Generated Test
```java
@ExtendWith(MockitoExtension.class)
class OrderServiceTest {

    @Mock
    private ProductRepository productRepository;

    @InjectMocks
    private OrderService orderService;

    @Test
    void calculateTotal_validProducts_returnsSum() {
        // Given
        var product1 = new Product("A", 50.0);
        var product2 = new Product("B", 100.0);
        when(productRepository.findAll()).thenReturn(List.of(product1, product2));

        // When
        double actualTotal = orderService.calculateTotal();

        // Then
        double expectedTotal = 150.0;
        assertThat(actualTotal).isEqualTo(expectedTotal);
    }
}
```

## Contributing

Contributions are welcome via Pull Requests. All PRs require review and approval from maintainers before merging.

When adding new rules:

1. Place general rules in `.claude/rules/tests/general/`
2. Place language-specific rules in `.claude/rules/tests/{language}/`
3. Update skill files if new rules need explicit reference
4. Ensure your changes follow the existing format and style

## Repository Protection

This repository uses branch protection rules:
- Direct pushes to `main` are disabled
- All changes require a Pull Request
- PRs require at least one approval from CODEOWNERS
- Status checks must pass before merging
