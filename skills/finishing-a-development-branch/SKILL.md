---
name: finishing-a-development-branch
description: Use when implementation is complete, all tests pass, and you need to decide how to integrate the work - guides completion of development work by presenting structured options for merge, PR, or cleanup
---

# Finishing a Development Branch

## Overview

Guide completion of development work by presenting clear options and handling chosen workflow.

**Core principle:** Verify tests → Detect environment → Present options → Execute choice → Clean up.

**Announce at start:** "I'm using the finishing-a-development-branch skill to complete this work."

## The Process

### Step 1: Verify Tests

**Before presenting options, verify tests pass:**

```bash
# Run project's test suite
bin/rails test          # Ruby on Rails
bundle exec rspec       # RSpec
# npm test / cargo test / pytest / go test ./...  (other project types)
```

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Detect Environment

Capture these **now**, while still inside the workspace. Step 5 changes
directory, and Step 6 needs values from before that change:

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
WORKTREE_PATH=$(git rev-parse --show-toplevel)
```

This determines which menu to show and how cleanup works:

| State | Menu | Cleanup |
|-------|------|---------|
| `GIT_DIR == GIT_COMMON` (normal repo) | Standard 3 options | No worktree to clean up |
| `GIT_DIR != GIT_COMMON`, named branch | Standard 3 options | Provenance-based (see Step 6) |
| `GIT_DIR != GIT_COMMON`, detached HEAD | Reduced 2 options (no merge) | Externally managed — leave in place |

### Step 3: Determine Base Branch

The base branch is whatever this work forked from — usually named in the plan,
the conversation, or the branch's upstream:

```bash
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If it is not already known, ask: "This branch split from main - is that
correct?" Confirm before merging; merging into the wrong base is expensive
to undo.

### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 3 options:**

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)

Which option?
```

**Detached HEAD — present exactly these 2 options:**

```
Implementation complete. You're on a detached HEAD (externally managed workspace).

1. Push as new branch and create a Pull Request
2. Keep as-is (I'll handle it later)

Which option?
```

**Don't add explanation** - keep options concise.

Discarding the work is not on the menu. It happens only when your human
partner explicitly asks for it (see "If your human partner asks to discard
the work" below). Wait for their answer; the integration decision is theirs.

### Step 5: Execute Choice

#### Option 1: Merge Locally

```bash
# Worktree removal must run from outside the worktree — move to the main
# repo root before touching anything
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"

# Merge first — verify success before removing anything
git checkout <base-branch>
git pull
git merge <feature-branch>

# Verify tests on merged result
<test command>
```

If tests fail on the merged result: stop, leave the worktree and branch in
place, and investigate. Nothing has been pushed, so the merge is local and
recoverable.

Once the merged result is green, **clean up the worktree (Step 6) first**,
then delete the branch:

```bash
git branch -d <feature-branch>
```

Order matters: git refuses to delete a branch that is still checked out in a
worktree — `error: cannot delete branch '<name>' used by worktree at '<path>'`.
If you see that, Step 6 has not run yet.

#### Option 2: Push and Create PR

```bash
git push -u origin <feature-branch>

gh pr create --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"

# From a detached HEAD, name the new branch on the remote first:
# git push origin HEAD:refs/heads/<new-branch>
```

On a non-GitHub forge, use that forge's CLI or the creation URL printed after
the push. Report the URL back to your human partner.

**Keep the worktree** — your human partner iterates on PR feedback there.

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't clean up the worktree.**

#### If your human partner asks to discard the work

This path exists only as a response to an explicit request to throw the work
away.

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for that exact confirmation. When it arrives:

```bash
MAIN_ROOT=$(git -C "$(git rev-parse --git-common-dir)/.." rev-parse --show-toplevel)
cd "$MAIN_ROOT"
```

Then clean up the worktree (Step 6) and force-delete the branch:

```bash
git branch -D <feature-branch>
```

### Step 6: Cleanup Workspace

**Runs for Option 1 and confirmed discards.** Options 2 and 3 always preserve
the worktree.

Both callers have already changed directory to the main repo root, and both
use the `GIT_DIR` / `GIT_COMMON` / `WORKTREE_PATH` values captured in Step 2 —
from *before* that directory change. Recomputing them here reads the base
branch and the main worktree instead, which is how this step used to remove
the wrong thing or nothing at all.

**If `GIT_DIR == GIT_COMMON`:** Normal repo, no worktree to clean up. Done.

**Otherwise, clean up only worktrees this project created:**

```bash
case "$WORKTREE_PATH" in
  */.worktrees/*|*/worktrees/*|"$HOME"/.config/superpowers/worktrees/*)
    git worktree remove "$WORKTREE_PATH"
    git worktree prune   # self-healing: drop stale registrations
    ;;
  *)
    echo "Host-managed workspace — leaving $WORKTREE_PATH in place"
    ;;
esac
```

Those three locations are exactly the ones `using-git-worktrees` creates.
Anything else belongs to the host environment; if your platform provides a
workspace-exit tool, use that instead.

If `git worktree remove` refuses because the worktree is dirty, **stop and
report it**. A dirty worktree may hold uncommitted work nobody has looked at;
`--force` throws it away silently.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | ✓ | - | - | ✓ |
| 2. Create PR | - | ✓ | ✓ | - |
| 3. Keep as-is | - | - | ✓ | - |
| Discard (explicit request only) | - | - | - | ✓ (force) |

## Common Rationalizations

| Excuse | Reality |
|--------|---------|
| "Tests passed earlier this session" | Run the suite on the tree you are about to integrate. A green run only proves the tree it ran on. |
| "They obviously want it merged" | Integration is your human partner's decision. Present the menu and wait. |
| "They seem done with this feature — I'll offer to discard it" | The menu is complete as written. Discard happens only when your human partner asks for it in so many words. |
| "'Yeah, get rid of it' counts as confirmation" | Only the typed word `discard` authorizes deletion. |
| "The PR is up, so the worktree is clutter now" | PR feedback gets fixed in that worktree. It stays until the work lands. |
| "This other worktree looks stale — I'll clean it too" | Clean up only the three locations `using-git-worktrees` creates. Everything else belongs to the host. |
| "I'll just recompute the worktree path in Step 6" | You are standing on the base branch by then. Use the values captured in Step 2. |
| "The merged-result failure is probably flaky" | A failing merged result stops everything. Branch and worktree stay put while you investigate. |
| "The base branch is obviously main" | Confirm the fork point or ask. Merging into the wrong base is expensive to undo. |
| "The push was rejected — force-push will fix it" | A rejected push means the remote moved. Investigate; force-push only on your human partner's explicit request. |

## Red Flags

**Never:**
- Proceed with failing tests
- Merge without verifying tests on result
- Delete work without confirmation
- Force-push without explicit request
- Delete the branch before removing its worktree
- `git worktree remove --force` to get past a dirty worktree

**Always:**
- Verify tests before offering options
- Present the menu exactly as written
- Get typed confirmation before discarding
- Clean up the worktree for Option 1 and confirmed discards only

## Integration

**Called by:**
- **subagent-driven-development** (Step 7) - After all tasks complete
- **executing-plans** (Step 5) - After all batches complete

**Pairs with:**
- **using-git-worktrees** - Cleans up worktree created by that skill
