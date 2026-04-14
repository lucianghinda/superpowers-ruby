---
name: superpowers-ruby:handoff-list
description: Use when viewing available handoff documents — lists active and archived handoffs with their status, date, topic, and branch
---

# Handoff List

## Overview

Display all available handoff documents, both active (unrestored) and archived (consumed). Helps you decide which handoff to resume or review.

**Announce at start:** "I'm using the handoff-list skill to show available handoffs."

## When to Use

- When starting a session and unsure if handoffs exist
- When you want to review past handoff history
- Before using `superpowers-ruby:handoff-resume` to see what's available

## The Process

### Step 1: Scan Handoff Directories

```bash
# Active handoffs
ls docs/handoffs/*.md 2>/dev/null

# Archived handoffs
ls docs/handoffs/_archive/*.md 2>/dev/null
```

### Step 2: Parse Frontmatter

For each file found, read the YAML frontmatter to extract: `created`, `topic`, `branch`, `trigger`, `restored`.

### Step 3: Display Table

Present results with active (unrestored) handoffs first, then archived, sorted by date descending:

```
## Active Handoffs

| Date | Topic | Branch | Trigger |
|------|-------|--------|---------|
| 2026-04-14 | handoff-skill | lg/handoff | manual |

## Archived Handoffs

| Date | Topic | Branch | Trigger | Restored At |
|------|-------|--------|---------|-------------|
| 2026-04-13 | auth-refactor | fix/auth | compact | 2026-04-13T15:30:00 |
```

**If no handoffs exist:**

```
No handoff documents found in docs/handoffs/ or docs/handoffs/_archive/.

Use `/superpowers-ruby:handoff` to create one.
```

### Step 4: Offer Next Action

If active handoffs exist, offer:

> "Would you like to resume from one of the active handoffs? Use `/superpowers-ruby:handoff-resume`."

## Pairs With

- **superpowers-ruby:handoff** — Creates new handoff documents
- **superpowers-ruby:handoff-resume** — Resume from a specific handoff
