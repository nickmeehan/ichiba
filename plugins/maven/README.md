# maven

Tools for hosts publishing Lightning Lessons on [Maven](https://maven.com).

## Installation

```bash
/plugin install maven@nickmeehan/ichiba
```

## Skills

### `audit-lightning-lesson`

Audits a Maven Lightning Lesson signup page against Maven's published
criteria for being made discoverable on maven.com and selected for the
weekly newsletter.

Invoke it by giving Claude a `maven.com/p/...` URL and asking for a
review:

- "audit this lightning lesson: https://maven.com/p/..."
- "review my Maven lesson page"
- "is my lightning lesson featureable?"

The skill fetches the page (with fallbacks for bot-blocked fetches) and
reports specific, rewrite-level changes for the title, name, bio,
learning objectives, and description — covering Maven's rules on action
verbs, character limits, banned words ("webinar", "FREE", "supercharge"),
pseudonym formatting, credential bloat, and infomercial copy.

The criteria are embedded in the skill itself and sourced from Maven's
help center article *Selection of discoverable and featured Lightning
Lessons*, so the audit works even when that help URL is unreachable.
