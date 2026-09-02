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
- `generate-tests/rules/tests/` — all rules (general, java unit and integration, post-generation)

## Plugin Validation

This repository doubles as a Claude Code plugin **and** a marketplace, declared
in `.claude-plugin/`. Both manifests must stay valid, because the
community-marketplace review pipeline runs `claude plugin validate` on every
submission.

**After changing anything under `.claude-plugin/` or `skills/`, run:**

```bash
./scripts/validate-plugin.sh
```

CI runs the same script on every pull request touching those paths
(`.github/workflows/validate-plugin.yml`). No credentials are needed —
validation is entirely local.

### What it checks, and why each check exists

| Check | Why it is not redundant |
|---|---|
| `claude plugin validate . --strict` | Validates the marketplace manifest. `--strict` promotes warnings to errors, which matters because the CLI reports a `version` that disagrees between the entry and `plugin.json` as a *warning* — while `plugin.json` silently wins at install time. |
| `claude plugin validate <copy> --strict` | The validator switches to marketplace mode the moment it sees `marketplace.json`, so validating the repo root **never** exercises `plugin.json`'s own schema. The script copies the plugin without the marketplace file to force plugin mode. |
| Entry name matches `plugin.json` | The CLI does **not** check this. A marketplace entry naming a plugin that `plugin.json` does not define validates cleanly and only fails later at install time with `Plugin "<name>" not found in marketplace`. Verified against claude 2.1.235. |

### Conventions that follow from this

- Declare `version` in `plugin.json` **only**. Repeating it in the marketplace
  entry adds a way for the two to drift, and the entry's copy is ignored.
- The plugin `name` is immutable once published — it is the install id and the
  skill namespace (`/unit-tests-skills:generate-tests`). Do not rename it.
- Keep `skills/` at the repository root. Only `plugin.json` and
  `marketplace.json` belong inside `.claude-plugin/`.

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
  {language}/integration/
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