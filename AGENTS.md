# AGENTS.md

Guidance for AI agents working with this repository.

## Overview

Skills for generating unit tests with consistent quality. Each skill is self-contained.

## Skills

| Command                       | What it does                          |
|-------------------------------|---------------------------------------|
| `/generate-tests <file>`      | Full workflow: analyzes code, outputs test cases for review, generates test code |
| `/generate-test-cases <file>` | Analysis only: outputs test case list without generating code |

## Rules Location

Rules are inside each skill folder:

- `generate-test-cases/rules/general/` — general rules only
- `generate-tests/rules/tests/` — all rules (general, java, post-generation)

## Creating a New Skill

### Directory Structure

```
skills/
  {skill-name}/
    SKILL.md
    rules/          # Rules used by this skill
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

List rule files from `./rules/` directory.

## Instructions

**Target:** $ARGUMENTS

Steps:
1. First step
2. Second step
3. ...
```

## Adding a New Rule

Add rules inside the skill folder that uses them:

```
skills/{skill-name}/rules/
  general/
    {rule-name}.md
  {language}/unit/
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