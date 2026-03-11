# Run Ollama in Docker

Run [Ollama](https://ollama.com) as a persistent Docker container on your Ubuntu server. The container exposes the Ollama REST API on the host, restarts automatically unless explicitly stopped, and stores all downloaded models in a named volume so they survive container recreation.

---

## Prerequisites

- Ubuntu server with **Docker Engine** and **Docker Compose** (v2) installed and running
- Internet access to pull the Ollama image and LLM weights

---

## Quick Start

### 1. Clone the repository

```bash
git clone https://github.com/vibhatsrivastava/Install_Ollama_In_Docker.git
cd Install_Ollama_In_Docker
```

### 2. Configure environment variables

```bash
cp .env.example .env
```

Open `.env` and adjust the values if needed:

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_IMAGE` | `ollama/ollama:latest` | Ollama Docker image and tag to use |
| `OLLAMA_PORT` | `11434` | Host port the Ollama API is reachable on |
| `MODEL` | `llama3.2` | Default model used by the pull script |

### 3. Start the Ollama container (detached)

```bash
docker compose up -d
```

The container will:
- Start in the background
- Restart automatically on Docker daemon or host reboot
- Stay stopped only if you explicitly stop it with `docker compose stop`

### 4. Verify the API is reachable from the host

> **Note:** The examples below use the default port `11434`. If you changed `OLLAMA_PORT` in your `.env` file, replace `11434` with your configured value.

```bash
# Optional: export your configured port so the command picks it up automatically
source .env
curl http://localhost:${OLLAMA_PORT:-11434}
```

Expected response: `Ollama is running`

---

## Download a Model

Run the interactive model-pull script:

```bash
bash scripts/pull-model.sh
```

You will be shown a numbered menu of popular models. Pick one, or choose **[c]** to enter any model name from the [Ollama library](https://ollama.com/library).

### Popular models included in the menu

| # | Model | Notes |
|---|---|---|
| 1 | `llama3.2` | Meta Llama 3.2 — 3B, fast, general purpose |
| 2 | `llama3.1` | Meta Llama 3.1 — 8B, stronger reasoning |
| 3 | `mistral` | Mistral 7B — very capable, general purpose |
| 4 | `codellama` | Code Llama 7B — code generation & completion |
| 5 | `gemma3` | Google Gemma 3 — 4B, multilingual, efficient |
| 6 | `phi4` | Microsoft Phi-4 — 14B, advanced reasoning |
| 7 | `deepseek-r1` | DeepSeek R1 — 8B, reasoning-focused |
| 8 | `qwen2.5-coder` | Qwen 2.5 Coder — 7B, coding specialist |
| 9 | `gpt-oss:20b` | GPT OSS 20B — 20B, OpenAI open-source |

> **Custom model**: Enter any model tag from https://ollama.com/library, e.g. `phi4:mini`, `llama3.2:1b`, `mistral:7b-instruct-q4_0`.

After the pull completes you can run the model interactively:

```bash
docker compose exec ollama ollama run <model_name>
```

List all downloaded models:

```bash
docker compose exec ollama ollama list
```

---

## Container Lifecycle

| Action | Command |
|---|---|
| Start (detached) | `docker compose up -d` |
| Stop (stays stopped) | `docker compose stop` |
| Restart | `docker compose restart` |
| View logs | `docker compose logs -f ollama` |
| Remove container (keep models) | `docker compose down` |
| Remove container **and models** | `docker compose down -v` |

---

## Persistent Storage

All models are stored in a named Docker volume called `ollama_data`, mounted at `/root/.ollama` inside the container.

- `docker compose down` removes the container but **keeps the volume** — your models are safe.
- `docker compose down -v` removes both the container and the volume — **all models are deleted**.

Inspect the volume:

```bash
docker volume inspect ollama_data
```

---

## Connecting to the API

The Ollama REST API is available at `http://<your-server-ip>:<OLLAMA_PORT>` from any machine that can reach the host (default port: `11434`).  
Full API reference: https://github.com/ollama/ollama/blob/main/docs/api.md

Quick test — generate a response (replace `11434` with your `OLLAMA_PORT` if you changed it):

```bash
curl http://localhost:11434/api/generate \
  -d '{"model":"llama3.2","prompt":"Say hello in one sentence.","stream":false}'
```

---

## Restricting Access with an API Key

By default, Ollama accepts all incoming requests without authentication. To restrict access, you can enable API key authentication using the `OLLAMA_API_KEY` environment variable (supported since Ollama **v0.1.24**).

### 1. Generate an API key

An API key is simply a cryptographically random secret string that you create yourself. Use one of the following methods:

**PowerShell (Windows):**
```powershell
[System.Convert]::ToBase64String([System.Security.Cryptography.RandomNumberGenerator]::GetBytes(32))
```

**Bash / Linux / macOS:**
```bash
openssl rand -base64 32
```

**Python (any platform):**
```bash
python -c "import secrets; print(secrets.token_urlsafe(32))"
```

Any of these produces a secure random string such as:
```
K7gNU3sdo-OL0wNhqoVWhr3g6s1xYv72ol_pe_Unols=
```

### 2. Add the API key to your `.env` file

Open your `.env` file and add the key:

```env
OLLAMA_API_KEY=your-generated-key-here
```

> **Security:** Never commit `.env` to version control. Ensure `.env` is listed in your `.gitignore`.

Update the variable reference table accordingly:

| Variable | Default | Description |
|---|---|---|
| `OLLAMA_IMAGE` | `ollama/ollama:latest` | Ollama Docker image and tag to use |
| `OLLAMA_PORT` | `11434` | Host port the Ollama API is reachable on |
| `MODEL` | `llama3.2` | Default model used by the pull script |
| `OLLAMA_API_KEY` | *(unset)* | Secret key required to authenticate API requests |

### 3. Pass the API key to the container

Reference the variable in `docker-compose.yml` under the `environment` section:

```yaml
environment:
  - OLLAMA_HOST=0.0.0.0
  - OLLAMA_API_KEY=${OLLAMA_API_KEY}
```

Then restart the container to apply the change:

```bash
docker compose up -d --force-recreate
```

### 4. Authenticate requests from the client side

Once the API key is set, every HTTP request to the Ollama API must include the key in the `Authorization` header:

```bash
curl http://localhost:11434/api/generate \
  -H "Authorization: Bearer your-generated-key-here" \
  -d '{"model":"llama3.2","prompt":"Say hello in one sentence.","stream":false}'
```

Requests without a valid key will receive a `401 Unauthorized` response.

**Using the OpenAI-compatible endpoint** (e.g. with tools like Open WebUI or LangChain):
```bash
curl http://localhost:11434/v1/chat/completions \
  -H "Authorization: Bearer your-generated-key-here" \
  -H "Content-Type: application/json" \
  -d '{"model":"llama3.2","messages":[{"role":"user","content":"Hello!"}]}'
```

> **Note:** The API key only secures HTTP API access. It does **not** affect the Ollama CLI running inside the container (e.g. `docker compose exec ollama ollama run ...`).

---

## License

[GPL-3.0](LICENSE)

