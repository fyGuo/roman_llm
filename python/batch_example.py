"""Run a prompt over every row of a CSV and write the model output to a new column.

    python3 python/batch_example.py input.csv output.csv --column text \
        --instruction "Classify the sentiment as positive, negative, or neutral. Answer with one word."

Rows already present in output.csv are skipped, so an interrupted run can be resumed.
"""

import argparse
import csv
import os
import sys

sys.path.insert(0, os.path.dirname(__file__))
from ollama_client import DEFAULT_MODEL, generate  # noqa: E402


def main():
    p = argparse.ArgumentParser()
    p.add_argument("input")
    p.add_argument("output")
    p.add_argument("--column", required=True, help="CSV column holding the text to process")
    p.add_argument("--instruction", required=True, help="Task instruction (used as system prompt)")
    p.add_argument("--model", default=DEFAULT_MODEL)
    p.add_argument("--out-column", default="llm_output")
    args = p.parse_args()

    with open(args.input, newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if not rows:
        sys.exit("Input CSV is empty.")
    fields = list(rows[0].keys()) + [args.out_column]

    done = 0
    if os.path.exists(args.output):
        with open(args.output, newline="", encoding="utf-8") as f:
            done = sum(1 for _ in csv.DictReader(f))

    mode = "a" if done else "w"
    with open(args.output, mode, newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fields)
        if not done:
            writer.writeheader()
        for i, row in enumerate(rows[done:], start=done + 1):
            row[args.out_column] = generate(row[args.column], model=args.model, system=args.instruction).strip()
            writer.writerow(row)
            f.flush()
            print(f"[{i}/{len(rows)}] done", file=sys.stderr)


if __name__ == "__main__":
    main()
