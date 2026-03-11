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

## License

[GPL-3.0](LICENSE)

