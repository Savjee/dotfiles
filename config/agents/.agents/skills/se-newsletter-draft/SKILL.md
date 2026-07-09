---
name: se-newsletter-draft
description: Researches and drafts Simply Explained newsletter entries from article links selected in a Markdown working draft. Use when Xavier asks to process, research, summarize, fact-check, or draft selected newsletter articles. Runs one web-enabled subagent per article in parallel, checks paywalls and alternatives, assesses reliability and suitability, proposes titles, and returns a concise Markdown briefing in the terminal.
---

# Draft a Simply Explained newsletter

Turn the article links in Xavier's working draft into a high-signal Markdown briefing. Research and draft every article independently, then combine the results in the order of the newsletter.

This skill supports writing; it does not choose the article lineup or edit the newsletter file unless Xavier explicitly asks.

## Required companion voice

Load the `xavier-newsletter-voice` skill before drafting if it is installed. Follow its style and integrity rules.

If it is unavailable, use this fallback:

- Explain the interesting part first in plain English.
- Write one paragraph of roughly 45–90 words.
- Include one or two concrete facts or mechanisms.
- Sound like a curious, technically informed friend.
- Mix enthusiasm with skepticism.
- Add at most one light reaction, question, or joke.
- Preserve qualifications such as "could", "in mice", or "proof of concept".
- Never invent Xavier's experience or opinion.

Read [article-agent-prompt.md](article-agent-prompt.md) before launching subagents.

## Input

Accept either:

- A Markdown newsletter file containing linked article headings, as in:

```markdown
## 👽 Space

### [NASA doubts Starliner](https://example.com/article)
> Source: [[Tweet - source note]]
```

- A pasted list of article URLs, optionally grouped into newsletter sections.

If neither a file nor article links are available, ask for them. Do not ask other questions unless the ambiguity changes which items should be processed.

## Extract the worklist

1. Read the working draft.
2. Collect linked `###` headings under newsletter sections.
3. Preserve section and article order.
4. Treat bare links immediately below an article as supplementary sources for that article.
5. Ignore links in the introduction, production checklist, source-note wikilinks, and already-written prose unless Xavier asks to reprocess them.
6. Do not treat `On this day` entries as articles unless explicitly requested.
7. Flag entries with no usable URL in the final report; do not invent one silently.

Create one work item per article:

- Position
- Section
- Seed title
- Primary URL
- Supplementary URLs, if any

## Mandatory parallel subagent workflow

Every article with a usable URL must be fetched, checked, and drafted by its own subagent.

1. Launch all article subagents in one message so they run concurrently.
2. Use `generalPurpose` subagents.
3. Use the default model unless Xavier requested a specific available model.
4. Set `run_in_background: false` so results can be assembled into one clean response.
5. Do not use read-only mode because the researcher needs web access. Explicitly tell each subagent not to modify files or perform external writes.
6. Give each subagent only one article work item, the full instructions from [article-agent-prompt.md](article-agent-prompt.md), and the fallback voice rules above. Subagents do not inherit the conversation or loaded skills.
7. Require structured JSON only from each subagent.
8. If platform concurrency is limited, launch the largest possible parallel waves. Still use exactly one primary subagent per article.
9. If a subagent fails technically or returns unusable JSON, retry that article once with a fresh subagent. Report a failure instead of researching the article in the parent agent.

Do not fetch and process articles serially in the parent agent. The parent only extracts the worklist, launches researchers, validates their returned structure, and formats the combined briefing.

## What each subagent must do

For its one article, the subagent must:

1. Fetch and read the primary URL rather than relying on a headline or snippet.
2. Detect access restrictions:
   - hard paywall or login wall;
   - metered or soft paywall;
   - blocked fetch, bot protection, or unavailable page.
3. If access is restricted or the publisher is known for paywalled articles, search for an accessible report of the same story.
4. Prefer alternatives in this order:
   - original paper, official announcement, repository, filing, or project page;
   - reputable public-interest or wire reporting;
   - another established publication with meaningful reporting.
