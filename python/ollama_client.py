"""Minimal Ollama client using only the Python standard library (no pip install needed).

Usage as a script:
    python3 python/ollama_client.py "Summarize the causes of the fall of Rome in 3 bullets."

Usage as a module:
    from ollama_client import chat
    print(chat([{"role": "user", "content": "Hello"}]))
"""

import json
import os
import sys
import urllib.request

HOST = os.environ.get("OLLAMA_HOST", "127.0.0.1:11434")
BASE_URL = HOST if HOST.startswith("http") else f"http://{HOST}"
DEFAULT_MODEL = os.environ.get("OLLAMA_MODELS_TO_PULL", "llama3.1:8b").split()[0]


def _post(path, payload, timeout=600):
    req = urllib.request.Request(
        f"{BASE_URL}{path}",
        data=json.dumps(payload).encode(),
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.load(resp)


def chat(messages, model=DEFAULT_MODEL, temperature=0.2, **options):
    """Send a list of {"role", "content"} messages; return the assistant reply text."""
    payload = {
        "model": model,
        "messages": messages,
        "stream": False,
        "options": {"temperature": temperature, **options},
    }
    return _post("/api/chat", payload)["message"]["content"]


def generate(prompt, model=DEFAULT_MODEL, system=None, temperature=0.2, **options):
    """Single prompt -> completion text."""
    payload = {
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {"temperature": temperature, **options},
    }
    if system:
        payload["system"] = system
    return _post("/api/generate", payload)["response"]


if __name__ == "__main__":
    prompt = " ".join(sys.argv[1:]) or "Say hello in one sentence."
    print(generate(prompt))
