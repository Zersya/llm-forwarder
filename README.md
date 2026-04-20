# LLM Forwarder

A self-hosted LLM proxy service that allows you to share your custom API key with others while tracking their usage by project.

## Features

- **API Key Management** - Generate unique API keys for each user/project
- **Usage Tracking** - Track tokens, costs, and requests per key
- **Rate Limiting** - Configure RPM/TPM limits per API key
- **OpenAI Compatible** - Works with any OpenAI-compatible client
- **SQLite Database** - Built-in persistence for tracking
- **Fully Customizable** - Use any LLM provider (OpenAI, Fireworks, Ollama, etc.)

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` with your LLM provider details:

```bash
# Example: OpenAI
LLM_API_KEY=sk-...
API_BASE_URL=https://api.openai.com/v1
MODEL_NAME=gpt-4o
MODEL_ALIAS=my-model

# Example: Fireworks.ai
LLM_API_KEY=your-fireworks-key
API_BASE_URL=https://api.fireworks.ai/inference/v1
MODEL_NAME=fireworks/accounts/fireworks/models/llama-v3_1-70b-instruct
MODEL_ALIAS=my-model

# Example: Ollama (local)
LLM_API_KEY=not-needed
API_BASE_URL=http://localhost:11434/v1
MODEL_NAME=llama3
MODEL_ALIAS=my-model

# Admin key (change this!)
MASTER_KEY=sk-admin-change-this-in-production
```

### 2. Start the Service

```bash
# Create data directory
mkdir -p data

# Start with Docker
docker-compose up -d
```

### 3. Generate API Keys

```bash
# Generate a key for a project
./scripts/setup-keys.sh generate my-project 30d 100 100000

# List all keys
./scripts/setup-keys.sh list

# View usage
./scripts/setup-keys.sh usage

# Delete a key
./scripts/setup-keys.sh delete sk-xxxxxxxx
```

## Usage

### Making Requests

Users can make requests using their API key:

```bash
curl http://localhost:4000/v1/chat/completions \
  -H "Authorization: Bearer sk-user-api-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "my-model",
    "messages": [
      {"role": "user", "content": "Hello, how are you?"}
    ]
  }'
```

### With OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    api_key="sk-user-api-key",
    base_url="http://localhost:4000/v1"
)

response = client.chat.completions.create(
    model="my-model",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

### With JavaScript/TypeScript

```javascript
import OpenAI from 'openai'

const client = new OpenAI({
  apiKey: 'sk-user-api-key',
  baseURL: 'http://localhost:4000/v1'
})

const response = await client.chat.completions.create({
  model: 'my-model',
  messages: [{ role: 'user', content: 'Hello!' }]
})
```

## Supported Providers

The forwarder works with any OpenAI-compatible API. Here are common examples:

| Provider | API_BASE_URL | MODEL_NAME |
|----------|--------------|------------|
| OpenAI | `https://api.openai.com/v1` | `gpt-4o`, `gpt-3.5-turbo` |
| Fireworks.ai | `https://api.fireworks.ai/inference/v1` | `fireworks/accounts/.../llama-v3_1-70b` |
| Azure OpenAI | `https://your-resource.openai.azure.com/` | `gpt-4o` |
| Ollama | `http://localhost:11434/v1` | `llama3`, `mistral` |
| vLLM | `http://your-vllm-server:8000/v1` | `meta-llama/Llama-3.1-70B-Instruct` |
| Custom | `https://your-endpoint.com/v1` | Any model your endpoint supports |

## Admin Endpoints

All admin endpoints require the `MASTER_KEY` in the Authorization header.

### Generate Key
```bash
curl -X POST http://localhost:4000/key/generate \
  -H "Authorization: Bearer sk-admin-key" \
  -H "Content-Type: application/json" \
  -d '{
    "key_alias": "my-project",
    "duration": "30d",
    "rpm": 100,
    "tpm": 100000,
    "models": ["my-model"],
    "metadata": {"project": "my-project"}
  }'
```

### List Keys
```bash
curl http://localhost:4000/key/info \
  -H "Authorization: Bearer sk-admin-key"
```

### View Spend
```bash
curl http://localhost:4000/spend/info \
  -H "Authorization: Bearer sk-admin-key"
```

### View Key Spend
```bash
curl "http://localhost:4000/key/info?key=sk-user-key" \
  -H "Authorization: Bearer sk-admin-key"
```

## API Reference

| Endpoint | Description |
|----------|-------------|
| `GET /health` | Health check |
| `POST /v1/chat/completions` | Chat completions (OpenAI compatible) |
| `POST /v1/completions` | Text completions |
| `POST /v1/embeddings` | Embeddings |
| `GET /v1/models` | List available models |
| `POST /key/generate` | Generate new API key |
| `GET /key/info` | List all keys |
| `DELETE /key/delete` | Delete API key |
| `GET /spend/info` | View spending |

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `LLM_API_KEY` | Yes | Your LLM provider API key |
| `API_BASE_URL` | Yes | Base URL for the LLM API |
| `MODEL_NAME` | Yes | Model name as defined by provider |
| `MODEL_ALIAS` | Yes | Friendly name users will use |
| `MASTER_KEY` | Yes | Admin master key |
| `DATABASE_URL` | No | Database URL (default: SQLite) |

## Deployment

### Production Tips

1. **Change MASTER_KEY** - Use a strong, unique key
2. **Use PostgreSQL** - For better scalability:
   ```yaml
   DATABASE_URL: postgresql://user:pass@host:5432/litellm
   ```
3. **Add SSL/TLS** - Put behind a reverse proxy like nginx
4. **Set up backups** - Backup the SQLite database regularly

### Docker Commands

```bash
# Build and start
docker-compose up -d --build

# View logs
docker-compose logs -f litellm

# Stop
docker-compose down

# Restart
docker-compose restart
```

## Project Structure

```
llm-forwarder/
├── config.yaml          # LiteLLM configuration
├── docker-compose.yml   # Docker orchestration
├── Dockerfile          # Container definition
├── .env.example         # Environment template
├── scripts/
│   └── setup-keys.sh   # Key management script
├── data/                # SQLite database (created on first run)
└── README.md
```

## Troubleshooting

### Service won't start
```bash
# Check logs
docker-compose logs litellm

# Verify .env file exists
cat .env
```

### Invalid API key
- Ensure the key hasn't expired
- Check if the key has access to the requested model
- Verify the key hasn't been deleted

### Rate limit errors
- The user has exceeded their RPM/TPM limit
- Generate a new key with higher limits or wait

### Model not found
- Verify MODEL_NAME matches exactly what your provider expects
- Check API_BASE_URL is correct
- Ensure LLM_API_KEY is valid

## License

MIT