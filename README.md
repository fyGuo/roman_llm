# roman_llm

Template for running a local LLM with [Ollama](https://ollama.com) on a remote Linux VM.
Edit here, push to GitHub, then `git clone` / `git pull` on the VM.

## Quick start (on the VM)

```bash
git clone https://github.com/fyGuo/roman_llm.git
cd roman_llm

bash scripts/check_env.sh        # 1. what does the VM have? (GPU, RAM, disk, sudo, internet)
bash scripts/install_ollama.sh   # 2. install (works without sudo)
bash scripts/start_server.sh     # 3. start server in the background
bash scripts/pull_models.sh      # 4. download model(s) from config.env
bash scripts/test_api.sh         # 5. smoke test
bash scripts/setup_python.sh     # 6. uv + pinned Python + dependencies (.venv)
```

Then use it:

```bash
source config.env                 # puts ollama on PATH for this shell
ollama run llama3.1:8b            # interactive chat
uv run python/ollama_client.py "Explain the Roman Republic in two sentences."
```

Stop the server with `bash scripts/stop_server.sh`.

## Layout

| Path | Purpose |
|---|---|
| `config.env` | Model list, host/port, model storage dir — the one file to edit |
| `scripts/check_env.sh` | Hardware / permission / network report |
| `scripts/install_ollama.sh` | Official installer with sudo; user-local install without |
| `scripts/start_server.sh`, `stop_server.sh` | Background server; logs in `run/ollama.log` |
| `scripts/pull_models.sh` | Download models (`bash scripts/pull_models.sh qwen2.5:7b` to override) |
| `scripts/test_api.sh` | One-shot request against the REST API |
| `pyproject.toml`, `uv.lock`, `.python-version` | Python version and dependencies, managed by uv |
| `scripts/setup_python.sh` | Install uv (no sudo) and run `uv sync` |
| `python/ollama_client.py` | Client (`chat`, `generate`), standard library only |
| `python/batch_example.py` | Apply a prompt to each row of a CSV, resumable |
| `Modelfile.example` | Custom model with fixed system prompt / parameters |
| `docker-compose.yml` | Alternative if the VM has Docker |

## Choosing a model

Rough memory needs (default 4-bit quantization):

| Size | Example | RAM / VRAM |
|---|---|---|
| 3B | `llama3.2:3b` | ~3 GB |
| 7–8B | `llama3.1:8b`, `qwen2.5:7b` | ~5–6 GB |
| 14B | `qwen2.5:14b` | ~10 GB |
| 70B | `llama3.1:70b` | ~40 GB+ (GPU strongly advised) |

Without a GPU, stay at 8B or below. Set the choice in `config.env` (`OLLAMA_MODELS_TO_PULL`).
If the home directory is small, point `OLLAMA_MODELS` at a larger disk.

## Python environment (uv)

Python version is pinned in `.python-version`; dependencies live in `pyproject.toml` and are
locked in `uv.lock`. Always change them on your local machine, then commit and push:

```bash
uv add pandas            # add a dependency (updates pyproject.toml + uv.lock)
uv remove pandas         # remove one
uv python pin 3.12       # change the Python version
git add pyproject.toml uv.lock .python-version && git commit -m "deps" && git push
```

On the VM, `git pull && uv sync --locked` reproduces the exact same environment.
Run code with `uv run <script.py>` (no need to activate `.venv`).

## Offline install

If `check_env.sh` reports ollama.com is unreachable:

1. On your own machine, download `ollama-linux-amd64.tgz` (or `.tar.zst`) from the
   [Ollama releases](https://github.com/ollama/ollama/releases) and put it in `offline/` on the VM.
2. Run `bash scripts/install_ollama.sh`.
3. uv downloads Python and packages from the internet too. Without access, install uv from its
   release archive and point it at the VM's own Python (`uv python pin /usr/bin/python3`).
4. Models also need transferring: run `ollama pull <model>` on a machine with internet, then copy
   its `~/.ollama/models` directory into the VM's `OLLAMA_MODELS` directory.

## Workflow

```bash
# local machine
git add -A && git commit -m "..." && git push
# VM
git pull && uv sync --locked
```

Don't commit model weights, logs, or data — `.gitignore` already excludes `run/`, `offline/*`, and `*.gguf`.
