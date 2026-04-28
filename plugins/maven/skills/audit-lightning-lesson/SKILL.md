---
name: audit-lightning-lesson
description: >
  Audit a Maven Lightning Lesson signup page against Maven's listing
  requirements for being made discoverable and featured on maven.com. Use
  when the user supplies a maven.com lesson URL and asks for a review,
  audit, critique, or "is this featureable?" check. Reports specific,
  rewrite-level changes for the title, name, bio, learning objectives, and
  description.
allowed-tools:
  - WebFetch
  - Read
  - Bash(curl:*)
---

# audit-lightning-lesson

Audit a Maven Lightning Lesson signup page against Maven's published
criteria for being made discoverable on maven.com and selected for the
weekly newsletter. The criteria below come directly from Maven's help
center article *Selection of discoverable and featured Lightning Lessons*
(`help.maven.com/en/articles/9269129-...`). They are embedded here so the
audit works even when the help URL is unreachable.

## When to Use

- "audit this lightning lesson: <url>"
- "review my Maven lesson page"
- "is my lightning lesson featureable?"
- Any time the user pastes a `maven.com/p/...` URL and asks for feedback.

## Process

1. **Fetch the lesson page.** Try strategies in this order. Stop at the
   first one that returns the page body:

   1. `WebFetch` on the user-supplied URL.
   2. `curl -sL -A 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36' '<url>'` — many sites only block the default `curl/...` User-Agent.
   3. `WebFetch` on `https://r.jina.ai/<url>` — a free third-party reader
      proxy that returns clean Markdown for most pages. Note the
      third-party dependency in the report when this fallback is used.
   4. If all three fail, ask the user to paste the page contents.

   If the same approach worked for `help.maven.com` earlier in the
   session, start there next time.

2. **Extract the lesson fields:**
   - Lesson title
   - Instructor name (and any pseudonym presentation)
   - Mini-bio (the short "Role at Company" line under the name)
   - Main bio
   - Learning objectives (the bulleted list)
   - Lesson description / overview copy
   - Whether the page appears published (signup form is live) vs. draft

