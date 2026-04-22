---
name: superpowers-ruby-handoff-resume
description: Use when starting a new session and wanting to continue from a previous handoff — reads the latest unrestored handoff document and restores session context
---

# Handoff Resume

## Overview

Resume work from a previously created handoff document. Finds the latest unrestored handoff, reads it, marks it as consumed, archives it, and sets up the session to continue from where the previous session left off.

**Core principle:** Read the handoff, understand the context, then continue from Next Steps.

**Announce at start:** "I'm using the handoff-resume skill to restore session context."

## When to Use

- Starting a new session to continue previous work
- After a session was ended without completing work
- When a colleague or agent left a handoff for you
- When you see handoff documents exist in `docs/handoffs/`

**Don't use when:**
- Context was just compacted (the `PostCompact` hook handles this automatically)
- There is no handoff document to resume from

## The Process

### Step 1: Find Unrestored Handoffs

```bash
# Look for handoff files with restored: false
ls docs/handoffs/*.md 2>/dev/null
```

Read each file's frontmatter and filter for `restored: false`. Sort by `created` date, newest first.

### Step 2: Select Handoff

**If one unrestored handoff exists:** Use it automatically.

**If multiple unrestored handoffs exist:** Present them and ask which to resume:

```
Found multiple unrestored handoffs:

| # | Date | Topic | Branch |
|---|------|-------|--------|
| 1 | 2026-04-14 | handoff-skill | lg/handoff |
| 2 | 2026-04-13 | auth-refactor | fix/auth |

Which handoff should I resume from?
```

**If no unrestored handoffs exist:** Check the archive:

```bash
ls docs/handoffs/_archive/*.md 2>/dev/null
```

If archived handoffs exist, list them and offer to re-open one. If none exist at all, inform the user.

### Step 3: Read and Present

Read the full handoff document. Present a summary:

```
Resuming from handoff: <topic>
- Branch: <branch>
- Created: <date>
- Goal: <goal summary>
- Next steps: <count> items
- Files to read: <count> documents
```

### Step 4: Mark as Restored and Archive

Update the handoff file's frontmatter:
- Set `restored: true`
- Add `restored_at: <ISO 8601 UTC timestamp>`

Move the file to `docs/handoffs/_archive/`.

### Step 5: Restore Context

1. **Read the Files to Read section first** — open each referenced plan, spec, or doc
2. **Review the Current State and Key Decisions** — understand what was done and why
3. **Check Modified Files** — run `git status` to see if the working tree matches expectations
4. **Note Failed Approaches** — avoid repeating what didn't work
5. **Continue from Next Steps** — start working on the first item

If any sections contain `<!-- to be enriched by LLM -->` markers (from a hook-generated handoff), fill them in from available context before proceeding.

## Pairs With

- **superpowers-ruby:handoff** — Creates the handoff documents this skill resumes from
- **superpowers-ruby:handoff-list** — View all available handoffs before choosing
