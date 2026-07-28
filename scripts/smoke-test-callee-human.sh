#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

mode="all"
keep_temp=0
temp_dir=""
active_pid=""
active_fifo_fd=""

story_message=$'Story: update the Prism lifecycle ownership validator so it recognizes phase-local internal agents under prism/<phase>/* instead of expecting prism/workflows/*. Actor: repository maintainers running validation locally and in CI. Scope: only the lifecycle ownership validation logic and matching ownership metadata expectations for internal agent paths. Non-goals: do not change manual host lifecycle semantics, public phase IDs, or plugin manifests. Acceptance: 1) scripts/validate-lifecycle-ownership.sh passes when specify uses prism/specify/{loop,questions,extract,gate}, design uses prism/design/flow, human uses prism/human/{prompt,check}, apply uses prism/apply/loop, and verify uses prism/verify/review; 2) the validator no longer requires files under pack/callee/prism/workflows/ for those moved internal agents; 3) existing checks for public phase refs, assignee ownership, and manual phase references remain unchanged; 4) the change is limited to repository validation and lifecycle metadata expectations, not runtime behavior.'

usage() {
  cat <<'EOF'
Usage: scripts/smoke-test-callee-human.sh [questions|specify|all] [--keep-temp]

Runs PTY-backed Callee smoke tests for Prism Human steps:
- questions: verifies prism/specify/questions waits for operator input and returns it
- specify: verifies prism/phases/specify reaches the first clarification step,
  accepts a grounded reply, and resumes with normalizer visit=2
- all: runs both tests

Requires util-linux script(1). Uses callee when installed, otherwise falls back
to npx --yes @baldaworks/callee@0.18.0.
EOF
}

fail() {
  keep_temp=1
  echo "FAIL: $*" >&2
  exit 1
}

cleanup() {
  if [[ -n "${active_pid}" ]]; then
    kill "${active_pid}" >/dev/null 2>&1 || true
    wait "${active_pid}" >/dev/null 2>&1 || true
  fi
  if [[ -n "${active_fifo_fd}" ]]; then
    eval "exec ${active_fifo_fd}>&-"
    eval "exec ${active_fifo_fd}<&-"
  fi
  if [[ -n "${temp_dir}" && "${keep_temp}" -eq 0 ]]; then
    rm -rf "${temp_dir}"
  elif [[ -n "${temp_dir}" ]]; then
    echo "Kept temp files in ${temp_dir}"
  fi
}

trap cleanup EXIT

while (($# > 0)); do
  case "$1" in
    questions|specify|all)
      mode="$1"
      ;;
    --keep-temp)
      keep_temp=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      fail "unknown argument: $1"
      ;;
  esac
  shift
done

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "required command not found: $1"
}

require_cmd script
require_cmd mkfifo
require_cmd rg

if command -v callee >/dev/null 2>&1; then
  callee_cmd=(callee)
else
  require_cmd npx
  callee_cmd=(npx --yes @baldaworks/callee@0.18.0)
fi

temp_dir="$(mktemp -d "${TMPDIR:-/tmp}/prism-callee-smoke.XXXXXX")"

shell_join() {
  local joined=()
  local quoted=""
  for arg in "$@"; do
    printf -v quoted '%q' "$arg"
    joined+=("$quoted")
  done
  local old_ifs="${IFS}"
  IFS=' '
  printf '%s' "${joined[*]}"
  IFS="${old_ifs}"
}

wait_for_pattern() {
  local path="$1"
  local pattern="$2"
  local timeout_seconds="$3"
  local label="$4"
  local deadline=$((SECONDS + timeout_seconds))
  while (( SECONDS < deadline )); do
    if [[ -f "${path}" ]] && rg -q --fixed-strings "${pattern}" "${path}"; then
      echo "PASS: ${label}"
      return 0
    fi
    sleep 1
  done
  echo "Last diagnostics from ${path}:" >&2
  if [[ -f "${path}" ]]; then
    tail -40 "${path}" >&2
  else
    echo "(missing file)" >&2
  fi
  fail "${label}"
}

assert_file_contains() {
  local path="$1"
  local pattern="$2"
  local label="$3"
  if rg -q --fixed-strings "${pattern}" "${path}"; then
    echo "PASS: ${label}"
    return 0
  fi
  echo "Last diagnostics from ${path}:" >&2
  tail -40 "${path}" >&2 || true
  fail "${label}"
}

