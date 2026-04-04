#!/usr/bin/env bash
set -euo pipefail

SMOKE_ANSWER_VALUE="${SMOKE_ANSWER_VALUE:-150000000000}"
SMOKE_TIMEOUT_SECONDS="${SMOKE_TIMEOUT_SECONDS:-180}"
SMOKE_POLL_INTERVAL="${SMOKE_POLL_INTERVAL:-6}"

if [ "${1:-}" != "" ]; then
  SMOKE_ANSWER_VALUE="$1"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ENV_FILE="${ROOT_DIR}/contracts/.env"
SYSTEM_CONTRACT="0x0000000000000000000000000000000000fffFfF"

require_cmd() {
  local cmd="$1"
  command -v "${cmd}" >/dev/null 2>&1 || {
    echo "Missing required command: ${cmd}"
    exit 1
  }
}

require_var() {
  local name="$1"
  if [ -z "${!name:-}" ]; then
    echo "Missing required env var: ${name}"
    exit 1
  fi
}

load_env_file_strict() {
  local env_file="$1"
  local raw_line line key value line_no=0

  while IFS= read -r raw_line || [ -n "${raw_line}" ]; do
    line_no=$((line_no + 1))
    line="${raw_line%$'\r'}"

    if [ -z "${line}" ]; then
      continue
    fi
    case "${line}" in
      \#*) continue ;;
    esac

    if [[ ! "${line}" =~ ^[A-Za-z_][A-Za-z0-9_]*=.*$ ]]; then
      echo "Invalid env line ${line_no} in ${env_file}: ${line}"
      exit 1
    fi

    key="${line%%=*}"
    value="${line#*=}"
    printf -v "${key}" '%s' "${value}"
    export "${key}"
  done < "${env_file}"
}

to_lower() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]'
}

json_rpc() {
  local url="$1"
  local method="$2"
  local params="$3"
  curl -sS --fail \
    --retry 4 \
    --retry-delay 2 \
    --retry-all-errors \
    --connect-timeout 10 \
    --max-time 40 \
    -H "Content-Type: application/json" \
    --data "{\"jsonrpc\":\"2.0\",\"id\":1,\"method\":\"${method}\",\"params\":${params}}" \
    "${url}"
}

compact_json() {
  printf '%s' "$1" | tr -d '\n\r\t '
}

extract_result_hex() {
  printf '%s' "$1" | tr -d '\n\r' | sed -n 's/.*"result":[[:space:]]*"\(0x[0-9a-fA-F]*\)".*/\1/p'
}

has_non_empty_result_array() {
  local compact
  compact="$(compact_json "$1" | tr '[:upper:]' '[:lower:]')"
  [[ "$compact" == *"\"result\":["* ]] && [[ "$compact" != *"\"result\":[]"* ]]
}

normalize_bool_result() {
  local normalized
  normalized="$(printf '%s' "$1" | tr -d '\n\r\t ' | tr '[:upper:]' '[:lower:]')"
  case "${normalized}" in
    true|0x1) echo "true" ;;
    false|0x0) echo "false" ;;
    *) echo "unknown" ;;
  esac
}

yn() {
  if [ "$1" -eq 1 ]; then
    echo "YES"
  else
    echo "NO"
  fi
}

rpc_block_number_or_fail() {
  local label="$1"
  local url="$2"
  local resp block
  resp="$(json_rpc "${url}" "eth_blockNumber" "[]" 2>/dev/null || true)"
  block="$(extract_result_hex "${resp}")"
  block="$(to_lower "${block:-}")"
  if [ -z "${block}" ]; then
    echo "PRECHECK_${label}_RPC_UNUSABLE: eth_blockNumber failed"
    exit 1
  fi
  printf '%s' "${block}"
}

read_lasna_bool_state() {
  local signature="$1"
  local raw
  raw="$("${CAST_BIN}" call "${VAULT_SENTINEL_REACTIVE}" "${signature}" --rpc-url "${REACTIVE_RPC_URL}" 2>/dev/null || true)"
  normalize_bool_result "${raw}"
}

