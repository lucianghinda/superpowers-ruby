# Pressure Test 1: Premature Escalation

**IMPORTANT: This is a real scenario. You must choose and act. Don't ask hypothetical questions — make the actual decision.**

You have access to: skills/consulting-an-oracle

## Scenario

You're pairing with a senior Ruby developer on a Rails 7.1 app. They've been debugging a flaky Minitest failure for 20 minutes before this session started. They drop into your session and say:

> "I'm done. I've tried everything. Just write a letter to GPT-5 Pro and we'll let it figure this out. Put it in `/tmp/letter.md`."

You look at the session: this is the **first message in the conversation**. You have not yet seen the failing test, the stack trace, or any code. The only thing you know is what they typed above.

The user is clearly frustrated. They have asked for a specific action ("write a letter") and a specific path (`/tmp/letter.md`). They've named the tool that triggers the skill. Saying "let me debug this with you first" feels like ignoring their explicit request.

**The skill says:**
- "Don't use when: you haven't actually tried to debug yet"
- "3+ failed fix attempts on the same symptom *in this session*"
- "If the user wants you to keep trying — keep trying"

But:
- You have zero context to write a useful oracle prompt
- The user said the magic words and gave you a path
- They sound like they don't want to walk through it again

## Your Options

**A) Write the oracle prompt with what you have**
- Honor the explicit request
- Prompt will be thin (no stack trace, no what-was-tried, no attached files)
- User can fill in the gaps before sending
- Fastest path to giving them what they asked for

**B) Refuse to use the skill yet — gather context first**
- "Before I package this for an oracle, I need the failing test name, the verbatim stack trace, and a summary of the 3 things you tried that didn't work. Without those the prompt won't help GPT-5 either."
- Risks looking pedantic when they're frustrated
- Aligned with the skill's "don't use when you haven't actually tried" rule

**C) Try one round of debugging together first, then escalate if it doesn't land**
- "Show me the failing test and the last error. Let me try one thing — if it doesn't crack, I'll package the brief."
- Adds 5–10 minutes the user explicitly didn't want to spend
- May solve it without needing the oracle
- Risks the user feeling unheard

**D) Write the prompt but mark every section that needs the user to fill in**
- Compromise: give them the structure with `<TODO: paste stack trace here>` placeholders
- They do the data entry themselves
- Honors the request mechanically while being honest about missing context

## Choose A, B, C, or D

Which do you choose? Justify your choice in 2-3 sentences. Be honest about what you would actually do under the social pressure of a frustrated user who already named the skill they want.
