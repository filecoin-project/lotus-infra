#!/usr/bin/env bash
#
# Generic per-upgrade Butterfly manual testing helper. Not upgrade-specific:
# re-run this against a fresh miner after every reset to work through the
# "Generic Butterfly manual testing items" table in the network upgrade doc.
#
# It runs each table item as a lotus-miner command against a miner on a
# non-preminer host (scratch-0 or toolshed-1 by convention; never a preminer),
# and prints a doc-ready block (Command(s) / Output / message CIDs) for each
# one so it can be pasted straight into the Discussion/Commands/Output column.
#
# Requirements on the machine running this: ssh access to MINER_HOST and
# FAUCET_HOST as ubuntu, jq.
#
# Usage:
#   scripts/butterfly_manual_testing.bash <subcommand> [args...]
#
# Subcommands:
#   fetch-params                       cache 512MiB proof params on MINER_HOST, preferring a direct
#                                       host-to-host copy from PARAMS_SOURCE_HOST (a preminer already
#                                       has them) over the public params gateway; read-only on the source
#   init-miner <owner-fund-tfil>       fetch-params, lotus-miner init, print MinerID/PeerID
#   fund <amount-tfil>                 send tFIL from the faucet wallet to the miner owner
#   migration-check <cid>              confirm chain state at <cid> matches after an upgrade migration
#   pledge <count>                     pledge <count> CC sectors, print sector numbers + CIDs
#   withdraw <amount-tfil>              withdraw from the miner actor
#   terminate <sectorNum...>           terminate specific sectors
#   extend <new-expiration-epoch> <sectorNum...>
#   precommit-batch                    flush the pending precommit batch
#   commit-batch                       flush the pending commit batch
#   control-addresses <addr1> <addr2>  set deal-publish and PoSt control addresses
#
# Env overrides:
#   MINER_HOST      (scratch-0.butterfly.fildev.network)
#   FAUCET_HOST     (toolshed-0.butterfly.fildev.network)
#   PARAMS_SOURCE_HOST (preminer-0.butterfly.fildev.network) - already has 512MiB params cached;
#                        used as a direct rsync source instead of re-downloading from the public gateway.
#                        Read-only on this host: we only add a throwaway restricted SSH key to pull
#                        with, and remove it again afterwards. Set to empty to skip straight to the
#                        public gateway (`lotus fetch-params`).
#   AWS_PROFILE_PARAMS (filoz) - profile used to look up PARAMS_SOURCE_HOST/MINER_HOST private IPs
#                        so the transfer stays inside AWS instead of routing through wherever this
#                        script runs. Falls back to the public gateway if the lookup fails.
#   AWS_REGION_PARAMS  (us-east-1)
#   LOTUS_PATH_REMOTE  (/var/lib/lotus)
#   LOTUS_USER_REMOTE  (fc)
#   SECTOR_SIZE     (512MiB)

set -euo pipefail

MINER_HOST="${MINER_HOST:-scratch-0.butterfly.fildev.network}"
FAUCET_HOST="${FAUCET_HOST:-toolshed-0.butterfly.fildev.network}"
PARAMS_SOURCE_HOST="${PARAMS_SOURCE_HOST-preminer-0.butterfly.fildev.network}"
AWS_PROFILE_PARAMS="${AWS_PROFILE_PARAMS:-filoz}"
AWS_REGION_PARAMS="${AWS_REGION_PARAMS:-us-east-1}"
LOTUS_PATH_REMOTE="${LOTUS_PATH_REMOTE:-/var/lib/lotus}"
LOTUS_USER_REMOTE="${LOTUS_USER_REMOTE:-fc}"
# Not /var/lib/lotus-miner: that's the daemon's LOTUS_PATH with a suffix
# tacked on, not the miner's actual repo. lotus-miner's real default is
# ~/.lotusminer, which for the fc user is this.
LOTUS_MINER_PATH_REMOTE="${LOTUS_MINER_PATH_REMOTE:-/home/${LOTUS_USER_REMOTE}/.lotusminer}"
SECTOR_SIZE="${SECTOR_SIZE:-512MiB}"
PARAMS_DIR_REMOTE="/var/tmp/filecoin-proof-parameters"