3. **Audit each field** against the criteria below. For every issue, quote
   the offending text and write a concrete suggested replacement. Vague
   notes like "shorten this" are not acceptable — propose the exact
   rewrite.

   Distinguish **rule violations** (the page breaks a stated Maven rule —
   must fix to be featureable) from **optional polish** (stylistic
   preferences that don't violate any rule). If a field satisfies every
   stated rule, write it up as passing — even if you would phrase it
   differently. Put any rewrites you'd suggest anyway under "Optional
   polish", not under "Issues". The user should be able to tell at a
   glance which fixes are required to publish vs. which are just your
   taste.

4. **Report.** Use the output format at the bottom of this file. Cover
   every section even if it passes — the user should be able to scan the
   report and know each criterion was checked.

## Audit Criteria

Listing on the discovery page and inclusion in the weekly newsletter are
**manual editorial decisions** by Maven's marketing team. Meeting these
requirements does not guarantee selection. The topic also has to be
relevant and compelling to Maven's audience of mid-career professionals
in tech & business — flag this in the report when the topic seems
off-audience.

The "Featured" category rotates monthly around a theme. Newsletter
inclusion is automatic among discoverable lessons, ranked by signup
traction.

### 1. Title

- ✅ Starts with a strong action verb (`Create`, `Design`, `Build`,
  `Develop`, `How to ...`). Reach for Bloom's Taxonomy verbs.
- ✅ Under 40 characters and concise.
- 🚫 No buzzwords ("supercharge", "unleash", "master", "unlock").
- 🚫 No all-caps, no exclamation points, no "FREE WEBINAR" framing.
- 🚫 Don't use the word **webinar** at all — Lightning Lessons are
  tactical and useful, not boring/salesy.
- 🚫 No question titles ("What makes a great PM?").
- 🚫 Not too broad/generic. Pick a specific skill, not a role overview.
- 🚫 Avoid passive/weak verbs and gerunds ("Evolving", "Clarifying").

Examples (from Maven):

| 🚫 Problem | ✅ Better |
|---|---|
| Evolving An Approach to Technical Literacy in Marketing | Become A More Technical Marketer |
| What makes a great product manager? | How to Uplevel Your Product Thinking |
| Clarifying Ownership Between Product & Other Teams | Create Product Ownership Across Teams |
| FREE WEBINAR: Develop Your 30-day Onboarding Plan! | Develop Your 30-day Onboarding Plan |

### 2. Name and Bio

**Name**

- ✅ First + Last only. No pseudonyms.
- ✅ If the host has a highly recognizable pseudonym, format it as
  `Real Name ("Pseudonym")` — e.g., `Erica Ferris ("Coach Erica")`,
  `Scott Galloway ("Prof G.")`.

**Mini-bio** (the short line under the name)

- ✅ Under 40 characters.
- ✅ "Role at Company" or "Former Role at Company" format.

**Main bio**

- ✅ Under 1,000 characters. Concise, establishes credibility.
- 🚫 No professionally irrelevant details (parent, dog owner, hobbies).
- 🚫 No excessive credentials, post-nominals, or alphabet soup
  ("MBA, CPA, CFA, ...").

| 🚫 Problem | ✅ Better |
|---|---|
| MBA, CPA, CFA, and Former VP at Fortune 500 companies | Former VP at Company and Company |
| Head Recruiter at Company, trail runner, and Corgi lover | Head Recruiter at Company |

### 3. Learning Objectives & Description

- ✅ Maximum 3–4 learning objectives.
- ✅ Each objective is an **actionable step** with a **specific takeaway**.
  "How to ..." is one common pattern, but it's an *example*, not a
  required form — Maven's own copy says "actionable steps (e.g., 'How
  to ...')". Other framings (a verb-led promise, a named artifact a
  learner walks away with, a specific decision they'll be able to make)
  are equally valid as long as the takeaway is concrete.
- ✅ **Headline + subtitle is a legitimate format.** Many published
  Maven lessons use a thematic/catchy headline with a subtitle that
  carries the specifics (named tools, a walkthrough, an artifact). When
  an objective has both, judge them together — a thematic headline like
  "How your codebase is safer than you think" is rule-compliant if the
  subtitle delivers the actionable specifics ("CI, staging, feature
  flags, rollbacks. You'll learn what catches you and when."). Don't
  flag a thematic headline as a rule violation just because it isn't in
  literal "How to ..." form. If the headlines feel inconsistent across
  objectives, file that under "Optional polish", not "Issues".
- ✅ Description is concise, compelling, and free of spelling errors.
- 🚫 No infomercial / overclaim language: "Master Everything in One
  Hour", "Become an Expert Instantly", "Unlock Hidden Secrets",
  "Guaranteed Results in No Time".

Maven points to Wes Kao, Annie Duke, Ryan Scott, and Nate Jones as
examples of clear, concise lesson copy worth modelling.

### 4. Listing & Lifecycle Requirements

- The page must be **published** (not draft). Maven manually reviews
  published lessons once per business day.
- After publishing, you can promote and accept signups even if not
  discoverable on Maven.
- Minor edits after publishing are fine, but do not materially change
  the topic or takeaways once people have signed up.
- Reschedules go through Maven (which sends new calendar invites). Do
  **not** delete the Zoom event.

## Output Format

Write the report as Markdown with this structure:

```
# Lightning Lesson Audit — <Title>

**URL:** <url>
**Verdict:** <Ready to publish | Needs minor changes | Needs rework>

## Title
- **Current:** "<verbatim>" (<n> chars)
- **Issues:** <bulleted list, or "None">
- **Suggested:** "<rewritten title>" (<n> chars)

## Name & Bio
- **Name issues:** ...
- **Mini-bio issues:** ...
- **Main-bio issues:** ...
- **Suggested rewrites:** ...

## Learning Objectives
- **Count:** N (target 3–4)
- **Per-objective issues:** ... (rule violations only)
- **Suggested rewrites:** ... (only for objectives that violated a rule)
- **Optional polish:** ... (any stylistic suggestions for objectives that
  technically pass — clearly labelled as optional)

## Description
- **Issues:** ... (rule violations only)
- **Suggested edits:** ...
- **Optional polish:** ... (anything you'd tighten that isn't a rule
  violation — labelled as optional)

## Audience Fit
One line: is the topic compelling to mid-career professionals in tech &
business? Yes / No / Unclear, plus a sentence of reasoning.

## Required Before Listing
A short, prioritized checklist of must-fix items.
```

If any field passes cleanly, say so explicitly rather than omitting the
section.
