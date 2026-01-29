# Project Guidelines

## Test Generation

This project provides skills and rules for generating high-quality unit tests. When asked to generate tests, first explore the project structure to understand the codebase, then use the available skills.

### Recommended Workflow

When generating tests, the two-step approach produces better results:

1. **First:** Run `/generate-test-cases <target>` to analyze code and list test cases
2. **Review:** Check that test cases cover the important branches
3. **Then:** Run `/generate-tests <target>` to generate actual test code

This approach ensures proper coverage based on INCLUDE/EXCLUDE rules and allows reviewing the test strategy before writing code.

### Available Skills

| Skill | Command | Purpose |
|-------|---------|---------|
| Generate Test Cases | `/generate-test-cases <target>` | Analyze code → output test case list with Given-When-Then |
| Generate Tests | `/generate-tests <target>` | Generate test code based on test cases |

### Test Rules

All rules are in `skills/rules/tests/`. When a skill is invoked, read the relevant rules:

**General (always apply):**
- `general/test-case-generation-strategy.md` — INCLUDE/EXCLUDE criteria
- `general/naming-conventions.md` — `{method}_{state}_{outcome}` format
- `general/general-principles.md` — Given-When-Then, actual/expected prefixes
- `general/what-makes-good-test.md` — Clarity, Completeness, Conciseness, Resilience
- `general/cleanly-create-test-data.md` — helpers, builders, no default reliance
- `general/keep-tests-focused.md` — one scenario per test
- `general/no-logic-in-tests.md` — KISS > DRY, literal values in assertions

**Java-specific:**
- `java/unit/java-test-template.md` — JUnit 5 template, forbidden annotations
- `java/unit/domain-service-rules.md` — Mockito patterns
- `java/unit/argument-matching.md` — ArgumentCaptor over any()

**Post-generation:**
- `post-generation/compilation-verification.md` — verify tests compile

### Workflow Details

**When user asks to "generate tests":**
1. Run `/generate-test-cases` first
2. After test cases are ready, ask user if they want to proceed with code generation
3. If yes, run `/generate-tests`

**When user asks to "generate test cases" only:**
1. Run `/generate-test-cases`
2. Stop after outputting the test cases list