#!/usr/bin/env bash
#
# nv29 ONLY. Deploys the FIP-0118 Solstice contracts (ServiceRewardsActor and
# StreamWeightActor, implementation + ERC1967 proxy each) to butterflynet after
# a reset, and checks they land at the addresses baked into Lotus'
# build/buildconstants/params_butterfly.go. The Solstice migration hard-fails
# at the upgrade epoch if those contracts are missing, so run this between
# the reset and UpgradeSolsticeHeight.
#
# Safe to delete once nv29 has shipped.
#
# What it does:
#   1. Reads the expected SRA/SWA proxy addresses, the deployer address and
#      the (throwaway, public) deployer key out of params_butterfly.go.
#   2. Funds the deployer from the faucet wallet on the faucet host via
#      `lotus send` (the HTTP faucet needs a captcha, the wallet does not).
#   3. Opens an SSH tunnel to the faucet host's Lotus API (Eth RPC enabled via
#      lotus_daemon_enable_eth_rpc) and runs the solstice repo's
#      script/Deploy.s.sol with forge, which takes the deployer's nonces 0..3.
#   4. Compares the deployed proxy addresses with the expected ones.
#
# Requirements on the machine running this: forge, cast, jq, ssh access to the
# faucet host as ubuntu, a checkout of filecoin-project/solstice with its
# submodules (forge install), and a checkout of the Lotus branch being tested.
# Run this over an SSH session with agent forwarding enabled (ssh -A) so the
# ssh calls below use your own forwarded key; no key needs to live on the
# machine running this script.
#
# Usage:
#   LOTUS_SRC=~/lotus SOLSTICE_SRC=~/solstice scripts/nv29_butterfly_deploy_solstice_contracts.bash
#
# Env overrides: FAUCET_HOST (toolshed-0.butterfly.fildev.network), FUND_FIL (100),
#   TUNNEL_PORT (11234), LOTUS_PATH_REMOTE (/var/lib/lotus), LOTUS_USER_REMOTE (fc).
#   CHECK_ONLY=1 stops after the read-only checks, before funding or deploying.
#   MIN_EPOCH_MARGIN (10): refuse to fund or deploy with fewer epochs than this left before the upgrade.

set -euo pipefail

LOTUS_SRC="${LOTUS_SRC:?set LOTUS_SRC to a Lotus checkout on the butterfly testing branch}"
SOLSTICE_SRC="${SOLSTICE_SRC:?set SOLSTICE_SRC to a filecoin-project/solstice checkout}"
FAUCET_HOST="${FAUCET_HOST:-toolshed-0.butterfly.fildev.network}"
FUND_FIL="${FUND_FIL:-100}"
TUNNEL_PORT="${TUNNEL_PORT:-11234}"
LOTUS_PATH_REMOTE="${LOTUS_PATH_REMOTE:-/var/lib/lotus}"
LOTUS_USER_REMOTE="${LOTUS_USER_REMOTE:-fc}"
BUTTERFLY_CHAIN_ID=3141592

params="${LOTUS_SRC}/build/buildconstants/params_butterfly.go"
[ -f "$params" ] || { echo "missing $params" >&2; exit 1; }
for tool in forge cast jq ssh; do command -v "$tool" >/dev/null || { echo "missing $tool" >&2; exit 1; }; done

log() { printf '\n==> %s\n' "$*"; }
# Lotus' eth_blockNumber intentionally reports the parent of the heaviest tipset,
# so use the native head for anything safety-related.
native_head() { remote_lotus chain head --height | tail -1; }
# Refuse to continue unless at least MIN_EPOCH_MARGIN epochs remain before the upgrade.
MIN_EPOCH_MARGIN="${MIN_EPOCH_MARGIN:-10}"
require_margin() {
  local stage="$1" head
  head=$(native_head)
  if [ -n "$upgrade_height" ] && [ $((head + MIN_EPOCH_MARGIN)) -gt "$upgrade_height" ]; then
    echo "$stage: native head is $head; fewer than ${MIN_EPOCH_MARGIN} epochs remain before UpgradeSolsticeHeight $upgrade_height. Stopping." >&2
    exit 1
  fi
  echo "$stage: native head $head, upgrade at ${upgrade_height:-unscheduled}"
}
remote_lotus() {
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${FAUCET_HOST}" \
    "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} lotus $*"
}

log "Reading expected addresses from ${params}"
expected_swa=$(grep -E '^\s*SWAActor:' "$params" | grep -oE '0x[0-9a-fA-F]{40}')
expected_sra=$(grep -E '^\s*SRAActor:' "$params" | grep -oE '0x[0-9a-fA-F]{40}')
deployer_addr=$(grep -E '^\s*InitialOrchestrator:' "$params" | grep -oE '0x[0-9a-fA-F]{40}')
# The deployer key is documented in a comment block right above the params;
# it is the 64 hex chars line that precedes the deployer address line.
deployer_key=$(grep -B1 -iE "^//\s+${deployer_addr}" "$params" | grep -oE '0x[0-9a-fA-F]{64}' | head -1)
upgrade_height=$(grep -E '^const UpgradeSolsticeHeight' "$params" | grep -oE '[0-9]+$' || true)
[ -n "$expected_swa" ] && [ -n "$expected_sra" ] && [ -n "$deployer_addr" ] && [ -n "$deployer_key" ] \
  || { echo "could not parse addresses/key from $params" >&2; exit 1; }
