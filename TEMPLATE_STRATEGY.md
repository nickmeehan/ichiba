# Marketplace Template Strategy

This document describes how to convert a copy of this repository into a reusable GitHub Template Repository that anyone can use to create their own Claude Code plugin marketplace.

## Overview

This repo has already been copied to `ichiba-template`. Apply the generalizations described below, then enable "Template repository" in GitHub Settings > General.

## File-by-File Changes

### 1. `.claude-plugin/marketplace.json`

Replace the current ichiba-specific manifest with generic placeholders:

```json
{
  "name": "my-marketplace",
  "description": "A Claude Code plugin marketplace for sharing and distributing plugins",
  "version": "1.0.0",
  "author": "your-name-or-org",
  "repository": "your-org/your-marketplace",
  "plugins": []
}
```

### 2. `README.md`

Rewrite entirely. The new README should serve as a "getting started with your new marketplace" guide:

- **Title**: "Claude Code Plugin Marketplace Template"
- **Intro**: Explain this is a template for creating your own Claude Code plugin marketplace
- **Quick Start section**:
  1. Click "Use this template" on GitHub
  2. Name your new repository
  3. Update `marketplace.json` with your name, org, and description
  4. Start creating plugins with `/new-plugin`
- **What's Included section**: List the built-in tooling:
  - Plugin generator script (`bin/generate-plugin.sh`)
  - `/new-plugin` command for scaffolding plugins
  - Skill authoring guide (`.claude/skills/create-skill/`)
  - Contributing guide template
- **Repository Structure section**: Same tree diagram but with generic names
- **Customization Checklist**: A checklist of things to update after cloning:
  - [ ] Update `marketplace.json` with your name and repo
  - [ ] Update `README.md` for your marketplace
  - [ ] Update default author in `bin/generate-plugin.sh`
  - [ ] Update `CONTRIBUTING.md` for your contribution policy
  - [ ] Update or replace the LICENSE
  - [ ] Delete this checklist once done
- **For Teams section**: Keep the existing value proposition content (reduce duplication, spread best practices, etc.)
- **Links**: Link to Anthropic plugin marketplace docs

### 3. `CONTRIBUTING.md`

Generalize to be a reusable contribution guide template:

- Remove the "Status: Not Accepting Contributions Yet" section entirely
- Remove references to "this marketplace" being ichiba
- Keep all the reference material (plugin structure, manifest examples, commit guidelines, best practices) — it's all generic and useful
- Change "Open an issue in this repository" to generic language
- Add a note at the top: "This is a template contribution guide. Customize it for your marketplace."
- In Option 1 (Using Anthropic's Plugin-Dev Toolkit), line 42 references `ichiba` — change `mv ~/.config/claude/plugins/your-plugin-name /path/to/ichiba/plugins/` to `mv ~/.config/claude/plugins/your-plugin-name /path/to/your-marketplace/plugins/`
- Remove or generalize the "Future License" section at the bottom

### 4. `bin/generate-plugin.sh`

Two specific changes:

- **Line 72** (in `generate_readme` function): Change the install example from:
  ```
  /plugin install $name@nickmeehan/ichiba
  ```
  to:
  ```
  /plugin install $name@YOUR-ORG/YOUR-MARKETPLACE
  ```
  Add a comment noting users should update this after cloning the template.

- **Line 366** (in `main` function): Change the default author from:
  ```bash
  DEFAULT_AUTHOR="nickmeehan"
  ```
  to:
  ```bash
  DEFAULT_AUTHOR=""
  ```
  And update the prompt to not show a default:
  ```bash
  read -p "Enter author name: " PLUGIN_AUTHOR
  if [ -z "$PLUGIN_AUTHOR" ]; then
      print_error "Author name is required"
      exit 1
  fi
  ```

### 5. `.claude/commands/new-plugin.md`

Review for any ichiba-specific references. If it calls `bin/generate-plugin.sh`, the script changes above should be sufficient. But verify there are no hardcoded marketplace names in the command prompt itself.

### 6. `.claude/skills/new-plugin-skill/`

Review for any ichiba-specific references in the skill's SKILL.md or supporting files. Generalize any marketplace-specific language.

### 7. `.claude/skills/create-skill/`

This skill is a general-purpose skill authoring guide — likely needs no changes. Verify there are no ichiba-specific references.

### 8. `LICENSE` and `NOTICE`

Decision point: The current license is Apache 2.0 + Commons Clause. For a template, consider:

- **Option A**: Keep the same license (users can change it after cloning)
- **Option B**: Use MIT for the template itself (more permissive, lower friction for adoption)
- **Recommendation**: Keep as-is but add a note in the README that users should choose their own license. The template's license covers the template infrastructure, not the plugins users create.

### 9. Delete `TEMPLATE_STRATEGY.md`

This file (the one you're reading) should be deleted from the template repo after all changes are applied — it's only needed as an implementation guide.

## Post-Setup: GitHub Configuration

After all file changes are applied:

1. Go to the new repo's **Settings > General**
2. Check **"Template repository"**
3. Optionally add **Topics**: `claude-code`, `plugin-marketplace`, `template`
4. Update the repo **Description**: "Template for creating your own Claude Code plugin marketplace"

## How Users Will Use the Template

1. Visit the template repo on GitHub
2. Click the green **"Use this template"** button → **"Create a new repository"**
3. Name their repo (e.g., `my-company/dev-plugins`)
4. Clone their new repo locally
5. Follow the "Customization Checklist" in the README
6. Start creating plugins with `/new-plugin`

## Notes

- The template should feel immediately usable — someone should be able to clone it and create their first plugin within minutes
- All placeholder values should be obviously placeholders (e.g., `your-org`, `YOUR-MARKETPLACE`) so they're easy to find-and-replace
- The plugin generator and skills are the real value — they work out of the box regardless of marketplace name
