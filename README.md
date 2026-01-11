# Ichiba - Internal Claude Code Plugin Marketplace

Welcome to the Ichiba plugin marketplace! This repository enables teams to share Claude Code customizations including commands, agents, skills, hooks, and MCP servers.

## What is Ichiba?

Ichiba (市場, Japanese for "marketplace") is our internal plugin marketplace for Claude Code. It helps reduce duplication of effort across teams by providing a central place to discover and share useful Claude Code plugins.

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

## Questions or Issues?

If you have questions or run into issues, please open an issue in this repository.

## License

Internal use only - nickmeehan organization.