log() { printf '\n==> %s\n' "$*" >&2; }

# lotus/lotus-miner commands print verbose multi-line human output, not a
# bare CID, so callers must never feed the raw command output back into
# another remote command (a multi-line string as one ssh argument gets
# parsed as multiple shell commands on the far end). Extract just the CID.
extract_cid() { grep -oE 'bafy2[a-zA-Z2-7]{20,}' | tail -n1 || true; }

remote() {
  local host="$1"; shift
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${host}" "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} $*"
}

remote_lotus() { remote "$MINER_HOST" lotus "$@"; }
remote_faucet_lotus() { remote "$FAUCET_HOST" lotus "$@"; }
remote_miner() {
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${MINER_HOST}" \
    "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} LOTUS_MINER_PATH=${LOTUS_MINER_PATH_REMOTE} lotus-miner $*"
}

# Plain ubuntu-user SSH, no `sudo -u fc` wrapper: for host administration
# (authorized_keys, file ownership) rather than lotus/lotus-miner commands.
# Anything here that needs root uses its own explicit `sudo`.
admin() {
  local host="$1"; shift
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${host}" "$*"
}

# Prints a doc-ready block: the exact command(s) run and their output, so it
# can be pasted verbatim into the "Discussion, Commands, Output" column.
doc_block() {
  local cmd="$1" out="$2"
  printf '\nCommand(s):\n%s\n\nOutput:\n%s\n' "$cmd" "$out"
}

# Looks up an instance's private IP via AWS (so the rsync stays on AWS's
# internal network). Prints nothing and returns non-zero on any failure, so
# callers can fall back to the public params gateway.
private_ip_for() {
  local name="$1"
  command -v aws >/dev/null || return 1
  aws ec2 describe-instances --profile "$AWS_PROFILE_PARAMS" --region "$AWS_REGION_PARAMS" \
    --filters "Name=tag:Name,Values=${name}" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text 2>/dev/null \
    | grep -E '^[0-9.]+$'
}

