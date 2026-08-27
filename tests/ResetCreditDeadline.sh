#!/usr/bin/env bash

set -uo pipefail

ui_dir="$(dirname "$0")/../package/contents/ui"
helper_path="$(dirname "$0")/../package/contents/code/codex_usage.py"

if rg -q 'nextResetCreditExpiresAt' "$helper_path" \
    && rg -q 'nearest_reset_credit_expiry\(reset_credits\)' "$helper_path" \
    && rg -q 'label: qsTr\("À utiliser avant"\)' "$ui_dir/FullRepresentation.qml" \
    && rg -q 'deadlineLabel\(payload\.nextResetCreditExpiresAt\)' "$ui_dir/main.qml" \
    && ! rg -q -i 'spark|bengalfox|5\.3' "$ui_dir"; then
    echo "PASS: reset deadline is shown and Codex Spark is absent"
    exit 0
fi

echo "FAIL: reset deadline or Codex Spark display is inconsistent"
exit 1
