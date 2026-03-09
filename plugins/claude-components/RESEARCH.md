# claude-components Plugin — Research & Implementation Plan

## Purpose

A plugin that provides skills for correctly creating Claude Code components (skills, agents, hooks, MCP configs, rules). When installed, any implementing agent has the latest, correct formatting info for building these components — whether they live in a `.claude/` folder or inside a plugin.

This is NOT a plugin-building plugin. It's a **component authoring** plugin — focused on getting the structure and content of each component type right, regardless of where it lives.

## Motivation

When agents create components (e.g., an agent `.md` file), they often miss required frontmatter fields or follow incorrect formatting. This plugin ensures the implementing agent has comprehensive, up-to-date guidance for each component type.

## Prior Art

### Official Claude Code `plugin-dev` Plugin

The Anthropic team maintains a `plugin-dev` plugin at `github.com/anthropics/claude-code/tree/main/plugins/plugin-dev` with 7 skills:

1. `skill-development` — Creating skills with progressive disclosure
2. `agent-development` — Creating autonomous agents with frontmatter
3. `command-development` — Creating slash commands
4. `hook-development` — Event-driven automation scripts
5. `mcp-integration` — MCP server configuration
6. `plugin-structure` — Plugin manifest and directory layout
7. `plugin-settings` — `.local.md` configuration patterns

Their skills follow progressive disclosure: lean SKILL.md (1,500–2,000 words) with detailed content in `references/` and working examples in `examples/`.

### Existing ichiba `create-skill` Skill

Located at `.claude/skills/create-skill/` with 9 files:
- `SKILL.md` (68 lines, entry point with routing)
- `constraints.md` — Always/never rules
- `decision-logic.md` — Structure determination flowchart
- `components.md` — Directory and file reference
- `descriptions.md` — Writing effective descriptions
- `templates.md` — 4 skill templates (simple, complex, workflow, complexity-based)
- `error-recovery.md` — Common fixes
- `examples.md` — Complete worked examples
- `_shared/validation.md` — Pre-publish checklist

This will be moved into the plugin as the `create-skill` skill.

---

## Skills to Include (v1.0.0)

### 1. `create-skill` — Skill Authoring

**Source:** Migrate existing `.claude/skills/create-skill/` + incorporate official best practices.

**Key content:**
- SKILL.md frontmatter: `name` (required), `description` (required)
- Description formula: what it does + when to use it + trigger keywords
- Third-person format: "This skill should be used when..."
- Progressive disclosure: metadata → SKILL.md body → nested files
- Directory structure: `SKILL.md`, `_shared/`, `scripts/`, `references/`, `assets/`
- SKILL.md body: ≤500 lines, handle 80% of cases in first 50 lines
- Writing style: imperative form ("Extract X" not "You should extract X")
- Templates for simple, complex, workflow, and tiered skills
- Validation checklist

**Structure:**
```
create-skill/
├── SKILL.md
├── constraints.md
├── decision-logic.md
├── components.md
├── descriptions.md
├── templates.md
├── error-recovery.md
├── examples.md
└── _shared/
    └── validation.md
```

---

### 2. `create-agent` — Agent/Subagent Authoring

**Source:** Official `agent-development` skill adapted for general use.

**Key content — Agent File Format:**

```yaml
---
name: agent-identifier          # Required: lowercase, hyphens, 3-50 chars
description: |                  # Required: triggering conditions + examples
  Use this agent when [conditions]. Examples:

  <example>
  Context: [Situation]
  user: "[Request]"
  assistant: "[Response]"
  <commentary>
  [Why this agent triggers]
  </commentary>
  </example>

model: inherit                  # Required: inherit|sonnet|opus|haiku
color: blue                     # Required: blue|cyan|green|yellow|magenta|red
tools: ["Read", "Write"]       # Optional: restrict to specific tools
---

You are [role description]...

**Your Core Responsibilities:**
1. [Responsibility 1]
2. [Responsibility 2]

**Analysis Process:**
1. [Step 1]
2. [Step 2]

**Output Format:**
[What to return]

**Edge Cases:**
- [Case 1]: [How to handle]
```

**Frontmatter fields:**

