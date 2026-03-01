---
name: generate-test-cases
description: "Use when the user asks to analyze code for test coverage, list what test cases are needed, or review testing strategy — WITHOUT generating actual test code."
allowed-tools: Read, Glob, Grep
---

# Generate Test Cases Skill

You will analyze code and generate a list of test cases that should be written for a given method/class. This skill outputs test case descriptions only — it does NOT generate actual test code.

---

## Rules Reference

**CRITICAL: You MUST read and apply all rules from the following files before generating test cases:**

> **Maintenance note:** General rules in `./rules/general/` are shared with the `generate-tests` skill (which has copies in `rules/tests/general/`). When updating rules, keep both locations in sync.

### General Rules (Always Apply)
- `./rules/general/test-case-generation-strategy.md` - INCLUDE/EXCLUDE criteria for test cases
- `./rules/general/naming-conventions.md` - Test naming format
- `./rules/general/general-principles.md` - Core testing principles
- `./rules/general/what-makes-good-test.md` - Clarity, Completeness, Conciseness, Resilience
- `./rules/general/keep-tests-focused.md` - One scenario per test
- `./rules/general/test-behaviors-not-methods.md` - Separate tests for behaviors
- `./rules/general/prefer-public-apis.md` - Test public APIs over private methods
- `./rules/general/cleanly-create-test-data.md` - Use helpers and builders for test data
- `./rules/general/keep-cause-effect-clear.md` - Effects follow causes immediately
- `./rules/general/no-logic-in-tests.md` - KISS > DRY, avoid logic in assertions
- `./rules/general/technology-stack-detection.md` - Detect language and framework
- `./rules/general/verify-relevant-arguments-only.md` - Only verify relevant mock arguments

---

## Output Format

For each test case, provide:

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

### Naming Convention
Test method name format: `{testedMethod}_{givenState}_{expectedOutcome}`

Examples:
- `calculateTotal_validProducts_returnsSum`
- `calculateTotal_emptyList_throwsIllegalArgumentException`
- `getUser_unauthorized_returns401`
- `getUser_forbidden_returns403`

---

## Instructions

When this command is invoked, generate test cases for the specified target:

**Target to analyze:** $ARGUMENTS

**Steps:**
1. **Read the rules** from `./rules/general/` directory
2. Read the source file/class/method specified above
3. Analyze ALL code branches, including:
   - Success paths
   - Error/exception paths
   - Validation logic
   - Private/protected methods called by the target
   - Security annotations (if present)
4. Apply the INCLUDE/EXCLUDE rules strictly
5. Output the list of test cases in the specified format
6. Do NOT generate actual test code — only the test case descriptions
