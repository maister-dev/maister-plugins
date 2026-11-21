#!/usr/bin/env bash
# env-e2e lifecycle script (SSOT — spec §6). Owns the ephemeral compose env
# ATOMICALLY: preflight → config → up → seed → test → capture → result, with
# teardown guaranteed by the trap on EVERY exit path (success, failure, error,
# group-TERM/INT). Exit-0 protocol (FR-5): exit 0 whenever the runner service
# executed — the verdict travels in the result JSON; non-zero exit is reserved
# for the config|env failure classes (docker CLI codes 125/126/127 from the
# runner invocation are env class: the suite did not execute).
# Bash 3.2-compatible (macOS web tier).
#
# Usage (engine): bash "$MAISTER_FLOW_DIR/scripts/run-e2e.sh" "maister-run-<runId>"
# Env (engine):   MAISTER_OUTPUT_FILE (armed by output.result), MAISTER_FLOW_DIR
# Debug:          MAISTER_E2E_DEBUG=1 → set -x
set -euo pipefail

if [[ "${MAISTER_E2E_DEBUG:-}" == "1" ]]; then set -x; fi

# --- logging + failure classes (NFR-2, spec §6) ----------------------------

phase() { printf '[env-e2e:%s] %s\n' "$1" "$2"; }

# config class: wrong invocation/config — nothing was created, rework can't fix.
die_config() {
  printf '[env-e2e:config] %s\n' "$1" >&2
  exit 1
}

# env class: docker/infra failed — evidence best-effort, teardown guaranteed.
die_env() {
  printf '[env-e2e:%s] %s\n' "$1" "$2" >&2
  exit 1
}

# --- sanitized child env (FR-10; defense-in-depth over platform ADR-153) ---
# Every docker invocation runs under env -i with only PATH/HOME/the compose
# project name/E2E_ENV — web-tier values never reach compose interpolation or
# containers. DOCKER_HOST is deliberately not propagated (use docker context).

dockerc() {
  env -i PATH="$PATH" HOME="$HOME" COMPOSE_PROJECT_NAME="$PROJECT_NAME" \
    ${E2E_ENV[@]+"${E2E_ENV[@]}"} docker "$@"
}

# --- teardown trap (FR-9) — armed BEFORE any compose call ------------------
# Group-TERM tolerance: the trap spawns FRESH docker processes (outside the
# signal batch); the engine's 30 s SIGKILL grace bounds it — down --timeout 10
# fits. `down -p` alone (no -f) finds resources by project label, so teardown
# works regardless of how far config got. One-off `run` containers may survive
# a killed CLI, so labeled containers are force-removed first.

UP_STARTED=0
CAPTURE_DONE=0

teardown() {
  phase down "tearing down compose project $PROJECT_NAME"
  local ids
  ids="$(dockerc ps -aq --filter "label=com.docker.compose.project=$PROJECT_NAME" 2>/dev/null || true)"
  if [[ -n "$ids" ]]; then
    # shellcheck disable=SC2086
    dockerc rm -f $ids >/dev/null 2>&1 || true
  fi
  dockerc compose -p "$PROJECT_NAME" down --volumes --remove-orphans --timeout 10 >/dev/null 2>&1 || true
}

on_exit() {
  local code=$?
  trap - EXIT TERM INT
  if [[ "$UP_STARTED" == "1" && "$CAPTURE_DONE" != "1" ]]; then
    capture_evidence best-effort || true
  fi
  teardown
  exit "$code"
}

# --- evidence capture (FR-4) -----------------------------------------------
# ALWAYS both files on exit-0 paths; best-effort from the trap on env
# failures. Runs BEFORE teardown so compose logs still see the containers.

capture_evidence() {
  phase capture "collecting evidence into $RUN_DIR (${1:-final})"
  local staging="$WORK_DIR/report"

  rm -rf "$staging"
  mkdir -p "$staging"
  if [[ -d playwright-report ]]; then
    cp -R playwright-report "$staging/"
  else
    printf 'playwright-report/ was not produced by the runner on this attempt\n' \
      > "$staging/MISSING-REPORT.txt"
  fi
  if [[ -d test-results ]]; then cp -R test-results "$staging/"; fi
  if [[ -f "$TEST_LOG" ]]; then cp "$TEST_LOG" "$staging/test-output.log"; fi
  tar -czf "$RUN_DIR/e2e-report.tar.gz" -C "$staging" .
  dockerc compose "${COMPOSE_ARGS[@]}" logs --no-color \
    > "$RUN_DIR/e2e-compose-logs.txt" 2>&1 || : > "$RUN_DIR/e2e-compose-logs.txt"
  CAPTURE_DONE=1
}

# --- result JSON (spec §4) -------------------------------------------------

json_escape() {
  awk 'BEGIN{ORS=""} {
    gsub(/\\/, "\\\\"); gsub(/"/, "\\\""); gsub(/\t/, "\\t"); gsub(/\r/, "\\r");
    if (NR > 1) printf "\\n";
    printf "%s", $0
  }'
}

