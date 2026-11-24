# Kashkool MCP Stack

Complete Model Context Protocol server stack for Kashkool project.

## Installed Servers (14 total)

| Server | Package | Status | Needs API Key |
|--------|---------|--------|---------------|
| Zenrows | `@zenrows/mcp` | ✅ Working | Auto-creates free account |
| Playwright | `@playwright/mcp` | ✅ Working | No |
| Puppeteer | `puppeteer-mcp-server` | ⚠️ Deprecated puppeteer | No |
| Firecrawl | `firecrawl-mcp` | ✅ Working | Optional (keyless mode works) |
| Apify | `@apify/actors-mcp-server` | ✅ Working | Yes (`APIFY_TOKEN`) |
| Jina Reader | `jina-reader-mcp-server` | ✅ Working | Yes (`JINA_API_KEY`) |
| Filesystem | `@modelcontextprotocol/server-filesystem` | ✅ Working | No |
| GitHub | `@beautyfree/modelcontextprotocol-server-github` | ✅ Working | Yes (`GITHUB_PERSONAL_ACCESS_TOKEN`) |
| YouTube Transcript | `@fabriqa.ai/youtube-transcript-mcp` | ✅ Working | No |
| Sequential Thinking | `@modelcontextprotocol/server-sequential-thinking` | ✅ Working | No |
| Everything | `@modelcontextprotocol/server-everything` | ✅ Working | No |
| PDF | `@modelcontextprotocol/server-pdf` | ⚠️ Port conflict (3001) | No |
| String | `@usestring/mcp` | ✅ Working | Yes (`STRING_API_KEY`) |
| Fetch | `mcp-fetch-server` | ✅ Working | No |
| Inspector | `@modelcontextprotocol/inspector` | ✅ Working | No |

## Quick Start

```bash
cd N:\spaceship-ai\projects\kashkool\mcp-stack

# Test individual servers
cmd /c "N:\spaceship-ai\tools\node-v26.13.1-win-x64\npx.cmd -y @zenrows/mcp --version"
cmd /c "N:\spaceship-ai\tools\node-v26.13.1-win-x64\npx.cmd -y @playwright/mcp --version"
# ... etc

# Use with MCP client (Claude Desktop, Cursor, etc.)
# Copy mcp-config.json to your client config
```

## Configuration

Edit `mcp-config.json` and add your API keys:

```json
{
  "mcpServers": {
    "firecrawl": {
      "env": { "FIRECRAWL_API_KEY": "your-key" }
    },
    "apify": {
      "env": { "APIFY_TOKEN": "your-token" }
    },
    "jina": {
      "env": { "JINA_API_KEY": "your-key" }
    },
    "github": {
      "env": { "GITHUB_PERSONAL_ACCESS_TOKEN": "your-token" }
    },
    "string": {
      "env": { "STRING_API_KEY": "your-key" }
    }
  }
}
```

## Notes

- **Zenrows**: Auto-creates free account on first run
- **Firecrawl**: Works in keyless mode (rate-limited)
- **PDF Server**: Uses port 3001 - change if conflict
- **Inspector**: Run with `npx @modelcontextprotocol/inspector` for debugging
- All servers use `stdio` transport by default

## Paths

- Project: `N:\spaceship-ai\projects\kashkool\mcp-stack`
- Node: `N:\spaceship-ai\tools\node-v26.13.1-win-x64\node.exe`
- NPX: `N:\spaceship-ai\tools\node-v26.13.1-win-x64\npx.cmd`
- Config: `N:\spaceship-ai\projects\kashkool\mcp-stack\mcp-config.json`