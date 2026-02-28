# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

A collection of AI agent skills (not a runnable application) for generating high-quality unit tests. Skills are installed into target projects via `npx openskills install` or `npx skills add`. There is no build system, test suite, or application code here — only skill definitions and rule documents.

## Repository Structure

```
skills/
  generate-test-cases/    # Skill: analyze code → output test case list
    SKILL.md              # Skill definition (frontmatter + instructions)
    rules/general/        # General testing rules
  generate-tests/         # Skill: generate actual test code from cases
    SKILL.md
    rules/tests/
      general/            # General testing rules (superset of generate-test-cases rules)
      java/unit/          # Java-specific rules (JUnit 5, Mockito, AssertJ)
      post-generation/    # Compilation verification rules
templates/
  AGENTS-SNIPPET.md       # Template users copy into their project's AGENTS.md
```

## Available Skills

| Command | Purpose |
|---------|---------|
| `/generate-test-cases <target>` | Analyze code → output structured test case list (Given-When-Then) |
| `/generate-tests <target>` | Generate test code from previously generated test cases |

## Workflow

The two-step process is **mandatory** — always generate test cases before generating tests:

1. `/generate-test-cases <target>` — outputs test case list
2. User reviews test cases
3. `/generate-tests <target>` — generates test code

When a user asks to "generate tests", run `/generate-test-cases` first, then ask the user before proceeding to `/generate-tests`.

## Rules

Each skill's `SKILL.md` lists which rule files it reads. When a skill is invoked, the skill definition instructs the agent to read the rule files from the skill's own `rules/` directory. The `generate-tests` skill has a superset of rules (includes Java-specific and post-generation rules).

Key rule topics:
- **INCLUDE/EXCLUDE criteria** (`test-case-generation-strategy.md`) — what to test vs. skip
- **Naming** (`naming-conventions.md`) — `{method}_{state}_{outcome}` format
- **Structure** (`general-principles.md`) — Given-When-Then, `actual`/`expected` prefixes
- **Java specifics** — JUnit 5 + Mockito + AssertJ; `@SpringBootTest` is FORBIDDEN in unit tests; use `ArgumentCaptor` to verify DTO/model fields; use `any()` only for irrelevant arguments

## Contributing

- Place general rules in `rules/general/` (or `rules/tests/general/` for generate-tests)
- Place language-specific rules in `rules/tests/{language}/unit/`
- All changes require a PR with CODEOWNER approval; direct pushes to `main` are disabled
