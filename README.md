# Unit Test Skills

A collection of AI agent skills for generating high-quality unit tests. These skills encode battle-tested testing principles that work across any programming language, with additional specialized rules for Java.

## Installation

### Option 1: Using openskills (Recommended)

[openskills](https://github.com/numman-ali/openskills) automatically generates `AGENTS.md` for maximum AI agent effectiveness.

```bash
# Install skills
npx openskills install clear-solutions/unit-tests-skills

# Auto-generate/update AGENTS.md with installed skills
npx openskills sync
```

**Why openskills?** According to [Vercel's research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals), skills alone trigger only 53% of the time. With `AGENTS.md`, success rate jumps to **100%**.

### Option 2: Using npx skills

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

**Important:** After installing with `npx skills`, manually add the snippet from [`templates/AGENTS-SNIPPET.md`](templates/AGENTS-SNIPPET.md) to your project's `AGENTS.md` file.

## Why AGENTS.md Matters

| Configuration | Success Rate |
|---------------|--------------|
| Skills alone | 53% |
| Skills + prompting | 79% |
| **AGENTS.md** | **100%** |

`AGENTS.md` provides persistent context to AI agents on every turn, without requiring them to decide to load skills first. See the [full article](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals) for details.

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

## Google's unit tests best practices

> **Legend:** Implemented = rule file exists in skills | Not implemented = no rule file yet
> Priority: HIGH / MEDIUM / LOW — based on impact on unit test quality

- [Tech on the Toilet: Driving Software Excellence, One Bathroom Break at a Time](https://testing.googleblog.com/2024/12/tech-on-toilet-driving-software.html) - Dec 2024 (announcement of continuation)
- [Increase Test Fidelity By Avoiding Mocks](https://testing.googleblog.com/2024/02/increase-test-fidelity-by-avoiding-mocks.html) - Feb 2024 — **NOT IMPLEMENTED** (HIGH) — real > fake > mock hierarchy
- [Testing on the Toilet: Separation of Concerns? That's a Wrap!](https://testing.googleblog.com/2020/12/testing-on-toilet-separation-of.html) - Dec 2020 — **NOT IMPLEMENTED** (MEDIUM) — wrap third-party APIs for testability
- [Testing on the Toilet: Testing UI Logic? Follow the User!](https://testing.googleblog.com/2020/10/testing-on-toilet-testing-ui-logic.html) - Oct 2020 — **NOT IMPLEMENTED** (LOW) — UI-specific, relevant for frontend rules
- [Testing on the Toilet: Don't Mock Types You Don't Own](https://testing.googleblog.com/2020/07/testing-on-toilet-dont-mock-types-you.html) - Jul 2020 — **NOT IMPLEMENTED** (HIGH) — never mock third-party types
- [Testing on the Toilet: Tests Too DRY? Make Them DAMP!](https://testing.googleblog.com/2019/12/testing-on-toilet-tests-too-dry-make.html) - Dec 2019 — **PARTIALLY IMPLEMENTED** (LOW) — DAMP principle not explicit, covered partly by `no-logic-in-tests.md`
- [Testing on the Toilet: Exercise Service Call Contracts in Tests](https://testing.googleblog.com/2018/11/testing-on-toilet-exercise-service-call.html) - Nov 2018 — **NOT IMPLEMENTED** (MEDIUM) — prefer fakes/hermetic servers over mocking services
- [Testing on the Toilet: Only Verify Relevant Method Arguments](https://testing.googleblog.com/2018/06/testing-on-toilet-only-verify-relevant.html) - Jun 2018 — **IMPLEMENTED** — `verify-relevant-arguments-only.md`
- [Testing on the Toilet: Keep Tests Focused](https://testing.googleblog.com/2018/06/testing-on-toilet-keep-tests-focused.html) - Jun 2018 — **IMPLEMENTED** — `keep-tests-focused.md`
- [Testing on the Toilet: Cleanly Create Test Data](https://testing.googleblog.com/2018/02/testing-on-toilet-cleanly-create-test.html) - Feb 2018 — **IMPLEMENTED** — `cleanly-create-test-data.md`
- [Testing on the Toilet: Only Verify State-Changing Method Calls](https://testing.googleblog.com/2017/12/testing-on-toilet-only-verify-state.html) - Dec 2017 — **NOT IMPLEMENTED** (HIGH) — don't verify query/getter methods
- [Testing on the Toilet: Keep Cause and Effect Clear](https://testing.googleblog.com/2017/01/testing-on-toilet-keep-cause-and-effect.html) - Jan 2017 — **IMPLEMENTED** — `keep-cause-effect-clear.md`
- [Testing on the Toilet: What Makes a Good End-to-End Test?](https://testing.googleblog.com/2016/09/testing-on-toilet-what-makes-good-end.html) - Sep 2016 — **IMPLEMENTED** — `what-makes-good-test.md`
- [Testing on the Toilet: Change-Detector Tests Considered Harmful](https://testing.googleblog.com/2015/01/testing-on-toilet-change-detector-tests.html) - Jan 2015 — **NOT IMPLEMENTED** (HIGH) — avoid tests that mirror production code
- [Testing on the Toilet: Prefer Testing Public APIs Over Implementation-Detail Classes](https://testing.googleblog.com/2015/01/testing-on-toilet-prefer-testing-public.html) - Jan 2015 — **IMPLEMENTED** — `prefer-public-apis.md`
- [Testing on the Toilet: Writing Descriptive Test Names](https://testing.googleblog.com/2014/10/testing-on-toilet-writing-descriptive.html) - Oct 2014 — **IMPLEMENTED** — `naming-conventions.md`
- [Testing on the Toilet: Don't Put Logic in Tests](https://testing.googleblog.com/2014/07/testing-on-toilet-dont-put-logic-in.html) - Jul 2014 — **IMPLEMENTED** — `no-logic-in-tests.md`
- [Testing on the Toilet: Risk-Driven Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-risk-driven-testing.html) - May 2014 — **NOT IMPLEMENTED** (LOW) — risk-based test prioritization
- [Testing on the Toilet: Effective Testing](https://testing.googleblog.com/2014/05/testing-on-toilet-effective-testing.html) - May 2014 — **PARTIALLY IMPLEMENTED** (LOW) — fidelity + precision missing from CCCR framework in `what-makes-good-test.md`
- [Testing on the Toilet: Test Behaviors, Not Methods](https://testing.googleblog.com/2014/04/testing-on-toilet-test-behaviors-not.html) - Apr 2014 — **IMPLEMENTED** — `test-behaviors-not-methods.md`
- [Testing on the Toilet: Test Behavior, Not Implementation](https://testing.googleblog.com/2013/08/testing-on-toilet-test-behavior-not.html) - Aug 2013 — **IMPLEMENTED** — `test-behaviors-not-methods.md`, `general-principles.md`
- [Testing on the Toilet: Know Your Test Doubles](https://testing.googleblog.com/2013/07/testing-on-toilet-know-your-test-doubles.html) - Jul 2013 — **NOT IMPLEMENTED** (HIGH) — stub vs mock vs fake distinctions
- [Testing on the Toilet: Fake Your Way to Better Tests](https://testing.googleblog.com/2013/06/testing-on-toilet-fake-your-way-to.html) - Jun 2013 — **NOT IMPLEMENTED** (HIGH) — prefer fakes, fake at lowest layer
- [Testing on the Toilet: Don't Overuse Mocks](https://testing.googleblog.com/2013/05/testing-on-toilet-dont-overuse-mocks.html) - May 2013 — **NOT IMPLEMENTED** (HIGH) — limit to 1-2 mocks per test
- [Testing on the Toilet: Testing State vs. Testing Interactions](https://testing.googleblog.com/2013/03/testing-on-toilet-testing-state-vs.html) - Mar 2013 — **NOT IMPLEMENTED** (HIGH) — prefer state testing over verify()
- [TotT: Making a Perfect Matcher](https://testing.googleblog.com/2009/10/tott-making-perfect-matcher.html) - Oct 2009
- [TotT: Finding Data Races in C++](https://testing.googleblog.com/2008/11/tott-contain-your-environment.html) - Nov 2008
- [TotT: Contain Your Environment](https://testing.googleblog.com/2008/10/tott-contain-your-environment.html) - Oct 2008
- [TotT: Floating-Point Comparison](https://testing.googleblog.com/2008/10/tott-floating-point-comparison.html) - Oct 2008
- [TotT: Simulating Time in jsUnit Tests](https://testing.googleblog.com/2008/10/tott-simulating-time-in-jsunit-tests.html) - Oct 2008
- [TotT: Data Driven Traps!](https://testing.googleblog.com/2008/09/tott-data-driven-traps.html) - Sep 2008
- [TotT: Sleeping != Synchronization](https://testing.googleblog.com/2008/08/tott-sleeping-synchronization.html) - Aug 2008
- [TotT: 100 and counting](https://testing.googleblog.com/2008/08/tott-100-and-counting.html) - Aug 2008
- [TotT: A Matter of Black and White](https://testing.googleblog.com/2008/08/progressive-developer-knows-that-in.html) - Aug 2008
- [TotT: Testing Against Interfaces](https://testing.googleblog.com/2008/07/tott-testing-against-interfaces.html) - Jul 2008
- [TotT: EXPECT vs. ASSERT](https://testing.googleblog.com/2008/07/tott-expect-vs-assert.html) - Jul 2008
- [TotT: Defeat "Static Cling"](https://testing.googleblog.com/2008/06/defeat-static-cling.html) - Jun 2008 — **NOT IMPLEMENTED** (MEDIUM) — wrap statics behind injectable interfaces
- [TotT: Friends You Can Depend On](https://testing.googleblog.com/2008/06/tott-friends-you-can-depend-on.html) - Jun 2008
- [TotT: The Invisible Branch](https://testing.googleblog.com/2008/05/tott-invisible-branch.html) - May 2008
- [TotT: Using Dependency Injection to Avoid Singletons](https://testing.googleblog.com/2008/05/tott-using-dependancy-injection-to.html) - May 2008 — **NOT IMPLEMENTED** (MEDIUM) — constructor injection for testability
- [TotT: Testable Contracts Make Exceptional Neighbors](https://testing.googleblog.com/2008/05/tott-testable-contracts-make.html) - May 2008
- [TotT: Avoiding Flakey Tests](https://testing.googleblog.com/2008/04/tott-avoiding-flakey-tests.html) - Apr 2008 — **NOT IMPLEMENTED** (LOW) — resource isolation between tests
- [TotT: Time is Random](https://testing.googleblog.com/2008/04/tott-time-is-random.html) - Apr 2008
- [TotT: Understanding Your Coverage Data](https://testing.googleblog.com/2008/03/tott-understanding-your-coverage-data.html) - Mar 2008
- [TotT: TestNG on the Toilet](https://testing.googleblog.com/2008/03/tott-testng-on-toilet.html) - Mar 2008
- [TotT: The Stroop Effect](https://testing.googleblog.com/2008/02/tott-stroop-effect.html) - Feb 2008
- [TotT: Too Many Tests](https://testing.googleblog.com/2008/02/in-movie-amadeus-austrian-emperor.html) - Feb 2008
- [TotT: Refactoring Tests in the Red](https://testing.googleblog.com/2007/04/tott-refactoring-tests-in-red.html) - Apr 2007
- [TotT: Stubs Speed up Your Unit Tests](https://testing.googleblog.com/2007/04/tott-stubs-speed-up-your-unit-tests.html) - Apr 2007
- [TotT: Extracting Methods to Simplify Testing](https://testing.googleblog.com/2007/06/tott-extracting-methods-to-simplify.html) - Jun 2007

