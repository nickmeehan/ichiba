# maven

A Claude Code plugin for hosts publishing Lightning Lessons on
[Maven](https://maven.com). Audits a lesson signup page against Maven's
published criteria for being made discoverable and featured.

## Installation

If you haven't added the ichiba marketplace yet, add it first:

```
/plugin marketplace add nickmeehan/ichiba
```

Then install the plugin:

```
/plugin install maven@ichiba
```

To upgrade later (after the plugin has been updated):

```
/plugin update maven@ichiba
```

If updates don't seem to take effect, clear the local cache:

```bash
rm -rf ~/.claude/plugins/cache
```

## Usage

The plugin ships one skill: `audit-lightning-lesson`. Trigger it by
giving Claude a Maven lesson URL and asking for a review.

Example prompts:

- *"Audit this lightning lesson: https://maven.com/p/abc123"*
- *"Review my Maven lesson page before I publish — https://maven.com/p/..."*
- *"Is this lightning lesson featureable? https://maven.com/p/..."*

You can also invoke it explicitly:

```
/maven:audit-lightning-lesson https://maven.com/p/abc123
```

### Sample output (truncated)

```markdown
# Lightning Lesson Audit — Ship Code Without Breaking Production

**URL:** https://maven.com/p/0f52fc
**Verdict:** Needs minor changes

## Title
- **Current:** "Ship Code Without Breaking Production" (37 chars)
- **Issues:** None.
- **Suggested:** No change. Strong action verb, under 40 chars.

## Name & Bio
- **Mini-bio issues:** "Senior Software Engineer, AI Products" deviates
  from Maven's stated "Role at Company" format. The page already lists
  Ontra in the sidebar, so the mini-bio should anchor there.
- **Suggested rewrite:** `Senior SWE at Ontra` (19 chars)

## Learning Objectives
- **Per-objective issues:** None. Headline + subtitle format is
  legitimate; each subtitle delivers concrete actionable specifics.
- **Optional polish:** Headlines are stylistically inconsistent —
  taste, not a rule violation.

## Required Before Listing
1. Mini-bio: rewrite to "Role at Company" format.
2. Confirm Published.
```

The audit covers every field Maven cares about (title, instructor name,
mini-bio, main bio, learning objectives, description, audience fit) and
distinguishes **rule violations** ("must fix to be featureable") from
**optional polish** ("taste, not blocking publish") so you can tell at
a glance which fixes are required.

## What it checks

Sourced verbatim from Maven's help center article *Selection of
discoverable and featured Lightning Lessons*:

- **Title:** action verb, under 40 chars, no buzzwords ("supercharge",
  "unleash", "master", "unlock"), no all-caps / `!` / "FREE WEBINAR"
  framing, not a question, not a passive gerund.
- **Name:** First + Last (pseudonyms in `Real Name ("Pseudonym")` form
  only when widely recognized).
- **Mini-bio:** under 40 chars, "Role at Company" format.
- **Main bio:** under 1,000 chars, no irrelevant personal details
  (parent, dog owner, hobbies), no alphabet-soup credentials.
- **Learning objectives:** 3–4 max, actionable steps with specific
  takeaways (a "How to ..." pattern is one valid form, not the only
  one — headline + subtitle is also legitimate when the subtitle
  carries the actionable specifics), no infomercial overclaims
  ("Master Everything", "Guaranteed Results", "Unlock Hidden Secrets").
- **Description:** concise, compelling, no infomercial language, no
  spelling errors.
- **Audience fit:** is the topic compelling to mid-career professionals
  in tech & business?

The criteria are embedded directly in the skill so audits work even
when Maven's help URL is unreachable from your environment.

## Fetching pages

The skill tries to fetch the lesson URL through a fallback chain:

1. `WebFetch` (Claude Code's built-in)
2. `curl` with a desktop User-Agent (some sites block default
   `curl/...`)
3. `r.jina.ai` reader proxy (returns clean Markdown for most pages)
4. Asks you to paste the page content

If your network blocks all three (e.g., a sandboxed CI environment),
just paste the page contents into the chat — the audit works the same
way against pasted text.

## Source

Maven's listing requirements:
<https://help.maven.com/en/articles/9269129-selection-of-discoverable-and-featured-lightning-lessons>

## Disclaimer

Meeting the criteria makes a lesson **eligible** for the discovery
page and the weekly newsletter — it does not guarantee selection.
Maven's marketing team curates the discovery page manually, and
newsletter inclusion is algorithmically ranked among discoverable
lessons by signup traction. This plugin maximises eligibility, not
selection.
