# Ollama + Docker Setup Guide

This guide explains how to configure Next AI Draw.io to work with local LLM instances using Docker.

## Supported Local LLM Providers

- **Ollama** - Local model management (port 11434)
- **LM Studio** - OpenAI-compatible local API (port 14321 in this example)

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Your Host                             │
│  ┌─────────────────┐  ┌─────────────────┐                   │
│  │  Ollama         │  │  LM Studio      │                   │
│  │  localhost:11434│  │  localhost:14321│                   │
│  │                 │  │  (OpenAI API)   │                   │
│  │  - gpt-oss:20b  │  │  - local-model  │                   │
│  │  - etc.         │  │                 │                   │
│  └────────┬────────┘  └────────┬────────┘                   │
│           │                    │                            │
│           └──────┬─────────────┘                            │
│                  │                                          │
│  ┌───────────────▼─────────────────────────────────────┐   │
│  │  Docker Compose Network                             │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │ next-ai-draw-io                             │   │   │
│  │  │  (port 3201)                                │   │   │
│  │  │                                             │   │   │
│  │  │  host.docker.internal:11434  → Ollama      │   │   │
│  │  │  host.docker.internal:14321  → LM Studio   │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  │  ┌─────────────────────────────────────────────┐   │   │
│  │  │ drawio                                      │   │   │
│  │  │  (port 8231)                                │   │   │
│  │  └─────────────────────────────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Prerequisites

### Option A: Ollama
```bash
# Install Ollama: https://ollama.com/download

# Start Ollama service
ollama serve

# Pull models
ollama pull llama3.2
ollama pull qwen2.5
```

### Option B: LM Studio
1. Download LM Studio: https://lmstudio.ai/
2. Start LM Studio
3. Load a model (e.g., Qwen, Llama, etc.)
4. Start the **Local Inference Server**
5. Set port to `14321` (or your preferred port)
6. Enable **CORS** (required for browser access)

Verify LM Studio is running:
```bash
curl http://localhost:14321/v1/models
# Should list your loaded model
```

## Configuration Files

### 1. ai-models.json (Multi-Model Configuration)

```json
{
  "providers": [
    {
      "name": "Ollama Local",
      "provider": "ollama",
      "models": [
        "gpt-oss:20b",
        "qwen2.5",
        "mistral"
      ],
      "default": true
    },
    {
      "name": "LM Studio",
      "provider": "openai",
      "models": [
        "local-model"
      ],
      "baseUrlEnv": "LMSTUDIO_BASE_URL"
    }
  ]
}
```

**Provider Types:**
- `"ollama"` - Uses Ollama provider (no API key)
- `"openai"` - OpenAI-compatible API (for LM Studio, etc.)

### 2. .env (Environment Variables)

```bash
# Default provider (Ollama)
AI_PROVIDER=ollama
AI_MODEL=gpt-oss:20b

# Ollama configuration
OLLAMA_BASE_URL=http://host.docker.internal:11434
OLLAMA_ENABLE_THINKING=true

# LM Studio configuration (OpenAI-compatible)
LMSTUDIO_BASE_URL=http://host.docker.internal:14321/v1
# No API key needed for LM Studio

# Security - MUST be true for local LLMs
ALLOW_PRIVATE_URLS=true

# Multi-model config
AI_MODELS_CONFIG_PATH=/app/ai-models.json
```

### 3. docker-compose.yml (Docker Networking)

```yaml
services:
  next-ai-draw-io:
    environment:
      # Ollama
      OLLAMA_BASE_URL: http://host.docker.internal:11434
      # LM Studio
      LMSTUDIO_BASE_URL: http://host.docker.internal:14321/v1
      # Security
      ALLOW_PRIVATE_URLS: "true"
    extra_hosts:
      - "host.docker.internal:host-gateway"
```

## Starting the Services

### 1. Start Your Local LLM Server(s)

**Ollama:**
```bash
ollama serve
```

**LM Studio:**
- Open LM Studio app
- Load a model
- Click **Start Server** (port 14321)
- Enable **CORS**

### 2. Start the Docker Containers

```bash
# Stop any existing containers
docker-compose down

# Build and start
docker-compose up -d --build

# Check logs
docker-compose logs -f next-ai-draw-io
```

### 3. Verify Setup

```bash
# Test Ollama from container
docker-compose exec next-ai-draw-io sh -c "curl -s http://host.docker.internal:11434/api/tags"

# Test LM Studio from container
docker-compose exec next-ai-draw-io sh -c "curl -s http://host.docker.internal:14321/v1/models"
```

## Accessing the Application

