# Port Report

## Application services
- 3000 — Next.js server exposed in container and mapped in Compose; see [Dockerfile](../Dockerfile#L58-L66) and [docker-compose.yml](../docker-compose.yml#L1-L14).
- 8080 — diagrams.net/draw.io sidecar mapped in Compose; see [docker-compose.yml](../docker-compose.yml#L1-L8) and referenced for MCP draw.io base URL [packages/mcp-server/README.md](../packages/mcp-server/README.md#L177).
- 6002 — Dev UI URL (docs), Electron dev target, Playwright default base URL when not CI; see [README.md](../README.md#L170-L176), [electron/main/index.ts](../electron/main/index.ts#L44-L63), [playwright.config.ts](../playwright.config.ts#L14-L21).
- 6001 — Playwright base URL when CI=true; see [playwright.config.ts](../playwright.config.ts#L14-L21).
- 61337 — Preferred packaged Electron port (falls back sequentially); see [electron/main/port-manager.ts](../electron/main/port-manager.ts#L9-L59).

## External service defaults (not opened by this app unless you run them)
- 11434 — Ollama default base URL; see [lib/types/model-config.ts](../lib/types/model-config.ts#L103-L114), [env.example](../env.example#L61-L71).
- 8000 — SGLang default base URL; see [lib/types/model-config.ts](../lib/types/model-config.ts#L117-L128), [env.example](../env.example#L74-L83).
- 8080 — Draw.io base URL in offline/deploy docs; see [docs/en/offline-deployment.md](../docs/en/offline-deployment.md#L14-L29) and translations.
