# MCP (Model Context Protocol) Configuration

MCP servers provide external tools and resources to Claude Code.

## Setup

1. Rename `.mcp.json.example` to `.mcp.json`
2. Configure your MCP server(s)
3. Update plugin.json to set "mcp": true

## Example Servers

Popular MCP servers include:
- `@modelcontextprotocol/server-filesystem` - File system access
- `@modelcontextprotocol/server-github` - GitHub integration
- `@modelcontextprotocol/server-postgres` - PostgreSQL access
- Custom servers built for your specific needs

## Remove This

Remove this file and .mcp.json.example once you've set up your MCP configuration.
