---
name: superpowers-ruby:handoff
description: Use when capturing session state before switching context, ending a session, or manually preserving progress — creates a structured handoff document in docs/handoffs/ so a future session can resume seamlessly
---

# Handoff

## Overview

Capture the current session's state into a structured handoff document so a future session (or a different agent) can resume without losing context. The handoff document records goals, decisions, progress, and next steps.

**Core principle:** Capture what the next session needs to know — not everything that happened.

**Announce at start:** "I'm using the handoff skill to capture session state."

## When to Use

- Before ending a long session with unfinished work
- Before switching to a different task or branch
- When context is getting large and compaction is likely
- When handing off work to another person or agent

**Don't use when:**
- Work is fully complete (use `superpowers-ruby:finishing-a-development-branch` instead)
- Capturing a solved problem (use `superpowers-ruby:compound` instead)

## Quick Reference

```bash
/superpowers-ruby:handoff              # Create a full handoff document
/superpowers-ruby:handoff-resume       # Resume from the latest handoff
/superpowers-ruby:handoff-list         # List available handoffs
```

**Output location:** `docs/handoffs/YYYY-MM-DD-<topic>.md`
**Archive location:** `docs/handoffs/_archive/`

## The Process

### Step 1: Gather Mechanical State

Run these commands to collect file-level state:

```bash
# Modified files
git diff --name-only
git status --porcelain

# Detect plan files
ls .claude/plans/*.md 2>/dev/null
ls docs/superpowers/specs/*.md 2>/dev/null
ls docs/superpowers/plans/*.md 2>/dev/null
```

### Step 2: Generate Topic

Derive a short topic slug from the current work context. Use the branch name as a starting point, stripped of prefixes like `feature/`, `fix/`, `lg/`. If no branch context, ask the user or derive from the goal.

**Topic slug guidelines:**
- Describe the **work being done**, not the branch or ticket — `auth-jwt-migration` not `fix-auth` or `JIRA-1234`
- Use **2-4 words** in lowercase kebab-case, max 40 characters — enough to distinguish at a glance when scanning `docs/handoffs/`
- Focus on the **subject and action** — what thing is being changed and how: `stimulus-form-validation`, `stripe-webhook-retry-logic`
- Avoid generic slugs like `bugfix`, `refactor`, `updates` — these are meaningless when you have 10 handoffs in the directory
- When in doubt, match the style of existing handoffs in `docs/handoffs/` — consistency beats cleverness

### Step 3: Write the Handoff Document

Create a file at `docs/handoffs/YYYY-MM-DD-<topic>.md` with this structure:

```markdown
---
created: <ISO 8601 UTC timestamp>
branch: <current git branch>
trigger: manual
restored: false
topic: <topic slug>
---

# Handoff: <descriptive title>

## Goal
<What we're working on and why — 2-3 sentences max>

## Current State
<What's done, what's in progress, what's blocked — bullet list>

## Key Decisions
<Important choices made and their rationale — bullet list with "decision — rationale" format>

## Modified Files
<From git status/diff — bullet list of file paths>

## Failed Approaches
<What was tried and didn't work, so the next session doesn't repeat it — bullet list>

## Files to Read
<Plan files, specs, design docs the next session should read first — bullet list with backtick paths>

## Next Steps
<Concrete actions to take next — numbered list, most important first>

## Open Questions
<Unresolved uncertainties or decisions that need user input — bullet list>
```

### Step 4: Fill All Sections

Unlike the hook-triggered version (which leaves `<!-- to be enriched by LLM -->` markers), the manual skill fills **every section** from conversation context:

- **Goal:** Summarize from the user's original request and any refined understanding
- **Current State:** What has been implemented, what's passing, what remains
- **Key Decisions:** Design choices, trade-offs, rejected alternatives with reasons
- **Modified Files:** From git commands in Step 1
- **Failed Approaches:** Debugging dead ends, approaches that were tried and abandoned
- **Files to Read:** Plan files from Step 1 plus any files the user specifically referenced
- **Next Steps:** The remaining work, ordered by priority
- **Open Questions:** Anything that needs clarification before the next session can proceed

### Step 5: Confirm

```
Handoff saved to `docs/handoffs/<filename>.md`

Summary:
- Goal: <one-line summary>
- Next steps: <count> items remaining
- Files to read: <count> documents
```

## Automatic Compaction Handoff

This skill also runs automatically via hooks when context compaction occurs:

- **Claude Code:** `PreCompact` hook runs `hooks/handoff-create` before compaction
- **OpenCode:** `experimental.session.compacting` event triggers the same script
- **Codex:** No compaction hooks available — use this skill manually

The hook-generated handoff captures mechanical state only (modified files, plan files). After compaction, the `PostCompact` hook (or `session.compacted` event) restores the handoff as `additionalContext` and instructs the agent to fill in the LLM-dependent sections from compacted context.

## Cross-Agent Handoff

Handoff documents are plain markdown files in `docs/handoffs/` — any agent or tool that can read the filesystem can resume from them. This makes handoffs work across agent boundaries, not just within the same session.

**Use cases:**

- **Claude Code → OpenCode:** Create a handoff in Claude Code, then open OpenCode in the same project. Use `/superpowers-ruby:handoff-resume` to pick up where Claude Code left off.
- **Agent → Human:** A developer reviews `docs/handoffs/` to understand what the agent was working on, then continues manually or starts a new session with context.
- **Human → Agent:** A developer writes a handoff document manually (following the template above) to brief an agent on work-in-progress before starting a session.
- **Subagent → Parent:** A subagent creates a handoff before finishing, so the orchestrating agent can dispatch a new subagent with full context.
- **Session A → Session B (same tool):** End a Claude Code session, start a fresh one later. The handoff persists on disk — use `handoff-resume` to continue.

**Why this works:** The handoff document is the contract. It doesn't depend on any specific agent's memory, context window, or session state. Any agent that can read markdown and follow instructions can resume from it.

## Pairs With

- **superpowers-ruby:handoff-resume** — Resume from a handoff in a new session
- **superpowers-ruby:handoff-list** — View available handoffs
- **superpowers-ruby:compound** — For capturing *solved* problems (handoff is for *in-progress* work)
- **superpowers-ruby:finishing-a-development-branch** — For *completed* work (handoff is for *unfinished* work)
