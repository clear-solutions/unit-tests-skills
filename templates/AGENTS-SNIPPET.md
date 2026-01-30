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

This project uses unit test generation skills. Use the two-step approach for best results:

1. `/generate-test-cases <file>` — Analyze code, output test case list
2. `/generate-tests <file>` — Generate test code from cases

### Available Skills

<available_skills>
  <skill>
    <name>generate-test-cases</name>
    <description>Analyzes source code and outputs a structured list of test cases in Given-When-Then format. Use this FIRST before generating actual test code.</description>
  </skill>
  <skill>
    <name>generate-tests</name>
    <description>Generates actual test code based on previously generated test cases. Follows strict testing principles: one scenario per test, no logic in tests, proper naming conventions.</description>
  </skill>
</available_skills>

### Workflow

When asked to "generate tests":
1. Run `/generate-test-cases` first
2. Review the test cases with the user
3. Run `/generate-tests` to create actual test code

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