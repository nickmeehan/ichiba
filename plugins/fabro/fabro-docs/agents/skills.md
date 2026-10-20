> ## Documentation Index
> Fetch the complete documentation index at: https://docs.fabro.sh/llms.txt
> Use this file to discover all available pages before exploring further.

# Skills

> Reusable prompt templates that extend agent capabilities

Skills are reusable prompt templates that give agents structured instructions for common tasks -- code review, committing, test writing, refactoring, and more. They are discovered automatically from convention directories, listed in the agent's system prompt, and can be invoked either by the user (with `/skill-name` syntax) or by the agent itself (via the `use_skill` tool).

Fabro implements the open [Agent Skills](https://agentskills.io/home) format. Each skill is a directory containing a `SKILL.md` file with YAML frontmatter and Markdown instructions. See the [Agent Skills specification](https://agentskills.io/specification) for the full file format, and [What are skills?](https://agentskills.io/what-are-skills) for an introduction.

## Discovery

Fabro discovers skills from three convention directories, searched in order:

| Directory | Scope |
| - | - |
| `~/.fabro/skills/` | Global -- applies to all projects |
| `{git_root}/.fabro/skills/` | Project -- checked into the repo |
| `{git_root}/skills/` | Project (alternate location) |

Within each directory, Fabro looks for `*/SKILL.md` files (one level of nesting).

When the same skill name appears in multiple directories, **later directories override earlier ones**. This means project-level skills take precedence over global skills, letting you customize behavior per-repo.

<Note>
  You can override the default directories by setting `skill_dirs` in the session configuration. When set, only the specified directories are searched.
</Note>

## Invocation

Skills can be invoked in two ways.

### Slash syntax (user input)

On the native agent backend, start authored input with `/skill-name` to invoke a skill:

```
/commit fix the off-by-one error in pagination
```

Fabro detects the leading `/commit` command, finds the matching skill, and expands the authored input using its template. The remaining text (`fix the off-by-one error in pagination`) is substituted into the `{{user_input}}` placeholder. A template without that placeholder replaces the authored input.

Rules for slash syntax:

* The command must be at the start of authored input, after any leading whitespace
* The skill name must be followed by whitespace or end of input
* Later slash tokens are ordinary arguments or text: `/commit mention /review` invokes only `commit`, while `Please run /commit` invokes no skill
* File paths like `/usr/bin/bash` are not matched (the character after `/` must be a lowercase letter, and the name cannot contain `/`)

For native workflow agent stages, only the authored node prompt is expanded. Workflow preambles, prior-stage context, `for_each` item data, and output contracts remain outside expansion and are preserved even when the template has no `{{user_input}}` placeholder. For example, prior-stage text mentioning `/tmp` or `/commit` stays literal.

User-delivered follow-ups also support a leading command. Generated output-repair turns bypass expansion. ACP agents receive the assembled workflow input and own any command interpretation; one-shot prompt nodes do not expand skills.

### use\_skill tool (agent-initiated)

When skills are available, Fabro adds a `use_skill` tool to the agent's toolset and lists the available skills in the system prompt:

```
# Available Skills
When the user's request matches a skill below, call the `use_skill` tool
to load its instructions, then follow them.
- `commit`: Create a git commit following best practices
- `review`: Review code changes for issues and improvements
```

The agent can call `use_skill` with a skill name to load the template, then follow the instructions:

| Parameter | Type | Required | Description |
| - | - | - | - |
| `skill_name` | string | yes | Name of the skill to load (without the `/` prefix) |

Returns the skill's template text.

## Lifecycle

1. **Discovery** -- On session startup, Fabro scans the skill directories and parses all valid `SKILL.md` files
2. **Registration** -- If any skills are found, the `use_skill` tool is registered and the skill list is added to the system prompt
3. **Expansion** -- On the native agent backend, a leading `/skill-name` command in authored input is expanded before sending to the LLM. Leading whitespace is allowed; later slash tokens stay literal. Workflow context and output requirements remain outside expansion, and generated output-repair turns bypass it
4. **Tool use** -- The agent can also call `use_skill` at any time to load a skill's template mid-conversation


This documentation is built and hosted on [Mintlify](https://mintlify.com), a developer documentation platform.