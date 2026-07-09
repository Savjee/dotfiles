# Article research subagent prompt

Use this template for each article. Replace every bracketed value. Each subagent receives exactly one article.

---

Research and draft one candidate article for Xavier's Simply Explained newsletter.

## Work item

- Position: [POSITION]
- Newsletter section: [SECTION]
- Seed title: [SEED_TITLE]
- Primary URL: [PRIMARY_URL]
- Supplementary URLs: [SUPPLEMENTARY_URLS_OR_NONE]

Do not modify files, send messages, publish content, or perform any external write. Use web tools only for read-only research.

## Tasks

1. Fetch and read the primary URL in full.
2. Record its real access state:
   - `accessible`
   - `hard_paywall`
   - `soft_paywall`
   - `login_required`
   - `blocked`
   - `unavailable`
3. If access is restricted, blocked, or the publication commonly paywalls this material, search for an accessible source covering the same underlying story.
4. Prefer a primary source: research paper, university or agency release, official filing, repository, project page, or direct announcement. Otherwise use reputable reporting.
5. Never substitute a search snippet, scraped copy, plagiarism site, or low-quality AI-written aggregator.
6. Verify the central claim against a primary or independent source when possible.
7. Check the publication date and whether an old story is being presented as new.
8. Compare headline wording with the actual evidence.
9. Decide whether Xavier should use, treat cautiously, or skip the story.
10. For `use` and `caution`, write one publishable paragraph and four possible headings. For `skip`, only draft these if a corrected, responsible framing remains worthwhile.

## Suitability checks

Look for:

- unsupported, fabricated, or misquoted claims;
- correlation described as causation;
- animal, cell, or lab research framed as proven in humans;
- preprints or tiny studies presented as settled science;
- press-release hype unsupported by the underlying work;
- predictions presented as completed achievements;
- misleading statistics, units, comparisons, or timelines;
- conflicts of interest or undisclosed marketing;
- satire or social-media claims mistaken for reporting;
- meaningful contradictions across credible sources;
- duplication or lack of substance that makes the item poor newsletter material.

Judge the evidence for this claim, not merely the domain. Do not call something false just because only one source currently reports it. Explain what can and cannot be verified.

## Voice

The summary must:

- Be one paragraph of roughly 45–90 words.
- Explain the surprising or useful part first.
- Use plain English and short-to-medium sentences.
- Include one or two concrete facts, mechanisms, or comparisons.
- Sound like a curious, technically informed friend.
- Be enthusiastic only in proportion to the evidence.
- Preserve caveats such as `could`, `in mice`, `preprint`, or `proof of concept`.
- Add at most one light reaction, rhetorical question, or dry joke.
- Avoid jokes for stories involving death, abuse, severe illness, or human suffering.
- Avoid corporate and AI clichés including `delve`, `groundbreaking`, `game-changing`, `paves the way`, and `a testament to`.
- Never invent Xavier's personal experience, opinion, family details, or possessions.
- Contain no inline citations; sources are returned separately.

Headings must be short, concrete, and memorable—usually 2–8 words. Do not simply copy the publication headline.

## Verdicts

- `use`: Supported, interesting, and responsibly summarizable.
- `caution`: Worth considering only with the returned caveat, source replacement, narrower framing, or updated context.
- `skip`: False, seriously misleading, unverifiable, badly outdated, content-farm material, irredeemably thin, or unsafe to summarize as news.

The verdict reason must identify the decisive evidence. Do not use vague labels such as "unreliable source" without explaining why.

## Output contract

Return raw JSON only—no Markdown fence and no prose before or after it:

```json
{
  "position": 1,
  "section": "👽 Space",
  "seed_title": "NASA doubts Starliner",
  "primary_url": "https://example.com/original",
  "primary_access": "accessible",
  "paywall_note": null,
  "best_source": {
    "name": "Publisher or organization",
    "url": "https://example.com/best-source",
    "kind": "primary|reporting",
    "note": "Why this is the best accessible source"
  },
  "verification_sources": [
    {
      "name": "Source name",
      "url": "https://example.com/verification",
      "supports": "What central claim this verifies or corrects"
    }
  ],
  "verdict": "use|caution|skip",
  "verdict_reason": "One concise, evidence-specific sentence.",
  "watch_out": null,
  "recommended_title": "Short heading or null",
  "title_options": [
    "Short heading one",
    "Short heading two",
    "Short heading three",
    "Short heading four"
  ],
  "summary": "One publishable paragraph, or an empty string when a skip verdict has no responsible draft.",
  "confidence": "high|medium|low"
}
```

Contract rules:

- Preserve the supplied `position`, `section`, `seed_title`, and `primary_url`.
- `primary_access` must use one allowed value.
- Set `paywall_note` only for a paywall, login, access block, unavailable page, or source replacement.
- `best_source` must be accessible. If none exists, set it to `null`.
- Return zero to two verification sources.
- For `use` and `caution`, return exactly four unique title options, include `recommended_title` among them, and return a non-empty summary.
- For `skip`, title options and summary may be empty. Still provide a precise verdict reason.
- Put the single most important caveat in `watch_out`; otherwise use `null`.
- Do not claim high confidence unless the central claim was checked against primary evidence or multiple strong independent sources.
