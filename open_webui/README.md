# Open WebUI + MCPO Docker Compose Setup

This directory contains everything needed to run **Open WebUI** alongside the **MCPO** proxy and any configured MCP servers (e.g., Brave Search) in a standalone Docker Compose stack.

## Contents

- **`.env`**: Environment variables (e.g., your API keys).
- **`config.json`**: MCPO configuration declaring all MCP servers to launch.
- **`docker-compose.yml`**: Docker Compose definition for the `open-webui` and `mcpo` services.

## Prerequisites

- Docker & Docker Compose installed on your host.
- Any necessary API keys for each MCP server you plan to use (e.g., `BRAVE_API_KEY` for Brave Search).

## Files

### `.env`

Store your secret keys here. Example:

```bash
BRAVE_API_KEY=<your_brave_api_key>
```

### `.config.json`
Declare your MCP servers in a JSON map. Example minimal config:
```json
{
  "mcpServers": {
    "brave_web_search": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-brave-search"]
    }
  }
}

```
To add more servers, append new entries under `mcpServers`.

### `docker-compose.yml`
Defines two services:
- `open-webui`: Runs the Open WebUI application.
- `mcpo`: Runs the MCPO proxy, reads `config.json`, injects env variables from `.env`

## Setup and Deployments

1. Review and update `.env` and `config.json` as needed.
2. Run `docker-compose up -d` to start the services.