| Field | Required | Format | Notes |
|-------|----------|--------|-------|
| `name` | Yes | `lowercase-hyphens-123` | 3-50 chars, alphanumeric start/end |
| `description` | Yes | Text + `<example>` blocks | Most critical field — determines triggering |
| `model` | Yes | `inherit\|sonnet\|opus\|haiku` | Use `inherit` unless specific need |
| `color` | Yes | Color name | `blue\|cyan\|green\|yellow\|magenta\|red` |
| `tools` | No | Array of tool names | Default: all tools. Use least privilege. |
| `disallowedTools` | No | Array of tool names | Alternative to `tools` — blocklist approach |
| `permissionMode` | No | String | Permission handling mode |
| `maxTurns` | No | Number | Limit agent iterations |
| `skills` | No | Array | Skills available to the agent |
| `mcpServers` | No | Object | MCP servers available to agent |
| `hooks` | No | Object | Hooks specific to agent |
| `memory` | No | String | Memory/context instructions |
| `background` | No | Boolean | Run in background |
| `isolation` | No | String | Isolation mode |

**Description best practices:**
- Include 2-4 concrete `<example>` blocks
- Show both proactive and reactive triggering
- Cover different phrasings of same intent
- Explain reasoning in `<commentary>`
- Be specific about when NOT to use

**System prompt best practices:**
- Write in second person ("You are...", "You will...")
- Be specific about responsibilities
- Provide step-by-step process
- Define output format
- Include quality standards
- Address edge cases
- Keep under 10,000 characters
- Target 500-3,000 characters for optimal effectiveness

**Agent location:**
- In a plugin: `plugins/<name>/agents/agent-name.md`
- In a project: `.claude/agents/agent-name.md`
- Auto-discovered from `agents/` directory

**Common tool sets:**
- Read-only analysis: `["Read", "Grep", "Glob"]`
- Code generation: `["Read", "Write", "Grep"]`
- Testing: `["Read", "Bash", "Grep"]`
- Full access: omit `tools` field

**Color guidelines:**
- Blue/cyan: analysis, review
- Green: success-oriented tasks
- Yellow: caution, validation
- Red: critical, security
- Magenta: creative, generation

**Structure:**
```
create-agent/
├── SKILL.md
├── references/
│   ├── frontmatter-fields.md
│   ├── system-prompt-patterns.md
│   └── triggering-examples.md
└── examples/
    ├── simple-agent.md
    └── full-agent.md
```

---

### 3. `create-hook` — Hook Authoring

**Source:** Official `hook-development` skill adapted for general use.

**Key content — Hook Configuration Format:**

Hooks live in `hooks/hooks.json` (plugin) or `.claude/settings.json` (project).

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Validate file write safety...",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Hook types:**

| Type | Use For | Format |
|------|---------|--------|
| `prompt` | Context-aware decisions, flexible evaluation | `{"type": "prompt", "prompt": "...", "timeout": 30}` |
| `command` | Deterministic checks, file ops, external tools | `{"type": "command", "command": "bash script.sh", "timeout": 60}` |

**Available events (14+):**

| Event | Trigger | Decision Output |
|-------|---------|-----------------|
| `PreToolUse` | Before tool execution | `allow\|deny\|ask` |
| `PostToolUse` | After tool completes | continue/suppress |
| `PostToolUseFailure` | After tool fails | continue/suppress |
| `Stop` | Main agent stopping | `approve\|block` |
| `SubagentStop` | Subagent stopping | `approve\|block` |
| `UserPromptSubmit` | User submits prompt | continue/suppress |
| `SessionStart` | Session begins | log/context |
| `SessionEnd` | Session ends | cleanup |
| `PreCompact` | Before compaction | add info |
| `Notification` | Claude sends notification | react |
| `PermissionRequest` | Permission needed | decide |
| `SubagentStart` | Subagent launches | configure |
| `InstructionsLoaded` | Instructions parsed | modify |
| `ConfigChange` | Config changes | react |

**Matcher patterns:**
- Exact: `"Write"`
- Multiple: `"Read|Write|Edit"`
- Wildcard: `"*"`
- Regex: `"mcp__.*__delete.*"`
- Case-sensitive