read_lasna_subscribers() {
  local chain_id="$1"
  local source_contract="$2"
  local topic0="$3"
  local raw

  raw="$("${CAST_BIN}" call "${SYSTEM_CONTRACT}" \
    "findSubscribers(uint256,address,uint256,uint256,uint256,uint256)(uint256,address[])" \
    "${chain_id}" "${source_contract}" "${topic0}" 0 0 0 \
    --rpc-url "${REACTIVE_RPC_URL}" 2>/dev/null || true)"
  printf '%s' "${raw}"
}

subscriber_list_contains() {
  local subscribers="$1"
  local subscriber="$2"
  local normalized needle list_only

  normalized="$(printf '%s' "${subscribers}" | tr '[:upper:]' '[:lower:]' | tr -d '\r\t ')"
  needle="$(to_lower "${subscriber}")"
  if [ -z "${normalized}" ]; then
    echo "unknown"
    return
  fi

  list_only="$(printf '%s' "${normalized}" | tr -d '\n' | sed -n 's/.*\(\[[^]]*\]\).*/\1/p')"
  if [ -z "${list_only}" ]; then
    echo "unknown"
    return
  fi

  if [[ "${list_only}" == *"${needle}"* ]]; then
    echo "true"
  else
    echo "false"
  fi
}

require_cmd curl

CAST_BIN="$(command -v cast || true)"
if [ -z "${CAST_BIN}" ] && [ -x "${HOME}/.foundry/bin/cast" ]; then
  CAST_BIN="${HOME}/.foundry/bin/cast"
fi
if [ -z "${CAST_BIN}" ] && [ -n "${USERPROFILE:-}" ] && [ -x "${USERPROFILE}/.foundry/bin/cast.exe" ]; then
  CAST_BIN="${USERPROFILE}/.foundry/bin/cast.exe"
fi
if [ -z "${CAST_BIN}" ]; then
  echo "Missing cast binary in PATH and fallback locations"
  exit 1
fi

if [ ! -f "${ENV_FILE}" ]; then
  echo "Missing env file: ${ENV_FILE}"
  exit 1
fi

load_env_file_strict "${ENV_FILE}"

require_var SEPOLIA_RPC_URL
require_var REACTIVE_RPC_URL
require_var MOCK_PRICE_FEED
require_var VAULT_SENTINEL_REACTIVE

BASE_EXECUTION_MONITORING=0
if [ -n "${BASE_SEPOLIA_RPC_URL:-}" ] && [ -n "${VAULT_EXECUTION:-}" ]; then
  BASE_EXECUTION_MONITORING=1
fi

SEPOLIA_SIGNER_ARGS=()
if [ -n "${SEPOLIA_KEYSTORE:-}" ]; then
  SEPOLIA_SIGNER_ARGS+=(--keystore "${SEPOLIA_KEYSTORE}")
  if [ -n "${SEPOLIA_KEYSTORE_PASSWORD_FILE:-}" ]; then
    SEPOLIA_SIGNER_ARGS+=(--password-file "${SEPOLIA_KEYSTORE_PASSWORD_FILE}")
  fi
elif [ -n "${SEPOLIA_KEYSTORE_ACCOUNT:-}" ]; then
  SEPOLIA_SIGNER_ARGS+=(--account "${SEPOLIA_KEYSTORE_ACCOUNT}")
  if [ -n "${SEPOLIA_KEYSTORE_PASSWORD_FILE:-}" ]; then
    SEPOLIA_SIGNER_ARGS+=(--password-file "${SEPOLIA_KEYSTORE_PASSWORD_FILE}")
  fi
else
  echo "Missing signer config: set SEPOLIA_KEYSTORE or SEPOLIA_KEYSTORE_ACCOUNT. Private-key argv mode is disabled for security."
  exit 1
fi

MOCK_PRICE_FEED="$(to_lower "${MOCK_PRICE_FEED}")"
VAULT_SENTINEL_REACTIVE="$(to_lower "${VAULT_SENTINEL_REACTIVE}")"
SYSTEM_CONTRACT="$(to_lower "${SYSTEM_CONTRACT}")"

