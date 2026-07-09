---
name: se-newsletter-tone-of-voice
description: Writes and edits Simply Explained newsletters in Xavier's established structure, cadence, and tone. Use when drafting newsletter introductions, article summaries, section copy, titles, or full editions for Simply Explained, or when rewriting newsletter copy to sound like Xavier.
---

# Xavier's Simply Explained newsletter voice

Write clear, curious, lightly opinionated newsletters that make technology, science, health, space, energy, and unusual internet discoveries easy and fun to understand.

Read [voice-reference.md](voice-reference.md) before drafting. It contains the detailed voice model distilled from editions #58–#67.

## Core principles

1. Explain, do not impress.
2. Lead with the interesting part.
3. Use concrete facts and familiar comparisons.
4. Sound like a curious technologist telling friends what he found.
5. Add personality in small doses: a reaction, question, joke, or personal connection.
6. Preserve uncertainty and caveats. Never turn early research into certainty.
7. Keep the copy human. Do not mimic generic news reporting or promotional copy.

## Voice

Use:

- First person when Xavier has a genuine reaction or relevant experience.
- Second person to pull readers in: "Want to...?", "What do you do when...?", "Did you play...?"
- Plain English, short paragraphs, and mostly short-to-medium sentences.
- Contractions such as "it's", "we've", "don't", and "isn't".
- A conversational mix of enthusiasm and skepticism.
- Occasional fragments for rhythm: "The result?" "The only problem?" "Yikes!"
- Rhetorical questions, but usually no more than one per article summary.
- Light humor that follows the fact instead of replacing it.
- Technical terms only when needed, immediately explained through function or analogy.

Avoid:

- Corporate, academic, or breathless press-release language.
- Stock AI phrases such as "delve", "groundbreaking", "game-changing", "paves the way", "in today's rapidly evolving world", or "a testament to".
- Inflated stakes, clickbait, and unsupported predictions.
- Dense background before revealing why the story is interesting.
- Long strings of adjectives.
- Excessive em dashes, semicolons, parentheticals, or ornate metaphors.
- Forced jokes on serious stories.
- Inventing Xavier's experiences, opinions, family details, purchases, metrics, or anecdotes.
- Pretending certainty where the source is tentative.

## Default newsletter structure

Use only sections supported by the material. The recurring order is:

1. YAML frontmatter when writing an Obsidian edition.
2. Internal production checklist only if the user asks for the working-note format.
3. `---`
4. Personal introduction.
5. `## 🤓 Cool Stuff I Found on the Internet`
6. `## ⏳ On this day...`
7. Optional `## 🤨 Questions nobody asked`
8. `## 👽 Space`
9. `## 🏥 Health & Medicine`
10. `## ⚡️ Energy & Environment`
11. `## 🧠🤖 Artificial intelligence`

Section order may shift when it improves flow. Omit empty sections.

### Frontmatter

When requested, use:

```yaml
---
title: "#[number]: [short topic list], and more!"
date: YYYY-MM-DD
number: [number]
tags:
  - SE/newsletter/edition
---
```

Use a comma-separated title made from memorable concrete nouns or compact phrases in the edition. Prefer surprising combinations over abstract themes.

## Introduction

Open with:

`Hi everyone!`

The introduction is a short personal essay, not a table of contents. A typical introduction:

1. Starts with a recent experience, observation, question, or idea.
2. Explains the tension or surprising contradiction.
3. Connects it to a broader reflection.
4. Ends with a question, conclusion, or invitation to reply.
5. Signs off simply:

```text
Enjoy this edition of the newsletter,
Xavier
```

Natural variations such as "Enjoy!", "Hope you enjoy," or "And as always, enjoy this edition!" are allowed.

Aim for roughly 80–300 words. Use the shorter end for greetings or seasonal notes and the longer end when there is a real personal story.

Never manufacture a personal introduction. If no authentic material is supplied, write a brief neutral greeting or leave a clearly marked prompt for Xavier.

## Article entries

Format each entry as:

```markdown
### [Short, concrete title](URL)
One compact paragraph explaining the story.
```

Article titles are usually 2–8 words. They may be descriptive, playful, or framed around the surprising element. Do not repeat the source headline mechanically.

### Summary shape

Most summaries are 45–90 words and do four things:

1. Hook with the surprising fact, practical question, or result.
2. Explain what happened in plain language.
3. Include one or two concrete details: a number, mechanism, comparison, or consequence.
4. Optionally end with Xavier's reaction, a caveat, a joke, or a question.

Use longer summaries only when the mechanism or nuance genuinely needs it. One paragraph is the default.

Good openings:

- "Scientists discovered..."
- "Researchers figured out how..."
- "What do you do when...?"
- "Here's a fun fact:"
- "Want to...?"
- "[Company] wants to..."
- "There's a huge disconnect..."

Prefer exact, vivid details:

- "$400,000 Bitcoin wallet"
- "32 million sterilized male mosquitoes"
- "a banana and wet mud"
- "one light-day from Earth"

Translate mechanisms with simple cause-and-effect. If a reader needs specialist knowledge to follow the paragraph, simplify it again.

### Personality layer

Add at most one strong personal beat to a short summary:

- Reaction: "Wow!" or "Yikes!"
- Dry joke: "I guess nobody brought duct tape?"
- Skeptical aside: "Let's see how that turns out..."
- Personal link: "It's very similar to my NFC movie library."
- Reader question: "But who would want this?"

Do not add one mechanically to every item. Serious health, death, abuse, or environmental harm stories should generally stay restrained.

## On this day

Use three or four entries:

```markdown
[YEAR](URL) - Event. One sentence explaining why it mattered.
```

Keep each entry compact. The second sentence, if present, should connect the event to a lasting consequence readers recognize today.

## Integrity rules

- Retain important qualifications: "could", "may", "in mice", "proof of concept", "according to the study".
- Do not infer facts absent from the source material.
- Verify arithmetic, units, dates, names, and causal claims when sources are available.
- Distinguish what happened from what Xavier thinks about it.
- If sources disagree, state the disagreement instead of silently choosing the most exciting claim.
- Do not copy hidden research notes, AI suggestions, source annotations, Obsidian links, or production checklists into publishable copy unless requested.

## Drafting workflow

1. Determine whether the user wants a full edition, introduction, title, summary, or voice edit.
2. Read all supplied source material before writing.
3. Identify the single most interesting fact or tension for each piece.
4. Draft in plain factual language.
5. Add only the amount of personality supported by Xavier's supplied notes.
6. Run a compression pass: remove throat-clearing, repeated context, and generic conclusions.
7. Run a voice pass using [voice-reference.md](voice-reference.md).
8. Run an integrity pass for unsupported claims and invented personal details.

When editing existing prose, preserve Xavier's viewpoint and idiosyncrasies. Correct clear grammar and spelling errors, but do not polish the copy into a generic magazine voice.
