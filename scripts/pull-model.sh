#!/usr/bin/env bash
# pull-model.sh — pull an Ollama model into the running container.
# Usage: bash scripts/pull-model.sh
# The script must be run from the repository root (where docker-compose.yml lives).

set -euo pipefail

# ── Load .env if it exists ────────────────────────────────────────────────────
ENV_FILE="$(dirname "$0")/../.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

DEFAULT_MODEL="${MODEL:-llama3.2}"

# ── Curated popular models ────────────────────────────────────────────────────
# Each entry is "model-name|Human-readable description".
# The model name (before '|') is used when pulling; the description is displayed.
MODELS=(
  "llama3.2|Meta Llama 3.2 (3B, general purpose, fast)"
  "llama3.1|Meta Llama 3.1 (8B, stronger reasoning)"
  "mistral|Mistral 7B (general purpose, very capable)"
  "codellama|Code Llama 7B (code generation & completion)"
  "gemma3|Google Gemma 3 (4B, efficient, multilingual)"
  "phi4|Microsoft Phi-4 (14B, advanced reasoning)"
  "deepseek-r1|DeepSeek R1 (8B, reasoning-focused)"
  "qwen2.5-coder|Qwen 2.5 Coder (7B, coding specialist)"
  "gpt-oss:20b|GPT OSS 20B (20B, OpenAI open-source)"
)

# ── Check the container is running ───────────────────────────────────────────
if ! docker compose ps --services --filter status=running 2>/dev/null | grep -q "^ollama$"; then
  echo "ERROR: The 'ollama' container is not running."
  echo "       Start it first with:  docker compose up -d"
  exit 1
fi

# ── Prompt ────────────────────────────────────────────────────────────────────
echo ""
echo "══════════════════════════════════════════════════════"
echo "  Ollama Model Installer"
echo "══════════════════════════════════════════════════════"
echo ""
echo "Popular models:"
echo ""
for i in "${!MODELS[@]}"; do
  name="${MODELS[$i]%%|*}"
  desc="${MODELS[$i]##*|}"
  printf "  [%d] %-15s – %s\n" "$((i + 1))" "$name" "$desc"
done
echo ""
echo "  [c] Enter a custom model name"
echo "  [q] Quit"
echo ""
echo "Default (from .env / MODEL variable): ${DEFAULT_MODEL}"
echo ""
read -rp "Your choice [1-${#MODELS[@]} / c / q, default=c]: " CHOICE

case "${CHOICE}" in
  [qQ])
    echo "Aborted."
    exit 0
    ;;
  [cC] | "")
    read -rp "Enter model name (e.g. llama3.2, mistral, phi4:mini): " CUSTOM
    CUSTOM="${CUSTOM:-$DEFAULT_MODEL}"
    if [[ -z "${CUSTOM}" ]]; then
      echo "ERROR: No model name provided."
      exit 1
    fi
    SELECTED_MODEL="${CUSTOM}"
    ;;
  *)
    if [[ "${CHOICE}" =~ ^[0-9]+$ ]] && (( CHOICE >= 1 && CHOICE <= ${#MODELS[@]} )); then
      SELECTED_MODEL="${MODELS[$((CHOICE - 1))]%%|*}"
    else
      echo "ERROR: Invalid choice '${CHOICE}'."
      exit 1
    fi
    ;;
esac

echo ""
echo "Pulling model: ${SELECTED_MODEL}"
echo "This may take several minutes depending on model size and your connection."
echo ""

docker compose exec ollama ollama pull "${SELECTED_MODEL}"

echo ""
echo "Done! Model '${SELECTED_MODEL}' is ready."
echo ""
echo "To run it interactively:"
echo "  docker compose exec ollama ollama run ${SELECTED_MODEL}"
echo ""
echo "To list all downloaded models:"
echo "  docker compose exec ollama ollama list"