**Hook input (JSON via stdin):**
```json
{
  "session_id": "abc123",
  "transcript_path": "/path/to/transcript.txt",
  "cwd": "/current/working/dir",
  "hook_event_name": "PreToolUse",
  "tool_name": "Write",
  "tool_input": { "file_path": "..." }
}
```

**Hook output:**
```json
{
  "continue": true,
  "suppressOutput": false,
  "systemMessage": "Message for Claude",
  "hookSpecificOutput": {
    "permissionDecision": "allow|deny|ask"
  }
}
```

**Exit codes:**
- `0` — Success (stdout shown in transcript)
- `2` — Blocking error (stderr fed back to Claude)
- Other — Non-blocking error

**Environment variables:**
- `$CLAUDE_PROJECT_DIR` — Project root
- `$CLAUDE_PLUGIN_ROOT` — Plugin directory (use for portability)
- `$CLAUDE_ENV_FILE` — SessionStart only: persist env vars

**Best practices:**
- Prefer prompt hooks for complex/context-aware decisions
- Use command hooks for fast deterministic checks
- Always validate inputs in command hooks
- Always quote variables in bash (`"$var"` not `$var`)
- Use `${CLAUDE_PLUGIN_ROOT}` for portable paths
- Set appropriate timeouts
- Test hooks independently before deploying

**Hook location:**
- In a plugin: `plugins/<name>/hooks/hooks.json`
- In a project: `.claude/settings.json` under `"hooks"` key

**Structure:**
```
create-hook/
├── SKILL.md
├── references/
│   ├── events-reference.md
│   ├── input-output-format.md
│   └── security-patterns.md
└── examples/
    ├── pretooluse-validation.json
    ├── stop-verification.json
    └── session-start-context.json
```

---

### 4. `create-mcp` — MCP Server Configuration

**Source:** Official `mcp-integration` skill adapted for general use.

**Key content — MCP Configuration:**

MCP configs live in `.mcp.json` (plugin root or project root) or inline in `plugin.json`.

**Server types:**

| Type | Use Case | Auth |
|------|----------|------|
| `stdio` | Local tools, custom servers | Environment vars |
| `sse` | Cloud services (Asana, GitHub) | OAuth (automatic) |
| `http` | REST APIs | Tokens, headers |
| `ws` | Real-time bidirectional | Tokens, headers |

**stdio example:**
```json
{
  "filesystem": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-filesystem", "/allowed/path"],
    "env": { "LOG_LEVEL": "debug" }
  }
}
```

**SSE example:**
```json
{
  "asana": {
    "type": "sse",
    "url": "https://mcp.asana.com/sse"
  }
}
```

**HTTP example:**
```json
{
  "api-service": {
    "type": "http",
    "url": "https://api.example.com/mcp",
    "headers": {
      "Authorization": "Bearer ${API_TOKEN}"
    }
  }
}
```

**WebSocket example:**
```json
{
  "realtime": {
    "type": "ws",
    "url": "wss://mcp.example.com/ws",
    "headers": { "Authorization": "Bearer ${TOKEN}" }
  }
}
```

**Tool naming convention:**
`mcp__plugin_<plugin-name>_<server-name>__<tool-name>`

**Environment variable expansion:**
- `${CLAUDE_PLUGIN_ROOT}` — Plugin directory (always use for portability)
- `${VAR_NAME}` — Any user environment variable

**Security best practices:**
- Always use HTTPS/WSS
- Use environment variables for tokens (never hardcode)
- Pre-allow specific tools, not wildcards
- Document required env vars in README

**MCP location:**
- In a plugin: `plugins/<name>/.mcp.json` or inline in `plugin.json`
- In a project: `.mcp.json` at project root

**Structure:**
```
create-mcp/
├── SKILL.md
├── references/
│   ├── server-types.md
│   ├── authentication.md
│   └── tool-naming.md
└── examples/
    ├── stdio-server.json
    ├── sse-server.json
    └── http-server.json
```

---

### 5. `create-rules` — Rules & CLAUDE.md Authoring