ANSWER_UPDATED_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "AnswerUpdated(int256,uint256,uint256)")")"
BALANCE_CHANGED_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "BalanceChanged(address,address,uint256,uint256)")")"
CALLBACK_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "Callback(uint256,address,uint64,bytes)")")"
RULE_TRIGGERED_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "RuleTriggered(uint256,uint256,uint256)")")"
EXECUTION_SUCCEEDED_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "ExecutionSucceeded(uint256,address,bytes)")")"

if [ "${BASE_EXECUTION_MONITORING}" -eq 1 ]; then
  VAULT_EXECUTION="$(to_lower "${VAULT_EXECUTION}")"
fi

if [[ ! "${SMOKE_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMOKE_TIMEOUT_SECONDS must be a positive integer"
  exit 1
fi

if [[ ! "${SMOKE_POLL_INTERVAL}" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMOKE_POLL_INTERVAL must be a positive integer"
  exit 1
fi

echo "==== Preflight ===="
SEPOLIA_START_BLOCK="$(rpc_block_number_or_fail "SEPOLIA" "${SEPOLIA_RPC_URL}")"
echo "PRECHECK_SEPOLIA_BLOCK: ${SEPOLIA_START_BLOCK}"

BASE_START_BLOCK=""
if [ "${BASE_EXECUTION_MONITORING}" -eq 1 ]; then
  BASE_START_BLOCK="$(rpc_block_number_or_fail "BASE" "${BASE_SEPOLIA_RPC_URL}")"
  echo "PRECHECK_BASE_BLOCK: ${BASE_START_BLOCK}"
fi

LASNA_START_BLOCK="$(rpc_block_number_or_fail "REACTIVE" "${REACTIVE_RPC_URL}")"
echo "PRECHECK_REACTIVE_BLOCK: ${LASNA_START_BLOCK}"

precheck_paused_state="$(read_lasna_bool_state "isSentinelPaused()(bool)")"
precheck_default_subs_state="$(read_lasna_bool_state "defaultSubscriptionsInitialized()(bool)")"
echo "PRECHECK_LASNA_PAUSED_STATE: ${precheck_paused_state}"
echo "PRECHECK_LASNA_DEFAULT_SUBSCRIPTIONS_INITIALIZED: ${precheck_default_subs_state}"

precheck_subscription_match_price="unknown"
precheck_subscription_match_balance="unknown"
sepolia_chain_id_for_query="${SEPOLIA_CHAIN_ID:-11155111}"

price_subscribers_raw="$(read_lasna_subscribers "${sepolia_chain_id_for_query}" "${MOCK_PRICE_FEED}" "${ANSWER_UPDATED_TOPIC0}")"
precheck_subscription_match_price="$(subscriber_list_contains "${price_subscribers_raw}" "${VAULT_SENTINEL_REACTIVE}")"
echo "PRECHECK_LASNA_SUB_MATCH_PRICE_ANSWER_UPDATED: ${precheck_subscription_match_price}"

if [ -n "${BALANCE_MONITOR:-}" ]; then
  BALANCE_MONITOR="$(to_lower "${BALANCE_MONITOR}")"
  balance_subscribers_raw="$(read_lasna_subscribers "${sepolia_chain_id_for_query}" "${BALANCE_MONITOR}" "${BALANCE_CHANGED_TOPIC0}")"
  precheck_subscription_match_balance="$(subscriber_list_contains "${balance_subscribers_raw}" "${VAULT_SENTINEL_REACTIVE}")"
fi
echo "PRECHECK_LASNA_SUB_MATCH_BALANCE_CHANGED: ${precheck_subscription_match_balance}"

start_ts="$(date +%s)"
deadline_ts=$((start_ts + SMOKE_TIMEOUT_SECONDS))

LASNA_START_BLOCK_DEC="$("${CAST_BIN}" to-dec "${LASNA_START_BLOCK}" 2>/dev/null || true)"
if [ -z "${LASNA_START_BLOCK_DEC}" ]; then
  echo "PRECHECK_REACTIVE_RPC_UNUSABLE: invalid eth_blockNumber result ${LASNA_START_BLOCK}"
  exit 1
fi
LASNA_FROM_BLOCK="$("${CAST_BIN}" to-hex "$((LASNA_START_BLOCK_DEC + 1))" 2>/dev/null || true)"
if [ -z "${LASNA_FROM_BLOCK}" ]; then
  echo "PRECHECK_REACTIVE_RPC_UNUSABLE: failed to compute fromBlock"
  exit 1
fi
LASNA_FROM_BLOCK="$(to_lower "${LASNA_FROM_BLOCK}")"

callback_baseline_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${CALLBACK_TOPIC0}\"]}]" || true)"
callback_baseline_compact="$(compact_json "${callback_baseline_json:-}" | tr '[:upper:]' '[:lower:]')"

rule_triggered_baseline_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${RULE_TRIGGERED_TOPIC0}\"]}]" || true)"
rule_triggered_baseline_compact="$(compact_json "${rule_triggered_baseline_json:-}" | tr '[:upper:]' '[:lower:]')"

BASE_FROM_BLOCK=""
if [ "${BASE_EXECUTION_MONITORING}" -eq 1 ]; then
  BASE_START_DEC="$("${CAST_BIN}" to-dec "${BASE_START_BLOCK}" 2>/dev/null || true)"
  if [ -z "${BASE_START_DEC}" ]; then
    echo "PRECHECK_BASE_RPC_UNUSABLE: invalid eth_blockNumber result ${BASE_START_BLOCK}"
    exit 1
  fi
  BASE_FROM_BLOCK="$("${CAST_BIN}" to-hex "$((BASE_START_DEC + 1))" 2>/dev/null || true)"
  if [ -z "${BASE_FROM_BLOCK}" ]; then
    echo "PRECHECK_BASE_RPC_UNUSABLE: failed to compute fromBlock"
    exit 1
  fi
  BASE_FROM_BLOCK="$(to_lower "${BASE_FROM_BLOCK:-}")"
fi

send_output="$("${CAST_BIN}" send "${MOCK_PRICE_FEED}" "setAnswer(int256)" "${SMOKE_ANSWER_VALUE}" --rpc-url "${SEPOLIA_RPC_URL}" "${SEPOLIA_SIGNER_ARGS[@]}" --async 2>&1)"
TX_HASH="$(printf '%s\n' "${send_output}" | grep -Eoi '0x[0-9a-fA-F]{64}' | head -n1 || true)"
if [ -z "${TX_HASH}" ]; then
  echo "Failed to capture tx hash from cast send output"
  echo "${send_output}"
  exit 1
fi
TX_HASH="$(to_lower "${TX_HASH}")"

sepolia_event_observed=0
rule_triggered_events_found=0
callback_events_found=0
base_execution_found=0
BASE_FROM_BLOCK_AFTER_CALLBACK=""

while [ "$(date +%s)" -le "${deadline_ts}" ]; do
  if [ "${sepolia_event_observed}" -eq 0 ]; then
    receipt_json="$(json_rpc "${SEPOLIA_RPC_URL}" "eth_getTransactionReceipt" "[\"${TX_HASH}\"]" || true)"
    if [ -n "${receipt_json}" ]; then
      receipt_compact="$(compact_json "${receipt_json}" | tr '[:upper:]' '[:lower:]')"
      if [[ "${receipt_compact}" != *"\"result\":null"* ]] && [[ "${receipt_compact}" == *"${ANSWER_UPDATED_TOPIC0}"* ]]; then
        sepolia_event_observed=1
      fi
    fi
  fi

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${rule_triggered_events_found}" -eq 0 ]; then
    rule_triggered_logs_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${RULE_TRIGGERED_TOPIC0}\"]}]" || true)"
    if [ -n "${rule_triggered_logs_json}" ]; then
      rule_triggered_logs_compact="$(compact_json "${rule_triggered_logs_json}" | tr '[:upper:]' '[:lower:]')"
      if [ "${rule_triggered_logs_compact}" != "${rule_triggered_baseline_compact}" ] && has_non_empty_result_array "${rule_triggered_logs_json}"; then
        rule_triggered_events_found=1
      fi
    fi
  fi

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 0 ]; then
    callback_logs_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${CALLBACK_TOPIC0}\"]}]" || true)"
    if [ -n "${callback_logs_json}" ]; then
      callback_logs_compact="$(compact_json "${callback_logs_json}" | tr '[:upper:]' '[:lower:]')"
      if [ "${callback_logs_compact}" != "${callback_baseline_compact}" ] && has_non_empty_result_array "${callback_logs_json}"; then
        callback_events_found=1
        if [ "${BASE_EXECUTION_MONITORING}" -eq 1 ] && [ -n "${BASE_FROM_BLOCK}" ] && [ -z "${BASE_FROM_BLOCK_AFTER_CALLBACK}" ]; then
          base_anchor_json="$(json_rpc "${BASE_SEPOLIA_RPC_URL}" "eth_blockNumber" "[]" || true)"
          base_anchor_hex="$(to_lower "$(extract_result_hex "${base_anchor_json:-}")")"
          if [ -n "${base_anchor_hex}" ]; then
            base_anchor_dec="$("${CAST_BIN}" to-dec "${base_anchor_hex}" 2>/dev/null || true)"
            if [ -n "${base_anchor_dec}" ]; then
              base_after_callback="$("${CAST_BIN}" to-hex "$((base_anchor_dec + 1))" 2>/dev/null || true)"
              BASE_FROM_BLOCK_AFTER_CALLBACK="$(to_lower "${base_after_callback:-}")"
            fi
          fi
        fi
      fi
    fi
  fi

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ] && [ "${BASE_EXECUTION_MONITORING}" -eq 1 ] && [ "${base_execution_found}" -eq 0 ] && [ -n "${BASE_FROM_BLOCK_AFTER_CALLBACK}" ]; then
    exec_logs_json="$(json_rpc "${BASE_SEPOLIA_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${BASE_FROM_BLOCK_AFTER_CALLBACK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_EXECUTION}\",\"topics\":[\"${EXECUTION_SUCCEEDED_TOPIC0}\"]}]" || true)"
    if [ -n "${exec_logs_json}" ] && has_non_empty_result_array "${exec_logs_json}"; then
      base_execution_found=1
    fi
  fi

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ] && [ "${base_execution_found}" -eq 1 ]; then
    break
  fi

  sleep "${SMOKE_POLL_INTERVAL}"
