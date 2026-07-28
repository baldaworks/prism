---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Script
spec:
  description: Extracts the final requirements document from the specify normalizer output.
  shell: sh
  env:
    SPECIFY_OUTPUT: |-
      {{ index .State.outputs "specify_executor" }}
---
doc="$(
  printf '%s\n' "$SPECIFY_OUTPUT" \
    | awk '
        found { print }
        /^REQUIREMENTS_DOCUMENT:[[:space:]]*$/ { found=1; next }
      '
)"

trimmed="$(
  printf '%s' "$doc" \
    | sed '/./,$!d'
)"

if [ -z "$trimmed" ]; then
  printf 'specify output did not contain a REQUIREMENTS_DOCUMENT section\n' >&2
  exit 1
fi

printf '%s\n' "$trimmed"
