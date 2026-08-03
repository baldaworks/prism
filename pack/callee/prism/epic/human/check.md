---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Script
spec:
  description: Validates the fail-closed Epic approval decision.
  shell: sh
  env:
    EPIC_APPROVAL_INTENT: |-
      {{ index .State.outputs "epic_approval_intent" }}
---
normalized="$(
  printf '%s' "$EPIC_APPROVAL_INTENT" \
    | tr -d '\r' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | tr '[:lower:]' '[:upper:]'
)"

case "$normalized" in
  APPROVE)
    printf 'APPROVE\n'
    exit 0
    ;;
  REFINE_ARCHITECTURE)
    printf 'PRISM_EPIC_DECISION=REFINE_ARCHITECTURE\n' >&2
    exit 2
    ;;
  *)
    printf 'Prism Epic approval withheld: %s\n' "$EPIC_APPROVAL_INTENT" >&2
    exit 1
    ;;
esac