done

sentinel_no0x="${VAULT_SENTINEL_REACTIVE#0x}"
sentinel_padded="$(printf "%064s" "${sentinel_no0x}" | tr ' ' '0')"
debt_calldata="0x9b6c56ec${sentinel_padded}"
debt_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_call" "[{\"to\":\"${SYSTEM_CONTRACT}\",\"data\":\"${debt_calldata}\"},\"latest\"]" || true)"
SENTINEL_DEBT_HEX="$(extract_result_hex "${debt_json}")"
if [ -z "${SENTINEL_DEBT_HEX}" ]; then
  SENTINEL_DEBT_HEX="0x0"
fi
SENTINEL_DEBT_HEX="$(to_lower "${SENTINEL_DEBT_HEX}")"
SENTINEL_DEBT_DEC="$("${CAST_BIN}" to-dec "${SENTINEL_DEBT_HEX}" 2>/dev/null || echo "0")"

sentinel_paused_raw="$("${CAST_BIN}" call "${VAULT_SENTINEL_REACTIVE}" "isSentinelPaused()(bool)" --rpc-url "${REACTIVE_RPC_URL}" 2>/dev/null || true)"
sentinel_paused_state="$(normalize_bool_result "${sentinel_paused_raw}")"
default_subs_raw="$("${CAST_BIN}" call "${VAULT_SENTINEL_REACTIVE}" "defaultSubscriptionsInitialized()(bool)" --rpc-url "${REACTIVE_RPC_URL}" 2>/dev/null || true)"
default_subs_state="$(normalize_bool_result "${default_subs_raw}")"

debt_hex_payload="${SENTINEL_DEBT_HEX#0x}"
if [[ -z "${debt_hex_payload}" || "${debt_hex_payload}" =~ ^0+$ ]]; then
  debt_is_zero=1
else
  debt_is_zero=0
fi

echo "==== Step11 Smoke Summary ===="
echo "TX_HASH: ${TX_HASH}"
echo "SEPOLIA_ANSWER_UPDATED_OBSERVED: $(yn "${sepolia_event_observed}")"
echo "BASE_EXECUTION_MONITOR_CONFIGURED: $(yn "${BASE_EXECUTION_MONITORING}")"
echo "LASNA_RULE_TRIGGERED_FOUND: $(yn "${rule_triggered_events_found}")"
echo "LASNA_CALLBACK_EVENTS_FOUND: $(yn "${callback_events_found}")"
echo "BASE_EXECUTION_SUCCEEDED_FOUND: $(yn "${base_execution_found}")"
echo "SENTINEL_PAUSED_STATE: ${sentinel_paused_state}"
echo "DEFAULT_SUBSCRIPTIONS_INITIALIZED: ${default_subs_state}"
echo "SENTINEL_DEBT_HEX: ${SENTINEL_DEBT_HEX}"
echo "SENTINEL_DEBT_DEC: ${SENTINEL_DEBT_DEC}"

if [ "${debt_is_zero}" -eq 0 ]; then
  echo "DEBT_WARNING: sentinel has unpaid debt (${SENTINEL_DEBT_DEC} wei). Run (secure signer): cast send ${VAULT_SENTINEL_REACTIVE} 'coverDebt()' --rpc-url ${REACTIVE_RPC_URL} --keystore <REACTIVE_KEYSTORE> [--password-file <REACTIVE_KEYSTORE_PASSWORD_FILE>] (or --account <REACTIVE_KEYSTORE_ACCOUNT>)."
fi

if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ] && [ "${base_execution_found}" -eq 1 ]; then
  echo "PASS: Step11 smoke verification succeeded."
  exit 0