**Source:** Official docs + best practices research. (Not in official plugin-dev.)

**Key content — Rules System:**

Rules provide persistent context and instructions to Claude Code sessions.

**Rule types and locations:**

| Type | Location | Scope | Loaded |
|------|----------|-------|--------|
| Global CLAUDE.md | `~/.claude/CLAUDE.md` | All sessions | Always |
| Project CLAUDE.md | `./CLAUDE.md` | This project | Always |
| Local CLAUDE.md | `./CLAUDE.local.md` | This project (gitignored) | Always |
| Parent CLAUDE.md | `../CLAUDE.md` | Monorepo parent | Always |
| Child CLAUDE.md | `./subdir/CLAUDE.md` | On demand | When working in subdir |
| Rules directory | `.claude/rules/*.md` | This project | Always (all files) |
| User rules | `~/.claude/rules/*.md` | All sessions | Always |

**CLAUDE.md format:**
```markdown
# Code style
- Use ES modules (import/export), not CommonJS (require)
- Destructure imports when possible

# Workflow
- Typecheck after making code changes
- Prefer running single tests over the whole suite

# Testing
- Use vitest for unit tests
- Always run `npm test -- --run path/to/test` after changes
```

No required format — keep it short and human-readable.

**Rules directory format (`.claude/rules/`):**
```markdown
---
paths:
  - src/auth/**/*
  - src/payments/**/*
---
# Security-Critical Code Rules

- All auth changes require security review
- Never log sensitive data
- Use parameterized queries only
```

**Rules frontmatter fields:**

| Field | Required | Format | Notes |
|-------|----------|--------|-------|
| `paths` | No | Array of glob patterns | Target specific files/dirs. If omitted, applies everywhere. |

**`@import` syntax in CLAUDE.md:**
```markdown
See @README.md for project overview.
See @docs/api-guide.md for API conventions.
```

**What to include:**
- Bash commands Claude can't guess
- Code style rules that differ from defaults
- Testing instructions and preferred test runners
- Repository etiquette (branch naming, PR conventions)
- Architectural decisions specific to your project
- Developer environment quirks (required env vars)
- Common gotchas or non-obvious behaviors

**What NOT to include:**
- Anything Claude can figure out by reading code
- Standard language conventions Claude already knows
- Detailed API documentation (link to docs instead)
- Information that changes frequently
- Long explanations or tutorials
- File-by-file descriptions of the codebase
- Self-evident practices like "write clean code"

**Best practices:**
- Target under 200 lines per CLAUDE.md file
- For each line, ask: "Would removing this cause Claude to make mistakes?"
- Use emphasis for critical rules: "IMPORTANT" or "YOU MUST"
- Check into git so your team can contribute
- Use `.claude/rules/` for path-targeted rules (saves context tokens)
- Use `CLAUDE.local.md` for personal/gitignored rules
- Prune regularly — review when Claude makes mistakes
- Use hooks instead of rules for actions that must happen every time

**Rules location:**
- Project: `./CLAUDE.md`, `.claude/rules/*.md`
- Personal: `~/.claude/CLAUDE.md`, `~/.claude/rules/*.md`
- Monorepo: `parent/CLAUDE.md` + `parent/child/CLAUDE.md`

**Structure:**
```
create-rules/
├── SKILL.md
├── references/
│   ├── locations-and-loading.md
│   ├── path-targeting.md
│   └── writing-guidelines.md
└── examples/
    ├── project-claude-md.md
    ├── path-targeted-rule.md
    └── monorepo-layout.md
```

---

## Plugin Structure

