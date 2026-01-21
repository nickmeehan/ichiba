# Ichiba - Claude Code Plugin Marketplace

Welcome to the Ichiba plugin marketplace! This is a public repository for sharing useful Claude Code plugins including commands, agents, skills, hooks, and MCP servers.

## What is Ichiba?

Ichiba (市場, Japanese for "marketplace") is a public plugin marketplace for Claude Code. The goals are:

- **Share useful plugins** for development workflows and productivity
- **Help people learn** by providing examples of well-structured plugins
- **Demonstrate patterns** that teams can adopt internally for their own conventions and best practices

This marketplace shows how organizations can build internal plugin ecosystems where everyone benefits from continuously improving tooling and shared best practices.

## Getting Started

### Install the Marketplace

Add this marketplace to your Claude Code:

```bash
/plugin marketplace add nickmeehan/ichiba
```

### Browse Available Plugins

See what's available:

```bash
/plugin
```

### Install a Plugin

```bash
/plugin install <plugin-name>@nickmeehan/ichiba
```

## Available Plugins

Currently, this marketplace is in its early stages. Check back soon for plugins!

## Contributing

We welcome contributions! If you've created a useful Claude Code plugin, please consider sharing it here.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for details on how to add your plugin to the marketplace.

## Repository Structure

```
ichiba/
├── .claude-plugin/
│   └── marketplace.json       # Marketplace manifest
├── plugins/
│   └── (plugin subdirectories)
├── CONTRIBUTING.md
└── README.md
```

## For Teams

This marketplace is a working example of how teams can build their own internal plugin marketplaces. Key benefits:

- **Reduce duplication** - Share solutions across teams instead of reinventing them
- **Spread best practices** - Codify conventions in plugins everyone can use
- **Continuous improvement** - Tooling gets better as people contribute enhancements
- **Low friction adoption** - Easy for team members to discover and install useful tools

See the [internal marketplace documentation](https://docs.anthropic.com/en/docs/claude-code/plugin-marketplaces) for guidance on setting up your own.

## Questions or Issues?

If you have questions or run into issues, please open an issue in this repository.

## License

Apache 2.0 with Commons Clause - Free to use and modify (including commercially), but you can't sell the files themselves. See [LICENSE](./LICENSE) and [NOTICE](./NOTICE) for details.