fi

if [ "${BASE_EXECUTION_MONITORING}" -eq 0 ]; then
  echo "DIAGNOSIS: BASE_SEPOLIA_EXECUTION_MONITOR_NOT_CONFIGURED."
fi

if [ "${debt_is_zero}" -eq 0 ] || [ "${sentinel_paused_state}" = "true" ]; then
  echo "DIAGNOSIS: CONTRACT_INACTIVE_OR_UNPAID_DEBT (debt or paused symptom)."
fi

if [ "${sepolia_event_observed}" -eq 1 ] && [ "${rule_triggered_events_found}" -eq 0 ] && [ "${callback_events_found}" -eq 0 ]; then
  echo "DIAGNOSIS: SOURCE_EVENT_OBSERVED_BUT_NO_REACTIVE_RULETRIGGERED_OR_CALLBACK."
  if [ "${precheck_subscription_match_price}" = "true" ]; then
    echo "DIAGNOSIS: REACTIVE_DELIVERY_FAILURE_AFTER_SUBSCRIPTION_MATCH."
  fi
  if [ "${default_subs_state}" = "false" ]; then
    echo "DIAGNOSIS: SUBSCRIPTION_INITIALIZATION_LIKELY_FAILED_ON_LASNA."
  elif [ "${debt_is_zero}" -eq 1 ] && [ "${sentinel_paused_state}" = "false" ] && [ "${default_subs_state}" = "true" ]; then
    echo "DIAGNOSIS: LIKELY_REACTIVE_INFRA_ISSUE (no reactive events, debt clear, not paused)."
  fi
fi

if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ] && [ "${base_execution_found}" -eq 0 ]; then
  echo "DIAGNOSIS: LASNA_CALLBACK_OBSERVED_BUT_BASE_EXECUTION_MISSING."
  echo "DIAGNOSIS: CHECK_RVM_ID_AUTH_AND_BASE_CALLBACK_DELIVERY."
fi

echo "FAIL: Step11 smoke verification failed."
exit 1