```
plugins/claude-components/
├── .claude-plugin/
│   └── plugin.json
├── skills/
│   ├── create-skill/
│   │   ├── SKILL.md
│   │   ├── constraints.md
│   │   ├── decision-logic.md
│   │   ├── components.md
│   │   ├── descriptions.md
│   │   ├── templates.md
│   │   ├── error-recovery.md
│   │   ├── examples.md
│   │   └── _shared/
│   │       └── validation.md
│   ├── create-agent/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── frontmatter-fields.md
│   │   │   ├── system-prompt-patterns.md
│   │   │   └── triggering-examples.md
│   │   └── examples/
│   │       ├── simple-agent.md
│   │       └── full-agent.md
│   ├── create-hook/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── events-reference.md
│   │   │   ├── input-output-format.md
│   │   │   └── security-patterns.md
│   │   └── examples/
│   │       ├── pretooluse-validation.json
│   │       ├── stop-verification.json
│   │       └── session-start-context.json
│   ├── create-mcp/
│   │   ├── SKILL.md
│   │   ├── references/
│   │   │   ├── server-types.md
│   │   │   ├── authentication.md
│   │   │   └── tool-naming.md
│   │   └── examples/
│   │       ├── stdio-server.json
│   │       ├── sse-server.json
│   │       └── http-server.json
│   └── create-rules/
│       ├── SKILL.md
│       ├── references/
│       │   ├── locations-and-loading.md
│       │   ├── path-targeting.md
│       │   └── writing-guidelines.md
│       └── examples/
│           ├── project-claude-md.md
│           ├── path-targeted-rule.md
│           └── monorepo-layout.md
└── README.md
```

## Plugin Manifest

```json
{
  "name": "claude-components",
  "version": "1.0.0",
  "description": "Skills for correctly creating Claude Code components: skills, agents, hooks, MCP configs, and rules",
  "author": "nickmeehan",
  "components": {
    "commands": [],
    "agents": [],
    "skills": ["create-skill", "create-agent", "create-hook", "create-mcp", "create-rules"],
    "hooks": false,
    "mcp": false
  }
}
```

## Marketplace Entry

```json
{
  "name": "claude-components",
  "version": "1.0.0",
  "description": "Skills for correctly creating Claude Code components: skills, agents, hooks, MCP configs, and rules",
  "path": "plugins/claude-components"
}
```

## Migration Plan

1. Move `.claude/skills/create-skill/` → `plugins/claude-components/skills/create-skill/`
2. Update the `create-skill` SKILL.md description to use third-person format
3. Incorporate official best practices (writing style, progressive disclosure guidance)
4. Keep the existing multi-file structure (constraints, decision-logic, templates, etc.)

## Implementation Order

1. **Scaffold plugin** — Create directory structure and plugin.json
2. **Migrate create-skill** — Move and enhance existing skill
3. **Build create-agent** — Highest impact (the original motivation)
4. **Build create-hook** — Second most complex component type
5. **Build create-rules** — Simple but important (unique to this plugin, not in official plugin-dev)
6. **Build create-mcp** — Most specialized, likely least frequently used
7. **Update marketplace.json** — Add plugin entry
8. **Test all skills** — Verify triggering and content quality

## Version Strategy

- v1.0.0: All 5 skills complete
- Patch bumps for content fixes and wording improvements
- Minor bumps for new skills (e.g., `create-command`, `create-lsp`)
- Both `plugin.json` and `marketplace.json` versions must stay in sync per CLAUDE.md rules

## Key Differences from Official `plugin-dev`

| Aspect | Official `plugin-dev` | Our `claude-components` |
|--------|----------------------|------------------------|
| Focus | Plugin development workflow | Component authoring correctness |
| Audience | Plugin authors | Any agent creating components |
| Scope | Plugin-specific (plugin.json, structure) | Any `.claude/` or plugin component |
| Includes rules | No | Yes |
| Includes plugin-settings | Yes | No (not a component type) |
| Includes plugin-structure | Yes | No (not the focus) |
| Includes command-development | Yes | No (legacy, low priority) |

## Sources

- [Claude Code Repository — Plugins](https://github.com/anthropics/claude-code/tree/main/plugins)
- [Claude Code Plugin-Dev Skills](https://github.com/anthropics/claude-code/tree/main/plugins/plugin-dev/skills)
- [Anthropic Skills Repository](https://github.com/anthropics/skills)
- [Claude Code Best Practices](https://code.claude.com/docs/en/best-practices)
- [Claude Code Skills Documentation](https://code.claude.com/docs/en/skills)
- [Claude Code Subagents Documentation](https://code.claude.com/docs/en/sub-agents)
- [Claude Code Hooks Guide](https://code.claude.com/docs/en/hooks-guide)