# Reporters emit ANSI cursor/color codes even without a TTY; JSON.parse
# rejects RAW control chars in strings (the engine hard-fails the attempt
# with CONFIG on invalid JSON — found live on the red path). Strip CSI
# sequences, then delete every remaining control char except \t \n \r
# (json_escape encodes those). BSD sed has no \x escapes — splice a literal
# ESC via printf.
strip_ansi() {
  sed "s/$(printf '\033')\[[0-9;]*[A-Za-z]//g" | tr -d '\000-\010\013\014\016-\037'
}

write_result() { # $1 = verdict
  local verdict="$1" summary_raw comments_raw

  summary_raw="$(strip_ansi < "$TEST_LOG" 2>/dev/null | grep -E '^[[:space:]]*[0-9]+ (passed|failed|skipped|flaky|did not run)' | tail -4 | tr '\n' ' ' | sed 's/  */ /g; s/ $//' || true)"
  if [[ -z "$summary_raw" ]]; then
    summary_raw="runner service exited with code $TEST_EXIT"
  fi
  if [[ "$verdict" == "fail" ]]; then
    comments_raw="$(tail -40 "$TEST_LOG" 2>/dev/null | strip_ansi || true)"
    if [[ -z "$comments_raw" ]]; then
      comments_raw="runner failed with exit code $TEST_EXIT and produced no output"
    fi
  else
    comments_raw="all green: $summary_raw"
  fi

  phase result "writing result JSON (verdict=$verdict)"
  printf '{"verdict":"%s","summary":"%s","e2e_comments":"%s"}\n' \
    "$verdict" \
    "$(printf '%s' "$summary_raw" | json_escape)" \
    "$(printf '%s' "$comments_raw" | json_escape)" \
    > "$MAISTER_OUTPUT_FILE"

  if [[ "$verdict" == "fail" ]]; then
    # FR-6 companion: the failing block is ALSO the last thing on stdout for
    # the human step log (the injection channel stays the JSON field).
    phase result "failing summary (last 40 runner lines):"
    printf '%s\n' "$comments_raw"
  fi
}

# === phase 1: init =========================================================

PROJECT_NAME="${1:-}"
if [[ -z "$PROJECT_NAME" ]]; then
  die_config "missing argument: compose project name (usage: run-e2e.sh maister-run-<runId>)"
fi
case "$PROJECT_NAME" in
  *[!a-zA-Z0-9_-]* | [!a-zA-Z0-9]*)
    die_config "invalid compose project name \"$PROJECT_NAME\" (expected ^[A-Za-z0-9][A-Za-z0-9_-]*$)"
    ;;
esac
if [[ -z "${MAISTER_OUTPUT_FILE:-}" ]]; then
  die_config "MAISTER_OUTPUT_FILE is not set — the e2e node must declare output.result (engine arms the transport)"
fi

RUN_DIR="$(cd "$(dirname "$MAISTER_OUTPUT_FILE")" && pwd)"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/env-e2e-XXXXXX")"
TEST_LOG="$WORK_DIR/test-output.log"
TEST_EXIT=0
COMPOSE_ARGS=(-p "$PROJECT_NAME")

phase init "project=$PROJECT_NAME run_dir=$RUN_DIR"
trap on_exit EXIT
trap 'exit 143' TERM
trap 'exit 130' INT

# === phase 2: preflight ====================================================
# Before config: a docker-less host must surface as an env-class preflight
# failure, not as a confusing compose-config error from the config phase.

phase preflight "docker daemon + compose v2"
dockerc info >/dev/null 2>&1 \
  || die_env preflight "docker daemon unreachable from the web tier (cli/check nodes run there) — start Docker or fix the docker context"
dockerc compose version >/dev/null 2>&1 \
  || die_env preflight "docker compose v2 unavailable on the web tier"

# === phase 3: config (spec §5) =============================================

phase config "loading .maister-env-e2e.sh from $(pwd)"
if [[ ! -f .maister-env-e2e.sh ]]; then
  die_config ".maister-env-e2e.sh not found in $(pwd) — create it at the repo root (see the env-e2e package README)"
fi
# shellcheck disable=SC1091
source ./.maister-env-e2e.sh

if [[ -z "${E2E_COMPOSE_FILES[*]+set}" || "${#E2E_COMPOSE_FILES[@]}" -eq 0 ]]; then
  die_config "E2E_COMPOSE_FILES must be set to a non-empty bash array of compose files"
fi
if [[ -z "${E2E_RUNNER_SERVICE:-}" ]]; then
  die_config "E2E_RUNNER_SERVICE must be set to the compose service (profile \"e2e\") that runs the tests"
fi
E2E_WAIT_TIMEOUT="${E2E_WAIT_TIMEOUT:-120}"

E2E_COMPOSE_STR="docker compose -p $PROJECT_NAME"
for f in "${E2E_COMPOSE_FILES[@]}"; do
  if [[ ! -f "$f" ]]; then
    die_config "compose file listed in E2E_COMPOSE_FILES not found: $f (repo-relative, cwd $(pwd))"
  fi
  COMPOSE_ARGS+=(-f "$f")
  E2E_COMPOSE_STR="$E2E_COMPOSE_STR -f $f"