start_script_run() {
  local command_string="$1"
  local fifo_path="$2"
  exec {active_fifo_fd}<>"${fifo_path}"
  script -qefc "${command_string}" /dev/null <&"${active_fifo_fd}" &
  active_pid=$!
}

close_fifo_fd() {
  if [[ -n "${active_fifo_fd}" ]]; then
    eval "exec ${active_fifo_fd}>&-"
    eval "exec ${active_fifo_fd}<&-"
    active_fifo_fd=""
  fi
}

run_questions_smoke() {
  local run_dir="${temp_dir}/questions"
  local fifo_path="${run_dir}/stdin.fifo"
  local artifact_path="${run_dir}/artifact.txt"
  local diagnostics_path="${run_dir}/diagnostics.txt"
  local command_string=""

  mkdir -p "${run_dir}"
  mkfifo "${fifo_path}"

  command_string="$(shell_join "${callee_cmd[@]}" agent run prism/specify/questions --agent-root pack/callee --message "debug human repro")"
  command_string+=" > $(printf '%q' "${artifact_path}") 2> $(printf '%q' "${diagnostics_path}")"

  echo "Running questions smoke test..."
  start_script_run "${command_string}" "${fifo_path}"
  wait_for_pattern "${diagnostics_path}" "running agent id=prism/specify/questions kind=Human visit=1" 15 "questions enters Human prompt"
  printf '1. smoke-test clarification\n' >&"${active_fifo_fd}"
  wait "${active_pid}"
  active_pid=""
  close_fifo_fd

  assert_file_contains "${diagnostics_path}" "outcome=return status=completed visit=1" "questions Human returns successfully"
  assert_file_contains "${diagnostics_path}" "agent run finished agent_duration=" "questions run emits final metrics"
  if [[ "$(cat "${artifact_path}")" != "1. smoke-test clarification" ]]; then
    echo "Artifact contents:" >&2
    cat "${artifact_path}" >&2 || true
    fail "questions artifact preserves operator response"
  fi
  echo "PASS: questions artifact preserves operator response"
}

run_specify_smoke() {
  local run_dir="${temp_dir}/specify"
  local fifo_path="${run_dir}/stdin.fifo"
  local artifact_path="${run_dir}/artifact.txt"
  local diagnostics_path="${run_dir}/diagnostics.txt"
  local command_string=""

  mkdir -p "${run_dir}"
  mkfifo "${fifo_path}"

  command_string="$(shell_join "${callee_cmd[@]}" agent run prism/phases/specify --agent-root pack/callee --message "${story_message}")"
  command_string+=" > $(printf '%q' "${artifact_path}") 2> $(printf '%q' "${diagnostics_path}")"

  echo "Running specify smoke test..."
  start_script_run "${command_string}" "${fifo_path}"
  wait_for_pattern "${diagnostics_path}" "running agent id=clarifications kind=Human ref=prism/specify/questions visit=1" 300 "specify reaches first Human clarification"
  cat <<'EOF' >&"${active_fifo_fd}"
1. The canonical ownership metadata artifact is docs/lifecycle-ownership.json; update only story_phases[*].executor.internal_refs for the moved phase-local agents.
2. The non-regression baseline is the current validator behavior in scripts/validate-lifecycle-ownership.sh for public_ref, assignee ownership and accepted aliases, and manual_phase_reference checks; those pass/fail outcomes must remain unchanged.
3. CI parity is normative: the same scripts/validate-lifecycle-ownership.sh entrypoint, with no CI-only branch or alternate config, must pass unchanged locally and in CI for the same repo state.
EOF
  wait_for_pattern "${diagnostics_path}" "id=clarifications kind=Human outcome=return ref=prism/specify/questions status=completed visit=1" 30 "specify Human clarification returns successfully"
  wait_for_pattern "${diagnostics_path}" "running agent id=normalizer kind=Role ref=prism/roles/interviewer visit=2" 30 "specify resumes with normalizer visit=2 after Human reply"

  kill "${active_pid}" >/dev/null 2>&1 || true
  wait "${active_pid}" >/dev/null 2>&1 || true
  active_pid=""
  close_fifo_fd
}

case "${mode}" in
  questions)
    run_questions_smoke
    ;;
  specify)
    run_specify_smoke
    ;;
  all)
    run_questions_smoke
    run_specify_smoke
    ;;
esac

echo "Smoke tests completed successfully."
