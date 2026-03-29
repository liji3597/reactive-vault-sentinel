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

yn() {
  if [ "$1" -eq 1 ]; then
    echo "YES"
  else
    echo "NO"
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
CALLBACK_TOPIC0="$(to_lower "$("${CAST_BIN}" keccak "Callback(uint256,address,uint64,bytes)")")"

if [[ ! "${SMOKE_TIMEOUT_SECONDS}" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMOKE_TIMEOUT_SECONDS must be a positive integer"
  exit 1
fi

if [[ ! "${SMOKE_POLL_INTERVAL}" =~ ^[1-9][0-9]*$ ]]; then
  echo "SMOKE_POLL_INTERVAL must be a positive integer"
  exit 1
fi

start_ts="$(date +%s)"
deadline_ts=$((start_ts + SMOKE_TIMEOUT_SECONDS))

lasna_start_block_resp="$(json_rpc "${REACTIVE_RPC_URL}" "eth_blockNumber" "[]")"
LASNA_START_BLOCK="$(extract_result_hex "${lasna_start_block_resp}")"
if [ -z "${LASNA_START_BLOCK}" ]; then
  echo "Failed to read Lasna start block"
  exit 1
fi

LASNA_START_BLOCK_DEC="$("${CAST_BIN}" to-dec "${LASNA_START_BLOCK}" 2>/dev/null || true)"
if [ -z "${LASNA_START_BLOCK_DEC}" ]; then
  echo "Failed to parse Lasna start block"
  exit 1
fi
LASNA_FROM_BLOCK="$("${CAST_BIN}" to-hex "$((LASNA_START_BLOCK_DEC + 1))" 2>/dev/null || true)"
if [ -z "${LASNA_FROM_BLOCK}" ]; then
  echo "Failed to compute Lasna from block"
  exit 1
fi
LASNA_FROM_BLOCK="$(to_lower "${LASNA_FROM_BLOCK}")"

callback_baseline_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${CALLBACK_TOPIC0}\"]}]" || true)"
callback_baseline_compact="$(compact_json "${callback_baseline_json:-}" | tr '[:upper:]' '[:lower:]')"

send_output="$("${CAST_BIN}" send "${MOCK_PRICE_FEED}" "setAnswer(int256)" "${SMOKE_ANSWER_VALUE}" --rpc-url "${SEPOLIA_RPC_URL}" "${SEPOLIA_SIGNER_ARGS[@]}" --async 2>&1)"
TX_HASH="$(printf '%s\n' "${send_output}" | grep -Eoi '0x[0-9a-fA-F]{64}' | head -n1 || true)"
if [ -z "${TX_HASH}" ]; then
  echo "Failed to capture tx hash from cast send output"
  echo "${send_output}"
  exit 1
fi
TX_HASH="$(to_lower "${TX_HASH}")"

sepolia_event_observed=0
callback_events_found=0

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

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 0 ]; then
    callback_logs_json="$(json_rpc "${REACTIVE_RPC_URL}" "eth_getLogs" "[{\"fromBlock\":\"${LASNA_FROM_BLOCK}\",\"toBlock\":\"latest\",\"address\":\"${VAULT_SENTINEL_REACTIVE}\",\"topics\":[\"${CALLBACK_TOPIC0}\"]}]" || true)"
    if [ -n "${callback_logs_json}" ]; then
      callback_logs_compact="$(compact_json "${callback_logs_json}" | tr '[:upper:]' '[:lower:]')"
      if [ "${callback_logs_compact}" != "${callback_baseline_compact}" ] && has_non_empty_result_array "${callback_logs_json}"; then
        callback_events_found=1
      fi
    fi
  fi

  if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ]; then
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

debt_hex_payload="${SENTINEL_DEBT_HEX#0x}"
if [[ -z "${debt_hex_payload}" || "${debt_hex_payload}" =~ ^0+$ ]]; then
  debt_is_zero=1
else
  debt_is_zero=0
fi

echo "==== Step11 Smoke Summary ===="
echo "TX_HASH: ${TX_HASH}"
echo "SEPOLIA_ANSWER_UPDATED_OBSERVED: $(yn "${sepolia_event_observed}")"
echo "LASNA_CALLBACK_EVENTS_FOUND: $(yn "${callback_events_found}")"
echo "SENTINEL_DEBT_HEX: ${SENTINEL_DEBT_HEX}"
echo "SENTINEL_DEBT_DEC: ${SENTINEL_DEBT_DEC}"

if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 1 ]; then
  echo "PASS: Step11 smoke verification succeeded."
  exit 0
fi

if [ "${sepolia_event_observed}" -eq 1 ] && [ "${callback_events_found}" -eq 0 ] && [ "${debt_is_zero}" -eq 1 ]; then
  echo "LIKELY_REACTIVE_INFRA_ISSUE"
  echo "FAIL: Step11 smoke verification failed."
  exit 1
fi

echo "FAIL: Step11 smoke verification failed."
exit 1