done

# Runner-service pre-validation (daemon-less `compose config`): turns a typo'd
# service into a config-class failure BEFORE any resource exists.
SERVICES="$(dockerc compose "${COMPOSE_ARGS[@]}" --profile e2e config --services 2>&1)" \
  || die_config "compose config failed for E2E_COMPOSE_FILES (${E2E_COMPOSE_FILES[*]}): $SERVICES"
if ! printf '%s\n' "$SERVICES" | grep -qx "$E2E_RUNNER_SERVICE"; then
  die_config "E2E_RUNNER_SERVICE \"$E2E_RUNNER_SERVICE\" is not a service of the composed files (available: $(printf '%s' "$SERVICES" | tr '\n' ' '))"
fi

# Isolation enforcement (FR-2/FR-3): zero published ports, no pinned container
# names, no host networking — collision-freedom is an invariant of the resolved
# model, not a trusted-author convention. Matched lines are reported verbatim.
RESOLVED_CONFIG="$(dockerc compose "${COMPOSE_ARGS[@]}" --profile e2e config 2>/dev/null || true)"
ISOLATION_VIOLATIONS="$(printf '%s\n' "$RESOLVED_CONFIG" | grep -nE '^[[:space:]]+(published:|container_name:|network_mode:[[:space:]]*host)' || true)"
if [[ -n "$ISOLATION_VIOLATIONS" ]]; then
  die_config "resolved compose model violates env-e2e isolation (published ports / container_name / host network are not allowed): $(printf '%s' "$ISOLATION_VIOLATIONS" | tr '\n' '; ')"
fi

RUN_ENV_FLAGS=()
if [[ -n "${E2E_ENV[*]+set}" ]]; then
  for pair in "${E2E_ENV[@]}"; do
    RUN_ENV_FLAGS+=(-e "$pair")
  done
fi

phase config "files=(${E2E_COMPOSE_FILES[*]}) runner=$E2E_RUNNER_SERVICE wait_timeout=${E2E_WAIT_TIMEOUT}s"

# === phase 4: up ===========================================================

phase up "compose up -d --wait (timeout ${E2E_WAIT_TIMEOUT}s)"
UP_STARTED=1
dockerc compose "${COMPOSE_ARGS[@]}" up -d --wait --wait-timeout "$E2E_WAIT_TIMEOUT" \
  || die_env up "compose up --wait failed or timed out after ${E2E_WAIT_TIMEOUT}s — check service healthchecks and E2E_WAIT_TIMEOUT (compose logs are captured as evidence)"

# === phase 5: seed =========================================================

if [[ -n "${E2E_SEED_COMMAND:-}" ]]; then
  phase seed "running E2E_SEED_COMMAND"
  env -i PATH="$PATH" HOME="$HOME" COMPOSE_PROJECT_NAME="$PROJECT_NAME" \
    E2E_COMPOSE="$E2E_COMPOSE_STR" ${E2E_ENV[@]+"${E2E_ENV[@]}"} \
    bash -c "$E2E_SEED_COMMAND" \
    || die_env seed "E2E_SEED_COMMAND failed — fix the seed hook or the stack it targets"
fi

# === phase 6: test (never fails the script — exit code becomes the verdict) =

phase test "compose run --rm $E2E_RUNNER_SERVICE"
set +e
dockerc compose "${COMPOSE_ARGS[@]}" --profile e2e run --rm -T \
  ${RUN_ENV_FLAGS[@]+"${RUN_ENV_FLAGS[@]}"} "$E2E_RUNNER_SERVICE" 2>&1 | tee "$TEST_LOG"
TEST_EXIT="${PIPESTATUS[0]}"
set -e
phase test "runner exited with code $TEST_EXIT"

# Docker-level failure classifier (FR-5): 125/126/127 are the docker CLI's
# reserved could-not-run codes, and docker COMPOSE flattens CLI-level errors
# to exit 1 while ending its output with an `Error response from daemon:`
# line — in both shapes the suite did NOT run, so this is env class, never a
# verdict. Residuals (documented, spec §8): a project wrapper itself exiting
# 126/127, or a failing suite whose LAST output line is a daemon error.
case "$TEST_EXIT" in
  125 | 126 | 127)
    die_env test "runner service did not execute (docker exit $TEST_EXIT — daemon/image/entrypoint failure); compose logs are in the evidence"
    ;;
esac
if [[ "$TEST_EXIT" -ne 0 ]] && tail -3 "$TEST_LOG" | grep -q 'Error response from daemon'; then
  die_env test "runner service did not execute (docker daemon error with exit $TEST_EXIT); compose logs are in the evidence"
fi

# === phase 7: capture (ALWAYS both files before the verdict) ===============

capture_evidence

# === phase 8: result + exit 0 (teardown runs from the trap) ================

if [[ "$TEST_EXIT" -eq 0 ]]; then
  write_result pass
else
  write_result fail
fi

exit 0
