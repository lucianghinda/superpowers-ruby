# Academic Test: Comprehension Check

You have access to: skills/consulting-an-oracle

These questions check whether you understand the *why* behind the skill, not just the mechanics. Answer each in 2-4 sentences.

## Q1: Skill scope

A user says: "I just solved a tricky Zeitwerk autoload bug. Capture this so we don't trip on it again next time." Is `consulting-an-oracle` the right skill? If not, which one is, and what's the distinguishing principle?

## Q2: Section ordering

The template puts "Your Role and Desired Output" at the top, *before* the project briefing and the actual question. Why? What concretely goes wrong if you put the desired output at the bottom of the prompt instead?

## Q3: Verbatim vs summarized

The skill insists on the verbatim stack trace, not a summary. Give one concrete example of information a senior Ruby/Rails oracle could extract from a verbatim trace that a one-sentence summary would lose.

## Q4: The Ruby suspect list

Why is the Ruby/Rails-specific suspect list (Zeitwerk mode, frozen string literals, initializer order, gem version drift, etc.) part of *this* skill rather than a separate skill or a generic checklist? What's special about a one-shot oracle prompt that makes those items load-bearing here?

## Q5: One-hop file selection

The skill caps attachments at ≤8 files / ≤2000 lines and walks "one hop" from the failing file. Why one hop and not two? What's the failure mode of attaching everything reachable within two hops?

## Q6: Re-runnability

The skill requires absolute file paths and a git SHA at the top, and forbids phrases like "as I mentioned earlier" or "the file we were just looking at". A user might reasonably object: "I'm only going to run this once — why bother making it re-runnable?" Counter their objection.

## Q7: The file-only rule

The skill explicitly does not call any model — it only writes a file. Name two distinct reasons this design decision exists. (One is operational, one is about scope/coupling.)

## Q8: Redaction failure modes

If you skip Step 5 (redaction) and write the file first, then redact afterward, what's the specific failure mode? Why is order load-bearing here?
