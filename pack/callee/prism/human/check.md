---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Script
spec:
  description: Validates the fail-closed free-form approval intent decision.
  shell: sh
  env:
    APPROVAL_INTENT: |-
      {{ index .State.outputs "approval_intent" }}
---
normalized="$(
  printf '%s' "$APPROVAL_INTENT" \
    | tr -d '\r' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | tr '[:lower:]' '[:upper:]'
)"

case "$normalized" in
  APPROVE)
    printf 'APPROVE\n'
    exit 0
    ;;
  REFINE_DESIGN)
    printf 'PRISM_HUMAN_DECISION=REFINE_DESIGN\n' >&2
    exit 2
    ;;
  *)
    printf 'Prism human gate withheld approval: %s\n' "$APPROVAL_INTENT" >&2
    exit 1
    ;;
esac