echo "expected SRA proxy: $expected_sra"
echo "expected SWA proxy: $expected_swa"
echo "deployer/orchestrator: $deployer_addr"
echo "UpgradeSolsticeHeight: ${upgrade_height:-unscheduled}"

log "Resolving the deployer's f410 address on ${FAUCET_HOST}"
# `lotus evm stat` prints both address forms, then exits non-zero because the
# actor does not exist yet; the addresses are all we need.
deployer_f410=$( (remote_lotus evm stat "$deployer_addr" 2>/dev/null || true) | awk '/Filecoin address/{print $NF}')
[ -n "$deployer_f410" ] || { echo "could not resolve f410 address" >&2; exit 1; }
echo "deployer f410: $deployer_f410"

log "Checking chain state via SSH tunnel on port ${TUNNEL_PORT}"
ctl=$(mktemp -u /tmp/nv29-tunnel.XXXXXX)
ssh -o BatchMode=yes -o ConnectTimeout=10 -M -S "$ctl" -f -N -L "${TUNNEL_PORT}:127.0.0.1:1234" "ubuntu@${FAUCET_HOST}"
trap 'ssh -S "$ctl" -O exit "ubuntu@${FAUCET_HOST}" >/dev/null 2>&1 || true' EXIT
RPC="http://127.0.0.1:${TUNNEL_PORT}/rpc/v1"
chain_id=$(cast chain-id --rpc-url "$RPC")
[ "$chain_id" = "$BUTTERFLY_CHAIN_ID" ] || { echo "unexpected chain id $chain_id (want $BUTTERFLY_CHAIN_ID)" >&2; exit 1; }
echo "chain id $chain_id, eth block number $(cast block-number --rpc-url "$RPC")"
require_margin "before funding"
nonce=$(cast nonce "$deployer_addr" --rpc-url "$RPC")
if [ "$nonce" != "0" ]; then
  echo "deployer nonce is $nonce, not 0: the proxies cannot land at the expected addresses on this chain" >&2; exit 1
fi

if [ "${CHECK_ONLY:-0}" = "1" ]; then
  echo "CHECK_ONLY set; stopping before funding and deploying."; exit 0
fi

log "Funding the deployer with ${FUND_FIL} FIL from the faucet wallet"
faucet_addr=$(remote_lotus wallet list | awk 'NR>1 && $1 ~ /^[tf]1/ {print $1; exit}')
[ -n "$faucet_addr" ] || { echo "no faucet wallet found on ${FAUCET_HOST}" >&2; exit 1; }
# `lotus send` prints a few informational lines before the message CID.
msg_cid=$(remote_lotus send --from "$faucet_addr" "$deployer_f410" "$FUND_FIL" | tail -1)
echo "sent from $faucet_addr, message $msg_cid; waiting for it to land"
wait_out=$(remote_lotus state wait-msg --timeout 5m "$msg_cid")
grep -qE '^Exit Code: 0$' <<<"$wait_out" || { echo "funding message did not succeed:" >&2; echo "$wait_out" >&2; exit 1; }
balance=$(cast balance "$deployer_addr" --rpc-url "$RPC" --ether)
echo "deployer balance: $balance FIL"
awk -v b="$balance" -v want="$FUND_FIL" 'BEGIN{exit !(b+0 >= want+0)}' \
  || { echo "deployer balance $balance is below the requested $FUND_FIL FIL" >&2; exit 1; }

log "Deploying the Solstice contracts with forge from ${SOLSTICE_SRC}"
cd "$SOLSTICE_SRC"
jq -e --arg id "$BUTTERFLY_CHAIN_ID" '.[$id]' deployments.json >/dev/null \
  || { echo "deployments.json has no entry for chain $BUTTERFLY_CHAIN_ID" >&2; exit 1; }
require_margin "before deploying"
forge script script/Deploy.s.sol --broadcast --skip-simulation --rpc-url "$RPC" --private-key "$deployer_key"
deployed_sra=$(jq -r --arg id "$BUTTERFLY_CHAIN_ID" '.[$id].sra' deployments.json)
deployed_swa=$(jq -r --arg id "$BUTTERFLY_CHAIN_ID" '.[$id].swa' deployments.json)

log "Verifying"
lc() { tr '[:upper:]' '[:lower:]' <<<"$1"; }
ok=1
for pair in "SRA:$expected_sra:$deployed_sra" "SWA:$expected_swa:$deployed_swa"; do
  IFS=: read -r name want got <<<"$pair"
  code_len=$(cast code "$got" --rpc-url "$RPC" | wc -c)
  if [ "$(lc "$want")" = "$(lc "$got")" ] && [ "$code_len" -gt 4 ]; then
    echo "$name proxy OK at $got (code present)"
  else
    echo "$name proxy MISMATCH: expected $want, deployed $got, code bytes $code_len" >&2; ok=0
  fi
done
echo "native head now $(native_head)"
[ "$ok" = 1 ] || { echo "Deployed addresses do not match params_butterfly.go; the Solstice migration will fail." >&2; exit 1; }
echo "Solstice contracts deployed at the expected addresses."