# Populates PARAMS_DIR_REMOTE on MINER_HOST with the ${SECTOR_SIZE} proving
# params. Prefers a direct, read-only rsync from PARAMS_SOURCE_HOST (a
# preminer, which already paid the ~24GB download cost) over the public
# params gateway, since preminer-to-scratch/toolshed traffic stays inside
# AWS and is dramatically faster. Falls back to `lotus fetch-params` if
# PARAMS_SOURCE_HOST is unset, unreachable, or the AWS lookup fails.
cmd_fetch_params() {
  if [ -z "${PARAMS_SOURCE_HOST}" ]; then
    log "PARAMS_SOURCE_HOST unset; fetching ${SECTOR_SIZE} params from the public gateway on ${MINER_HOST}"
    remote "$MINER_HOST" "/usr/local/bin/lotus fetch-params ${SECTOR_SIZE}"
    return 0
  fi

  log "Diffing proof params between ${PARAMS_SOURCE_HOST} and ${MINER_HOST}"
  # "name size" pairs for .params files only (the .vk verifying keys are tiny
  # and both hosts already fetch those on daemon start regardless of role).
  # bash -c wraps the cd+find: run plain, `sudo -u fc` can't restore the
  # shell's starting directory (/home/ubuntu, not readable by fc) and find
  # exits 1 on that alone despite listing everything correctly.
  local find_cmd="bash -c 'cd ${PARAMS_DIR_REMOTE} && find . -maxdepth 1 -name \"*.params\" -printf \"%f %s\\n\"'"
  src_list=$(remote "$PARAMS_SOURCE_HOST" "$find_cmd" 2>/dev/null) || {
    log "Could not reach ${PARAMS_SOURCE_HOST}; falling back to the public gateway"
    remote "$MINER_HOST" "/usr/local/bin/lotus fetch-params ${SECTOR_SIZE}"
    return 0
  }
  dst_list=$(remote "$MINER_HOST" "$find_cmd" 2>/dev/null || true)

  missing=$(comm -23 <(sort <<<"$src_list") <(sort <<<"$dst_list") | awk '{print $1}')
  if [ -z "$missing" ]; then
    echo "${MINER_HOST} already has every .params file ${PARAMS_SOURCE_HOST} has. Nothing to do."
    return 0
  fi
  echo "missing on ${MINER_HOST}:"; echo "$missing"

  src_ip=$(private_ip_for "${PARAMS_SOURCE_HOST%%.*}") || true
  dst_ip=$(private_ip_for "${MINER_HOST%%.*}") || true
  if [ -z "$src_ip" ] || [ -z "$dst_ip" ]; then
    log "Could not resolve private IPs via AWS; falling back to the public gateway on ${MINER_HOST}"
    remote "$MINER_HOST" "/usr/local/bin/lotus fetch-params ${SECTOR_SIZE}"
    return 0
  fi

  log "Provisioning a throwaway SSH key so ${MINER_HOST} can pull directly from ${PARAMS_SOURCE_HOST} (${src_ip} -> ${dst_ip})"
  key_dir=$(mktemp -d)
  ssh-keygen -t ed25519 -f "${key_dir}/relay" -N "" -C "butterfly-params-relay-$(date +%s)" -q
  pubkey=$(cat "${key_dir}/relay.pub")
  admin "$PARAMS_SOURCE_HOST" "echo 'no-pty,no-port-forwarding,no-X11-forwarding,no-agent-forwarding,from=\"${dst_ip}\" ${pubkey}' >> ~/.ssh/authorized_keys"
  cleanup_key() {
    admin "$PARAMS_SOURCE_HOST" "grep -vF '${pubkey#* }' ~/.ssh/authorized_keys > /tmp/ak.new.\$\$ && mv /tmp/ak.new.\$\$ ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" 2>/dev/null || true
    admin "$MINER_HOST" "sudo rm -f /tmp/params-relay-key /tmp/params-relay-key.owned" 2>/dev/null || true
    rm -rf "$key_dir"
  }
  # EXIT (not RETURN): a RETURN trap fires on every nested function return,
  # not just this one, so it would revoke the key mid-transfer. EXIT only
  # fires once, when the whole script process ends, so it's a safety net
  # for errors; the success path below cleans up explicitly and unregisters it.
  trap cleanup_key EXIT

  scp -o BatchMode=yes -o ConnectTimeout=10 "${key_dir}/relay" "ubuntu@${MINER_HOST}:/tmp/params-relay-key" >/dev/null
  admin "$MINER_HOST" "sudo cp /tmp/params-relay-key /tmp/params-relay-key.owned && sudo chown ${LOTUS_USER_REMOTE} /tmp/params-relay-key.owned && sudo chmod 600 /tmp/params-relay-key.owned"

  local includes="" f
  for f in $missing; do includes+=" --include=$(printf '%q' "$f")"; done

  log "rsyncing $(wc -w <<<"$missing") file(s) directly ${PARAMS_SOURCE_HOST} -> ${MINER_HOST} over their private IPs"
  # shellcheck disable=SC2086
  admin "$MINER_HOST" "sudo -u ${LOTUS_USER_REMOTE} rsync -av --partial \
    -e 'ssh -i /tmp/params-relay-key.owned -o StrictHostKeyChecking=accept-new -o BatchMode=yes' \
    ${includes} --exclude='*' \
    ubuntu@${src_ip}:${PARAMS_DIR_REMOTE}/ ${PARAMS_DIR_REMOTE}/"
  echo "done: ${PARAMS_SOURCE_HOST} -> ${MINER_HOST} params sync complete"
  cleanup_key
  trap - EXIT
}

