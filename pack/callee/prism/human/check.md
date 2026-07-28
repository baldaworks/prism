---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Script
spec:
  description: Validates that the Prism human gate received an explicit approval.
  shell: sh
  env:
    APPROVAL_RESPONSE: |-
      {{ index .State.outputs "approval_prompt" }}
---
normalized="$(
  printf '%s' "$APPROVAL_RESPONSE" \
    | tr -d '\r' \
    | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | tr '[:lower:]' '[:upper:]'
)"

if [ "$normalized" = "APPROVE" ]; then
  printf 'Prism human gate approved.\n'
  exit 0
fi

printf 'Prism human gate withheld approval: %s\n' "$APPROVAL_RESPONSE" >&2
exit 1
