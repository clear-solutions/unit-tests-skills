# AGENTS.md

Guidance for AI agents working with this repository.

## Overview

Skills for generating unit tests with consistent quality. Two-step process: analyze code first, then generate tests.

## Skills

| Command                       | What it does                          |
|-------------------------------|---------------------------------------|
| `/generate-test-cases <file>` | Analyzes code, outputs test case list |
| `/generate-tests <file>`      | Generates test code from cases        |

## Rules Location

All testing rules are in `skills/rules/tests/`:

- `general/` — applies to all languages
- `java/unit/` — Java-specific (JUnit 5, Mockito)
- `post-generation/` — compilation verification

## When Generating Tests

1. Read rules from `skills/rules/tests/general/`
2. If Java — also read `java/unit/` rules
3. Apply INCLUDE/EXCLUDE criteria from `test-case-generation-strategy.md`
4. Follow naming format: `{method}_{state}_{outcome}`
5. Verify tests compile before finishing

## Skills Location

Skills are in `skills/` directory at project root.

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/
    SKILL.md
```

### Naming Conventions

- **Skill directory**: `kebab-case` (e.g., `generate-tests`, `generate-test-cases`)
- **SKILL.md**: Always uppercase, exact filename

### SKILL.md Format

```markdown
---
name: skill-name
description: One sentence describing when to use this skill.
allowed-tools: Read, Write, Glob, Grep
---

# Skill Title

What this skill does.

## Rules Reference

List rule files this skill reads from `skills/rules/tests/`.

## Instructions

**Target:** $ARGUMENTS

Steps:
1. First step
2. Second step
3. ...
```

## Adding a New Rule

### Directory Structure

```
skills/rules/tests/
  general/              # Language-agnostic rules
    {rule-name}.md
  {language}/unit/      # Language-specific unit test rules
    {rule-name}.md
```

### Rule File Format

```markdown
## Rule Title

Why this rule matters.

**Incorrect:**

```java
// Bad example
```

**Correct:**

```java
// Good example
```

### Guidelines

1. Guideline one
2. Guideline two
```