5. Do not use scraped copies, plagiarism sites, AI-content farms, or search snippets as substitute articles.
6. Verify the central claim with at least one independent or primary source whenever possible.
7. Assess suitability based on the evidence, not merely the publisher's reputation.
8. Draft one publishable summary paragraph in Xavier's voice.
9. Propose four short, concrete newsletter headings and identify the best one.
10. Return the JSON contract from the prompt exactly.

## Suitability guard

Use one verdict:

- `use`: The central claim is supported, interesting, and can be summarized responsibly.
- `caution`: Potentially useful, but requires an explicit caveat, better source, narrower framing, or updated context.
- `skip`: Misleading, false, unverifiable, badly outdated, trivial beyond repair, duplicated in the edition, or impossible to summarize responsibly from available evidence.

Check especially for:

- A headline stronger than the underlying evidence.
- Correlation presented as causation.
- Animal or lab results framed as a human treatment.
- Press releases with no accessible study or independent support.
- Tiny samples, missing controls, or preprints presented as settled science.
- Fabricated quotes, dates, institutions, people, or statistics.
- Old stories presented as new.
- Satire or social posts mistaken for reporting.
- Conflicts of interest or marketing disguised as news.
- Numbers with no meaningful denominator or comparison.
- Predictions framed as accomplished facts.
- Contradictions between the article and primary sources.

Do not over-penalize a strong story for minor errors. Recommend a corrected framing when that solves the problem.

## Paywall behavior

- If the original is accessible, use it when it is the best source.
- If an accessible, trustworthy alternative exists, link the newsletter heading to that source and note the replacement briefly.
- If no adequate accessible alternative exists, clearly say so.
- If no full source can be read and the central claims cannot otherwise be verified, use `skip` and do not fabricate a summary.
- Never reconstruct a paywalled article from snippets and present it as fully read.
- A blocked fetch alone does not prove a paywall; label the actual access problem accurately.

## Parent validation

Before formatting:

1. Confirm one result or explicit failure exists for every work item.
2. Ensure summaries are one paragraph and contain no citations inside the prose.
3. For `use` and `caution`, ensure the selected heading appears among the proposed titles.
4. Reject unsupported first-person claims attributed to Xavier.
5. Preserve caveats required by `caution` verdicts.
6. Normalize verdict labels and source notes without rewriting away substance.
7. Keep the original newsletter order, not completion order.

## Terminal output

Return Markdown only. Do not narrate the research process.

Start with:

```markdown
# Article briefing

**11 articles:** 8 use · 2 caution · 1 skip
```

Then group results under their existing newsletter section:

```markdown
## 👽 Space

### 1. NASA doubts Starliner
**Verdict:** ✅ Use
**Sources:** [Best accessible source](URL) · [Verification](URL)

#### [Recommended title](BEST_URL)
One publishable summary paragraph in Xavier's voice.

**Other titles:** `Option two` · `Option three` · `Option four`
```

Add only applicable alert lines:

```markdown
**Paywall:** Original is paywalled; using an accessible alternative.
**Watch-out:** The headline implies causation, but the study shows correlation.
```

For `caution`, use `⚠️ Caution`. For `skip`, use `❌ Skip` and place the concise reason before any draft:

```markdown
**Verdict:** ❌ Skip — the claimed study does not exist and the statistic is repeated only by low-quality aggregators.
```

For missing URLs or failed subagents, use `⚠️ Could not process` and state the exact blocker.

## Signal-to-noise rules

- No research diary, tool commentary, generic praise, or repeated explanations.
- No long credibility essays. Put the decisive issue in one `Watch-out` line.
- Omit `Paywall` and `Watch-out` when there is nothing useful to report.
- List no more than two verification sources.
- Do not include subagent JSON in the terminal output.
- Do not add an introduction, edition title, article selection advice, or production checklist unless requested.
- End after the final article. Do not offer generic next steps.
