#!/usr/bin/env python3
"""
Score doc-traversal agent eval results.

Usage:
    python3 score-results.py results/           # score all result files in directory
    python3 score-results.py results/narrow-oauth-*.json  # score specific files

Result files are JSON with structure:
{
  "test_id": "narrow-oauth",
  "trial": 1,
  "query": "implementing OAuth token refresh",
  "returned_docs": ["docs/path1.md", "docs/path2.md"],
  "read_count": 15,
  "cap_respected": true
}
"""

import json
import sys
import os
from pathlib import Path
from itertools import combinations
from collections import Counter


def load_config():
    config_path = Path(__file__).parent / "eval-config.json"
    with open(config_path) as f:
        return json.load(f)


def load_results(path_args):
    results = []
    for arg in path_args:
        p = Path(arg)
        if p.is_dir():
            for f in sorted(p.glob("*.json")):
                with open(f) as fh:
                    results.append(json.load(fh))
        elif p.is_file() and p.suffix == ".json":
            with open(p) as fh:
                results.append(json.load(fh))
    return results


def jaccard(set_a, set_b):
    if not set_a and not set_b:
        return 1.0
    union = set_a | set_b
    if not union:
        return 1.0
    return len(set_a & set_b) / len(union)


def score_trial(trial, test_config):
    returned = set(trial["returned_docs"])
    must = set(test_config["must_include"])
    may = set(test_config.get("may_include", []))
    must_not = set(test_config.get("must_not_include", []))
    acceptable = must | may

    # Must-include recall
    recall = len(returned & must) / len(must) if must else 1.0

    # Precision (fraction of returned that are acceptable)
    precision = len(returned & acceptable) / len(returned) if returned else 1.0

    # Must-not-include violations
    violations = returned & must_not

    # Cap adherence
    max_docs = test_config["constraints"]["max_returned_docs"]
    cap_ok = len(returned) <= max_docs

    # Read efficiency
    max_reads = test_config["constraints"]["max_read_calls"]
    read_count = trial.get("read_count", 0)
    read_ok = read_count <= max_reads

    return {
        "must_include_recall": recall,
        "precision": precision,
        "violations": sorted(violations),
        "cap_respected": cap_ok,
        "returned_count": len(returned),
        "read_count": read_count,
        "read_within_budget": read_ok,
    }


def score_test(test_id, trials, test_config):
    scores = [score_trial(t, test_config) for t in trials]

    # Consistency: average pairwise Jaccard across trials
    doc_sets = [frozenset(t["returned_docs"]) for t in trials]
    if len(doc_sets) >= 2:
        jaccards = [jaccard(a, b) for a, b in combinations(doc_sets, 2)]
        consistency = sum(jaccards) / len(jaccards)
    else:
        consistency = 1.0

    # Document frequency: how often each doc appears across trials
    all_docs = Counter()
    for t in trials:
        for d in t["returned_docs"]:
            all_docs[d] += 1

    n = len(trials)
    return {
        "test_id": test_id,
        "test_name": test_config["name"],
        "num_trials": n,
        "avg_recall": sum(s["must_include_recall"] for s in scores) / n,
        "avg_precision": sum(s["precision"] for s in scores) / n,
        "cap_adherence": sum(1 for s in scores if s["cap_respected"]) / n,
        "avg_returned_count": sum(s["returned_count"] for s in scores) / n,
        "avg_read_count": sum(s["read_count"] for s in scores) / n,
        "read_budget_adherence": sum(1 for s in scores if s["read_within_budget"]) / n,
        "consistency_jaccard": consistency,
        "doc_frequency": {
            doc: count / n for doc, count in all_docs.most_common()
        },
        "violation_frequency": {
            doc: count
            for doc, count in Counter(
                d for s in scores for d in s["violations"]
            ).most_common()
        },
    }


def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <results-dir-or-files...>")
        sys.exit(1)

    config = load_config()
    results = load_results(sys.argv[1:])

    if not results:
        print("No result files found.")
        sys.exit(1)

    # Group by test_id
    by_test = {}
    for r in results:
        by_test.setdefault(r["test_id"], []).append(r)

    test_lookup = {t["id"]: t for t in config["tests"]}

    print("=" * 80)
    print("DOC-TRAVERSAL AGENT EVAL RESULTS")
    print("=" * 80)

    all_scores = []
    for test_id in sorted(by_test.keys()):
        trials = by_test[test_id]
        tc = test_lookup.get(test_id)
        if not tc:
            print(f"\nWARN: No config for test_id={test_id}, skipping")
            continue

        s = score_test(test_id, trials, tc)
        all_scores.append(s)

        print(f"\n{'─' * 80}")
        print(f"Test: {s['test_name']} ({test_id})")
        print(f"  Trials: {s['num_trials']}")
        print(f"  Must-Include Recall:  {s['avg_recall']:.0%}")
        print(f"  Precision:            {s['avg_precision']:.0%}")
        print(f"  Cap Adherence (≤7):   {s['cap_adherence']:.0%}")
        print(f"  Avg Returned Docs:    {s['avg_returned_count']:.1f}")
        print(f"  Avg Read Calls:       {s['avg_read_count']:.1f}")
        print(f"  Read Budget (≤{tc['constraints']['max_read_calls']}):     {s['read_budget_adherence']:.0%}")
        print(f"  Consistency (Jaccard): {s['consistency_jaccard']:.2f}")

        if s["doc_frequency"]:
            print(f"  Doc Frequency (top 10):")
            for doc, freq in list(s["doc_frequency"].items())[:10]:
                bar = "█" * int(freq * 20)
                print(f"    {freq:5.0%} {bar} {doc}")

        if s["violation_frequency"]:
            print(f"  ⚠ Must-Not-Include Violations:")
            for doc, count in s["violation_frequency"].items():
                print(f"    {count}/{s['num_trials']} trials: {doc}")

    # Summary
    if all_scores:
        print(f"\n{'=' * 80}")
        print("SUMMARY")
        print(f"{'=' * 80}")
        n = len(all_scores)
        print(f"  Tests:                {n}")
        print(f"  Total Trials:         {sum(s['num_trials'] for s in all_scores)}")
        print(f"  Avg Recall:           {sum(s['avg_recall'] for s in all_scores) / n:.0%}")
        print(f"  Avg Precision:        {sum(s['avg_precision'] for s in all_scores) / n:.0%}")
        print(f"  Avg Cap Adherence:    {sum(s['cap_adherence'] for s in all_scores) / n:.0%}")
        print(f"  Avg Consistency:      {sum(s['consistency_jaccard'] for s in all_scores) / n:.2f}")
        print(f"  Avg Read Calls:       {sum(s['avg_read_count'] for s in all_scores) / n:.1f}")


if __name__ == "__main__":
    main()
