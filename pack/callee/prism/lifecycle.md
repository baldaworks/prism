---
apiVersion: callee.metalagman.dev/v1alpha1
kind: Router
spec:
  description: |
    Public Prism lifecycle Router. Selects exactly one declared Story or Epic
    graph from the first line of a host-generated route envelope. The envelope
    preserves the complete caller prompt for the selected graph. Explicit
    unknown, blank, or malformed routes fail closed because no default branch
    is declared; the Router never retries another child.
  route: '{{ regexFind "^ROUTE=(story|epic)(\\r?\\n|$)" .Input | trimPrefix "ROUTE=" }}'
  children:
    - ref: prism/story
      alias: story
      route: story
    - ref: prism/epic
      alias: epic
      route: epic
---
{{ .Prompt }}
