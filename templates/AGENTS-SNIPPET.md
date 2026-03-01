# AGENTS.md Snippet for Unit Test Skills

Add this snippet to your project's `AGENTS.md` file to enable AI agents to automatically discover and use the unit test generation skills.

## Quick Setup

If you don't have an `AGENTS.md` file yet, create one in your project root:

```bash
touch AGENTS.md
```

Then copy the content below into your `AGENTS.md`:

---

## Snippet to Copy

```markdown
# AGENTS.md

## Unit Test Generation

This project uses unit test generation skills.

### Available Skills

<available_skills>
  <skill>
    <name>generate-tests</name>
    <description>Use when the user asks to generate, create, or write unit tests for code. Analyzes the target code, produces a structured test case list for review, then generates test code. Supports Java (JUnit 5, Mockito, AssertJ).</description>
  </skill>
  <skill>
    <name>generate-test-cases</name>
    <description>Use when the user asks to analyze code for test coverage, list what test cases are needed, or review testing strategy — WITHOUT generating actual test code.</description>
  </skill>
</available_skills>

### Key Principles

- INCLUDE: Each code branch, unique return value, each exception type
- EXCLUDE: Duplicate scenarios, collection size variations, speculative cases
- Format: `{method}_{state}_{outcome}` naming
- Structure: Given-When-Then with `actual`/`expected` prefixes
```

---

## Why AGENTS.md?

According to [Vercel's research](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals):

| Configuration | Success Rate |
|---------------|--------------|
| Skills alone | 53% |
| Skills + instructions | 79% |
| **AGENTS.md** | **100%** |

AGENTS.md provides persistent context to agents on every turn, without requiring them to decide to load skills first.