- **Next AI Draw.io**: http://localhost:3201
- **Draw.io (self-hosted)**: http://localhost:8231
- **Ollama API**: http://localhost:11434
- **LM Studio API**: http://localhost:14321

## Selecting Models in UI

1. Click **Settings** (gear icon) in chat panel
2. Click **API Keys & Models**
3. Select from available providers:

| Provider | Models | Best For |
|----------|--------|----------|
| **Ollama Local** | gpt-oss:20b, qwen2.5, mistral | Fast local inference |
| **LM Studio** | local-model | Full model control, GPU offloading |

## LM Studio Specific Configuration

### Changing the Port

If you use a different port for LM Studio (default is 1234):

1. **Update `.env`:**
```bash
LMSTUDIO_BASE_URL=http://host.docker.internal:1234/v1
```

2. **Update `docker-compose.yml`:**
```yaml
environment:
  LMSTUDIO_BASE_URL: http://host.docker.internal:1234/v1
```

3. **Restart containers:**
```bash
docker-compose down
docker-compose up -d
```

### Model Name in LM Studio

LM Studio uses `local-model` as the model name by default. If you've configured a custom model name in LM Studio, update `ai-models.json`:

```json
{
  "name": "LM Studio",
  "provider": "openai",
  "models": ["your-custom-model-name"],
  "baseUrlEnv": "LMSTUDIO_BASE_URL"
}
```

### Adding API Key (Optional)

If you enable API key in LM Studio:

1. **Set key in LM Studio** (Settings → API Key)
2. **Update `.env`:**
```bash
LMSTUDIO_API_KEY=your-lmstudio-key
```
3. **Update `ai-models.json`:**
```json
{
  "name": "LM Studio",
  "provider": "openai",
  "models": ["local-model"],
  "baseUrlEnv": "LMSTUDIO_BASE_URL",
  "apiKeyEnv": "LMSTUDIO_API_KEY"
}
```

## Troubleshooting

### Issue: "Cannot connect to LM Studio"

**Symptoms**: Model validation fails for LM Studio provider

**Solutions:**

1. **Check LM Studio is running:**
   ```bash
   curl http://localhost:14321/v1/models
   ```

2. **Verify CORS is enabled** in LM Studio:
   - Settings → Developer → Enable CORS

3. **Check Docker can reach LM Studio:**
   ```bash
   docker-compose exec next-ai-draw-io sh -c "curl -v http://host.docker.internal:14321/v1/models"
   ```

4. **Firewall issues** (Windows):
   - Allow LM Studio through Windows Defender Firewall
   - Or temporarily disable firewall for testing

### Issue: "Model not found" for LM Studio

**Cause**: Wrong model name

**Fix**: LM Studio uses `local-model` by default. Check in LM Studio:
- Developer tab → Model ID
- Or use the API: `curl http://localhost:14321/v1/models`

### Issue: "API key is required" for LM Studio

**Cause**: LM Studio configured to require API key

**Fix**: Either:
- Disable API key in LM Studio (Settings → API Key → Off)
- Or configure API key (see "Adding API Key" section above)

### Issue: "Cannot connect to Ollama"

See [Ollama troubleshooting](#issue-cannot-connect-to-ollama) in previous sections.

## Comparing Ollama vs LM Studio

| Feature | Ollama | LM Studio |
|---------|--------|-----------|
| **Installation** | CLI / Docker | Desktop App |
| **Model Management** | CLI (`ollama pull`) | GUI download |
| **GPU Support** | Automatic | Configurable |
| **Context Length** | Default | Configurable |
| **API Format** | Ollama native | OpenAI-compatible |
| **Multi-model** | Single model | Quick switch |
| **Best For** | Simplicity, scripting | Control, experimentation |

## Advanced: Multiple LM Studio Instances

You can configure multiple LM Studio instances with different models:

```json
{
  "providers": [
    {
      "name": "LM Studio - Coding",
      "provider": "openai",
      "models": ["qwen-coder"],
      "baseUrlEnv": "LMSTUDIO_CODER_URL"
    },
    {
      "name": "LM Studio - General",
      "provider": "openai",
      "models": ["llama-general"],
      "baseUrlEnv": "LMSTUDIO_GENERAL_URL"
    }
  ]
}
```

```bash
# .env
LMSTUDIO_CODER_URL=http://host.docker.internal:14321/v1
LMSTUDIO_GENERAL_URL=http://host.docker.internal:14322/v1
```

Run two LM Studio instances on different ports.

## Next Steps

1. Test both providers with: "Draw a simple flowchart"
2. Compare response quality between Ollama and LM Studio
3. Configure additional models as needed

See [AI Providers Guide](./ai-providers.md) for cloud provider options.
