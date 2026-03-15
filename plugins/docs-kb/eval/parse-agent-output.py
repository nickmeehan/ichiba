#!/usr/bin/env python3
"""
Parse a doc-traversal agent output file and extract eval results.

Usage:
    python3 parse-agent-output.py <output-file> <test-id> <trial-num> <query>

Handles both:
- Agent outputs with eval-results blocks
- Raw Claude Code agent transcript JSON (lines of JSON objects)
"""

import json
import re
import sys
from pathlib import Path

# Paths that are template placeholders, not real docs
PLACEHOLDER_PATTERNS = ['path/to/', 'actual/', 'example/']


def is_placeholder(path):
    return any(p in path for p in PLACEHOLDER_PATTERNS) or path.startswith('path')


def extract_assistant_texts(content):
    """Extract text blocks from assistant messages in transcript, in order."""
    texts = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        if msg.get("type") != "assistant":
            continue

        message = msg.get("message", {})
        content_field = message.get("content", "")
        if isinstance(content_field, str):
            texts.append(content_field)
        elif isinstance(content_field, list):
            for block in content_field:
                if isinstance(block, dict) and block.get("type") == "text":
                    texts.append(block.get("text", ""))

    return texts


def extract_full_text(content):
    """Extract ALL text (user + assistant) for full transcript search."""
    texts = []
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            texts.append(line)
            continue

        message = msg.get("message", {})
        content_field = message.get("content", "")
        if isinstance(content_field, str):
            texts.append(content_field)
        elif isinstance(content_field, list):
            for block in content_field:
                if isinstance(block, dict) and block.get("type") == "text":
                    texts.append(block.get("text", ""))

    return "\n".join(texts)


def count_reads_from_transcript(content):
    """Count Read tool calls from transcript."""
    count = 0
    for line in content.strip().split('\n'):
        line = line.strip()
        if not line:
            continue
        try:
            msg = json.loads(line)
        except json.JSONDecodeError:
            continue

        message = msg.get("message", {})
        content_field = message.get("content", "")
        if isinstance(content_field, list):
            for block in content_field:
                if isinstance(block, dict) and block.get("type") == "tool_use":
                    if block.get("name") == "Read":
                        count += 1
    return count


def extract_docs_from_text(text):
    """Extract unique leaf doc paths from text, filtering placeholders."""
    all_refs = re.findall(r'docs/[a-z][a-z0-9_/-]*\.md', text)
    seen = set()
    result = []
    for d in all_refs:
        if d.endswith('_index.md'):
            continue
        if is_placeholder(d):
            continue
        if d not in seen:
            seen.add(d)
            result.append(d)
    return result


def find_returned_docs_from_last_message(assistant_texts):
    """Extract returned docs from the last assistant message."""
    if not assistant_texts:
        return []

    last_msg = assistant_texts[-1]

    # Try to find a structured section (Relevant Leaf Documents, etc.)
    sections = re.split(
        r'(?:Relevant Leaf|Returned|Final|Summary|Results)',
        last_msg,
        flags=re.IGNORECASE
    )
    if len(sections) > 1:
        final_section = sections[-1]
        docs = extract_docs_from_text(final_section)
        if docs:
            return docs

    # Fallback: all docs from last message
    return extract_docs_from_text(last_msg)


def parse_output(content, test_id, trial_num, query):
    assistant_texts = extract_assistant_texts(content)
    all_assistant_text = "\n".join(assistant_texts)

    # Count reads from transcript structure
    read_count = count_reads_from_transcript(content)

    # Find ALL eval-results blocks in assistant text (excludes user prompt echo)
    eval_matches = list(re.finditer(
        r'eval-results\s*\n(.*?)```',
        all_assistant_text,
        re.DOTALL
    ))
    # Take the last one that has real (non-placeholder) doc paths
    eval_match = None
    for m in reversed(eval_matches):
        block = m.group(1)
        docs_m = re.search(r'RETURNED_DOCS:\s*(.*)', block)
        if docs_m:
            paths = [d.strip() for d in docs_m.group(1).split(',') if d.strip().endswith('.md')]
            if not paths or not any(is_placeholder(p) for p in paths):
                eval_match = m
                break
    # Fallback to last match if none had clean paths
    if eval_match is None and eval_matches:
        eval_match = eval_matches[-1]

    returned_docs = []
    cap_respected = True
    had_eval_block = False

    if eval_match:
        had_eval_block = True
        block = eval_match.group(1)

        docs_match = re.search(r'RETURNED_DOCS:\s*(.*)', block)
        if docs_match:
            docs_str = docs_match.group(1).strip()
            if docs_str and docs_str.lower() not in ('none', 'n/a', ''):
                returned_docs = [
                    d.strip() for d in docs_str.split(',')
                    if d.strip() and d.strip().endswith('.md')
                ]

        # Filter out placeholder paths
        clean_docs = [d for d in returned_docs if not is_placeholder(d)]
        if len(clean_docs) < len(returned_docs):
            # Some placeholders found — fall back to heuristic from last assistant msg
            returned_docs = find_returned_docs_from_last_message(assistant_texts)
            had_eval_block = False
        else:
            returned_docs = clean_docs

        read_match = re.search(r'READ_COUNT:\s*(\d+)', block)
        if read_match:
            read_count = int(read_match.group(1))

        cap_match = re.search(r'CAP_RESPECTED:\s*(true|false)', block, re.IGNORECASE)
        if cap_match:
            cap_respected = cap_match.group(1).lower() == 'true'
    else:
        # No eval block in last message — try heuristic from last message
        returned_docs = find_returned_docs_from_last_message(assistant_texts)
        cap_respected = len(returned_docs) <= 7

    # Final safety: filter any remaining placeholders
    returned_docs = [d for d in returned_docs if not is_placeholder(d)]

    return {
        "test_id": test_id,
        "trial": trial_num,
        "query": query,
        "returned_docs": returned_docs,
        "read_count": read_count,
        "cap_respected": cap_respected,
        "had_eval_block": had_eval_block
    }


def main():
    if len(sys.argv) < 5:
        print(f"Usage: {sys.argv[0]} <output-file> <test-id> <trial-num> <query>")
        sys.exit(1)

    output_file = sys.argv[1]
    test_id = sys.argv[2]
    trial_num = int(sys.argv[3])
    query = sys.argv[4]

    with open(output_file) as f:
        content = f.read()

    result = parse_output(content, test_id, trial_num, query)

    results_dir = Path(__file__).parent / "results"
    results_dir.mkdir(exist_ok=True)
    out_path = results_dir / f"{test_id}-trial-{trial_num:02d}.json"

    with open(out_path, 'w') as f:
        json.dump(result, f, indent=2)

    print(f"Saved: {out_path}")
    print(f"  Returned docs: {len(result['returned_docs'])}")
    print(f"  Read count: {result['read_count']}")
    print(f"  Cap respected: {result['cap_respected']}")
    print(f"  Had eval block: {result['had_eval_block']}")
    for d in result['returned_docs']:
        print(f"    - {d}")


if __name__ == "__main__":
    main()