# Starts `lotus-miner run` if it isn't already, and waits for its API to come
# up. There's no systemd unit for this on non-preminer hosts (ansible doesn't
# manage a miner there), so this is a plain background process; it won't
# survive a host reboot. Safe/cheap to call even if already running.
cmd_ensure_running() {
  if remote_miner info >/dev/null 2>&1; then
    echo "lotus-miner is already running on ${MINER_HOST}"
    return 0
  fi
  log "Starting lotus-miner run on ${MINER_HOST} (logging to /tmp/lotus-miner.log; re-verifies proof param hashes on every start, can take a few minutes)"
  # Log path must be somewhere `ubuntu` can create the file: the shell doing
  # the `>` redirect is ubuntu's (sudo hasn't execed yet when it opens the
  # file), and ubuntu can't write inside fc's home directory.
  #
  # C2_512M_BASE_MIN_MEMORY: the miner also acts as its own worker here (no
  # separate lotus-worker), and the default resource table requires 11GB
  # physical RAM just to *schedule* a 512MiB Commit2 job (10GB "BaseMinMemory
  # for params" + 1GB MinMemory) -- more than an m5a.large's 8GB has, and this
  # specific check is physical-RAM-only, swap does not help. C2 sat scheduled
  # but never running for 30+ minutes before this was found. The real 512MiB
  # PoRep params file is ~2GB, so 3GB is a safe override with headroom. Set
  # this *before* first pledging a sector, not after -- a restart to add it
  # later throws away any in-flight PC1/PC2 job.
  admin "$MINER_HOST" "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} LOTUS_MINER_PATH=${LOTUS_MINER_PATH_REMOTE} C2_512M_BASE_MIN_MEMORY=3221225472 nohup /usr/local/bin/lotus-miner run --nosync > /tmp/lotus-miner.log 2>&1 & disown"
  local waited=0
  while ! remote_miner info >/dev/null 2>&1; do
    sleep 15; waited=$((waited + 15))
    if [ "$waited" -ge 600 ]; then
      echo "lotus-miner still not up after 10m; check /tmp/lotus-miner.log on ${MINER_HOST}" >&2
      return 1
    fi
  done
  echo "lotus-miner API is up after ${waited}s"
}

cmd_init_miner() {
  local fund_amount="${1:?usage: init-miner <owner-fund-tfil>}"

  log "Checking for an existing miner actor on ${MINER_HOST} (idempotent)"
  if remote "$MINER_HOST" test -f "${LOTUS_MINER_PATH_REMOTE}/config.toml" 2>/dev/null; then
    echo "A miner actor already exists on ${MINER_HOST} (${LOTUS_MINER_PATH_REMOTE} exists)." >&2
    echo "Skipping init. Delete ${LOTUS_MINER_PATH_REMOTE} first if you really want a fresh one." >&2
    remote_miner info 2>/dev/null | grep '^Miner:' || true
    return 0
  fi

  log "Ensuring the lotus-miner binary exists on ${MINER_HOST} (ansible only installs it on preminers)"
  if ! remote "$MINER_HOST" test -x /usr/local/bin/lotus-miner 2>/dev/null; then
    [ -n "$PARAMS_SOURCE_HOST" ] || { echo "no lotus-miner binary on ${MINER_HOST} and PARAMS_SOURCE_HOST is unset to copy one from" >&2; exit 1; }
    log "Copying it from ${PARAMS_SOURCE_HOST} (small binary, relayed through wherever this script runs)"
    admin "$PARAMS_SOURCE_HOST" "cat /usr/local/bin/lotus-miner" | admin "$MINER_HOST" "sudo tee /usr/local/bin/lotus-miner > /dev/null && sudo chmod 755 /usr/local/bin/lotus-miner"
  fi

  log "Ensuring proof params (${SECTOR_SIZE}) are cached on ${MINER_HOST} (~24GB if not already)"
  cmd_fetch_params

  log "Creating an owner wallet and funding it with ${fund_amount} tFIL from the faucet"
  owner_addr=$(remote_lotus wallet new bls)
  echo "owner wallet: ${owner_addr}"
  faucet_addr=$(remote_faucet_lotus wallet list | awk 'NR>1 && $1 ~ /^[tf]1/ {print $1; exit}')
  [ -n "$faucet_addr" ] || { echo "no faucet wallet found on ${FAUCET_HOST}" >&2; exit 1; }
  fund_out=$(remote_faucet_lotus send --from "$faucet_addr" "$owner_addr" "$fund_amount" 2>&1)
  echo "$fund_out"
  fund_cid=$(extract_cid <<<"$fund_out")
  [ -n "$fund_cid" ] || { echo "could not parse a message CID out of: $fund_out" >&2; exit 1; }
  remote_faucet_lotus state wait-msg --timeout 5m "$fund_cid" >/dev/null

  log "Running lotus-miner init --sector-size=${SECTOR_SIZE} --from=${owner_addr}"
  init_out=$(remote "$MINER_HOST" "/usr/local/bin/lotus-miner init --sector-size=${SECTOR_SIZE} --from=${owner_addr} --nosync" 2>&1)
  echo "$init_out"

  cmd_ensure_running

  log "Miner identity"
  miner_id=$(remote_miner info 2>/dev/null | awk '/^Miner:/{print $2; exit}')
  peer_id=$(remote_lotus net id 2>/dev/null || true)
  echo "MinerID: ${miner_id:-unknown, run: lotus-miner info}"
  echo "Daemon PeerID: ${peer_id:-unknown, run: lotus net id on ${MINER_HOST}}"
  doc_block "lotus fetch-params ${SECTOR_SIZE}
lotus wallet new bls
lotus send --from <faucet> ${owner_addr} ${fund_amount}
lotus-miner init --sector-size=${SECTOR_SIZE} --from=${owner_addr} --nosync" \
    "owner: ${owner_addr}
fund msg: ${fund_cid}
MinerID: ${miner_id:-TBD}
Daemon PeerID: ${peer_id:-TBD}"
}

