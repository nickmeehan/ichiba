#!/usr/bin/env bash
# Parse a batch of agent output files into eval result JSONs.
# Usage: ./batch-parse.sh <round-num> <oauth-file> <api-file> <deploy-file> <auth-file> <okta-file> <ml-file>
#
# Example:
#   ./batch-parse.sh 1 /tmp/agent1.output /tmp/agent2.output ...

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROUND=${1:?Round number required}
shift

TESTS=(
  "narrow-oauth|implementing OAuth token refresh"
  "wide-api|setting up a new API endpoint"
  "broad-deploy|deploying the application"
  "cross-auth-debug|debugging auth issues"
  "deep-okta|configuring Okta SSO SCIM provisioning"
  "negative-ml|machine learning model training"
)

for i in "${!TESTS[@]}"; do
  IFS='|' read -r test_id query <<< "${TESTS[$i]}"
  output_file="${1:?Missing output file for $test_id}"
  shift

  if [ -f "$output_file" ]; then
    python3 "$SCRIPT_DIR/parse-agent-output.py" "$output_file" "$test_id" "$ROUND" "$query"
  else
    echo "WARN: Output file not found: $output_file (test: $test_id)"
  fi
done

echo ""
echo "Round $ROUND parsed. Run scoring with:"
echo "  python3 $SCRIPT_DIR/score-results.py $SCRIPT_DIR/results/"
