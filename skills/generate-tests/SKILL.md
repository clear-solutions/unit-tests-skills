---
name: generate-tests
description: "Use when the user asks to generate, create, or write unit tests for code. Analyzes the target code, produces a structured test case list for review, then generates test code. Supports Java (JUnit 5, Mockito, AssertJ)."
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

# Generate Tests Skill

You will analyze code and generate high-quality unit tests for a given target.

---

## Rules Reference

**CRITICAL: You MUST read and apply all relevant rules from the `./rules/tests/` directory:**

> **Maintenance note:** General rules in `./rules/tests/general/` are shared with the `generate-test-cases` skill (which has copies in `rules/general/`). When updating rules, keep both locations in sync.

### General Rules (Always Apply)
- `general/test-case-generation-strategy.md` - INCLUDE/EXCLUDE criteria
- `general/naming-conventions.md` - Test naming format
- `general/general-principles.md` - Core testing principles (Given-When-Then, actual/expected)
- `general/technology-stack-detection.md` - Detect language and framework
- `general/what-makes-good-test.md` - Clarity, Completeness, Conciseness, Resilience
- `general/cleanly-create-test-data.md` - Use helpers and builders for test data
- `general/keep-cause-effect-clear.md` - Effects follow causes immediately
- `general/no-logic-in-tests.md` - KISS > DRY, avoid logic in assertions
- `general/keep-tests-focused.md` - One scenario per test
- `general/test-behaviors-not-methods.md` - Separate tests for behaviors
- `general/verify-relevant-arguments-only.md` - Only verify relevant mock arguments
- `general/prefer-public-apis.md` - Test public APIs over private methods

### Java Unit Tests
- `java/unit/java-test-template.md` - Basic template, FORBIDDEN annotations
- `java/unit/json-serialization.md` - Use explicit JSON literals
- `java/unit/argument-matching.md` - Use ArgumentCaptor, not any()
- `java/unit/logging-rules.md` - OutputCaptureExtension for logs
- `java/unit/domain-service-rules.md` - Mockito patterns

### Post-Generation
- `post-generation/compilation-verification.md` - Verify compilation

---

## Instructions

When this skill is invoked, generate tests for the specified target using the internal two-step workflow below.

**Target to test:** $ARGUMENTS

### Step 1: Generate Test Cases

1. **Read the relevant rules** from `./rules/tests/` based on code type
2. Read the source file/class/method specified above
3. Analyze ALL code branches, including:
   - Success paths
   - Error/exception paths
   - Validation logic
   - Private/protected methods called by the target
   - Security annotations (if present)
4. Apply the INCLUDE/EXCLUDE rules strictly
5. Output the list of test cases in the format below — do NOT generate test code yet

#### Test Case Output Format

```
## Test Cases for {ClassName}.{methodName}

### 1. {testMethodName}
- **Given:** {preconditions/input state}
- **When:** {action being tested}
- **Then:** {expected outcome}
- **Code branch:** {which code path this covers}

### 2. {testMethodName}
...
```

#### Naming Convention
Test method name format: `{testedMethod}_{givenState}_{expectedOutcome}`

Examples:
- `calculateTotal_validProducts_returnsSum`
- `calculateTotal_emptyList_throwsIllegalArgumentException`
- `getUser_unauthorized_returns401`

### Step 2: Ask for User Review

After outputting test cases, use the **AskUserQuestion tool** to ask the user:
```
Question: "Test cases are ready. Proceed with generating test code?"
Header: "Next step"
Options:
  - Label: "Yes, generate tests" / Description: "Proceed to generate test files from the test cases above"
  - Label: "No, let me review first" / Description: "Stop here so I can review and adjust the test cases"
```

- If user selects "Yes", proceed to Step 3
- If user selects "No", STOP and wait for further instructions

### Step 3: Generate Test Code

1. Analyze the code to determine the type (controller, service, repository, messaging, etc.)
2. Apply the appropriate rules from the rules directory
3. Generate comprehensive tests following all rules and the test cases from Step 1
4. Create the test file(s) in the correct location using the Write tool

### Step 4: Verify Compilation

1. Run compilation and fix any issues until tests compile successfully