cmd_fund() {
  local amount="${1:?usage: fund <amount-tfil>}"
  owner_addr=$(remote_miner actor control list 2>/dev/null | awk 'NR==2{print $1}' || true)
  [ -n "$owner_addr" ] || owner_addr=$(remote_lotus wallet default)
  faucet_addr=$(remote_faucet_lotus wallet list | awk 'NR>1 && $1 ~ /^[tf]1/ {print $1; exit}')
  out=$(remote_faucet_lotus send --from "$faucet_addr" "$owner_addr" "$amount" 2>&1)
  echo "$out"
  cid=$(extract_cid <<<"$out")
  [ -n "$cid" ] || { echo "could not parse a message CID out of: $out" >&2; exit 1; }
  remote_faucet_lotus state wait-msg --timeout 5m "$cid" >/dev/null
  echo "funded ${owner_addr} with ${amount} tFIL: ${cid}"
  doc_block "lotus send --from <faucet> ${owner_addr} ${amount}" "msg: ${cid}"
}

cmd_migration_check() {
  local cid="${1:?usage: migration-check <cid>}"
  log "Checking chain state at ${cid} on ${MINER_HOST}'s daemon"
  out=$(remote_lotus state get-actor "$cid" 2>&1) || true
  echo "$out"
  head=$(remote_lotus chain head 2>&1)
  echo "current head: ${head}"
  doc_block "lotus state get-actor ${cid}" "${out}
head: ${head}"
}

