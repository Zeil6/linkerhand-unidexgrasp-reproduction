#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-state}"
ROOT="${UNIDEX_ROOT:-$(pwd)}"
CHECKPOINT="${CHECKPOINT:-}"
POLICY_DIR="$ROOT/dexgrasp_policy_l20hand/dexgrasp"

test -n "$CHECKPOINT" || { echo 'ERROR: set CHECKPOINT=/absolute/path/to/model.pt'; exit 2; }
test -f "$CHECKPOINT" || { echo "ERROR: checkpoint not found: $CHECKPOINT"; exit 1; }
case "$CHECKPOINT" in /*) ;; *) echo 'ERROR: CHECKPOINT must be an absolute path'; exit 2 ;; esac

case "$MODE" in
  state) SCRIPT="$POLICY_DIR/script/run_train_ppo_state.sh" ;;
  vision) SCRIPT="$POLICY_DIR/script/run_train_ppo_vision.sh" ;;
  *) echo 'Usage: test_checkpoint.sh {state|vision}'; exit 2 ;;
esac

test -f "$SCRIPT" || { echo "ERROR: upstream script not found: $SCRIPT"; exit 1; }
echo "Checkpoint validated: $CHECKPOINT"
echo 'The upstream shell scripts may encode their own test/checkpoint flags.'
echo "Inspect before launch: $SCRIPT"
echo 'Then pass the validated absolute checkpoint using the CLI option supported by that upstream commit.'
echo 'No command was guessed or launched automatically.'