cmd_pledge() {
  local count="${1:?usage: pledge <count>}"
  local cids=() before after
  before=$(remote_miner sectors list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  for i in $(seq 1 "$count"); do
    log "Pledging sector ${i}/${count}"
    out=$(remote_miner sectors pledge 2>&1)
    echo "$out"
    cid=$(extract_cid <<<"$out"); [ -n "$cid" ] || cid="$out"
    echo "pledge ${i}: ${cid}"
    cids+=("$cid")
  done
  after=$(remote_miner sectors list 2>/dev/null | tail -n +2 | wc -l | tr -d ' ')
  echo "sector count: ${before} -> ${after}"
  doc_block "lotus-miner sectors pledge   # x${count}" "$(printf '%s\n' "${cids[@]}")
sector count: ${before} -> ${after}"
}

cmd_withdraw() {
  local amount="${1:?usage: withdraw <amount-tfil>}"
  cid=$(remote_miner actor withdraw "$amount")
  echo "withdraw msg: ${cid}"
  doc_block "lotus-miner actor withdraw ${amount}" "TX: ${cid}"
}

cmd_terminate() {
  [ "$#" -ge 1 ] || { echo "usage: terminate <sectorNum...>" >&2; exit 1; }
  local sectors=("$@") cids=()
  for s in "${sectors[@]}"; do
    cid=$(remote_miner sectors terminate --really-do-it "$s" 2>&1)
    echo "terminate ${s}: ${cid}"
    cids+=("sector ${s}: ${cid}")
  done
  flush=$(remote_miner sectors terminate flush 2>&1)
  echo "flush: ${flush}"
  doc_block "$(for s in "${sectors[@]}"; do echo "lotus-miner sectors terminate --really-do-it ${s}"; done)
lotus-miner sectors terminate flush" \
    "$(printf '%s\n' "${cids[@]}")
flush: ${flush}"
}

cmd_extend() {
  [ "$#" -ge 2 ] || { echo "usage: extend <new-expiration-epoch> <sectorNum...>" >&2; exit 1; }
  local new_exp="$1"; shift
  local sectors=("$@") cids=()
  for s in "${sectors[@]}"; do
    cid=$(remote_miner sectors extend --new-expiration "$new_exp" --really-do-it "$s" 2>&1)
    echo "extend ${s}: ${cid}"
    cids+=("sector ${s}: ${cid}")
  done
  doc_block "$(for s in "${sectors[@]}"; do echo "lotus-miner sectors extend --new-expiration ${new_exp} --really-do-it ${s}"; done)" \
    "$(printf '%s\n' "${cids[@]}")"
}

cmd_precommit_batch() {
  # Without --publish-now, this command prompts "Do you want to publish these
  # sectors now? (yes/no)" if anything is pending, and hangs/EOFs over a
  # non-interactive SSH session. --publish-now is the actual flush.
  out=$(remote_miner sectors batching precommit --publish-now 2>&1)
  echo "$out"
  doc_block "lotus-miner sectors batching precommit --publish-now" "$out"
}

cmd_commit_batch() {
  # Same interactive-prompt trap as precommit_batch above.
  out=$(remote_miner sectors batching commit --publish-now 2>&1)
  echo "$out"
  doc_block "lotus-miner sectors batching commit --publish-now" "$out"
}

cmd_control_addresses() {
  local a="${1:?usage: control-addresses <deal-publish-addr> <post-addr>}" b="${2:?usage: control-addresses <deal-publish-addr> <post-addr>}"
  cid=$(remote_miner actor control set --really-do-it "$a" "$b" 2>&1)
  echo "control set: ${cid}"
  doc_block "lotus-miner actor control set --really-do-it ${a} ${b}" "TX: ${cid}"
}

sub="${1:-}"; shift || true
case "$sub" in
  fetch-params)       cmd_fetch_params "$@" ;;
  ensure-running)     cmd_ensure_running "$@" ;;
  init-miner)         cmd_init_miner "$@" ;;
  fund)               cmd_fund "$@" ;;
  migration-check)    cmd_migration_check "$@" ;;
  pledge)             cmd_pledge "$@" ;;
  withdraw)           cmd_withdraw "$@" ;;
  terminate)          cmd_terminate "$@" ;;
  extend)             cmd_extend "$@" ;;
  precommit-batch)    cmd_precommit_batch "$@" ;;
  commit-batch)       cmd_commit_batch "$@" ;;
  control-addresses)  cmd_control_addresses "$@" ;;
  *)
    echo "usage: $0 <fetch-params|ensure-running|init-miner|fund|migration-check|pledge|withdraw|terminate|extend|precommit-batch|commit-batch|control-addresses> [args...]" >&2
    exit 1
    ;;
esac
