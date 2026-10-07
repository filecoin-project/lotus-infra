#!/usr/bin/env bash
#
# Generic per-upgrade Butterfly manual testing helper. Not upgrade-specific:
# re-run this against a fresh miner after every reset to work through the
# "Generic Butterfly manual testing items" table in the network upgrade doc.
#
# It runs each table item as a lotus-miner command against a miner on a
# non-preminer host (scratch-0 or toolshed-1 by convention; never a preminer),
# and prints a doc-ready block (Command(s) / Output) for each one so it can be
# pasted straight into the Discussion/Commands/Output column. Any command that
# fails prints its output and stops the script.
#
# Requirements on the machine running this: ssh access as ubuntu to
# MINER_HOST, FAUCET_HOST and PARAMS_SOURCE_HOST/BINARY_SOURCE_HOST; the aws
# CLI with access to the FilOz account (only for the direct params copy).
#
# Usage:
#   scripts/butterfly_manual_testing.bash <subcommand> [args...]
#
# Subcommands, roughly in the order the table uses them:
#   fetch-params                   copy proof params (*.params, *.srs) that MINER_HOST is missing
#                                  from PARAMS_SOURCE_HOST over the private network, falling back
#                                  to `lotus fetch-params` from the public gateway
#   ensure-running                 start `lotus-miner run` on MINER_HOST if it isn't running
#   init-miner <owner-fund-tfil>   copy the lotus-miner binary if missing, fetch-params, create
#                                  and fund an owner wallet, lotus-miner init, ensure-running
#   fund <amount-tfil>             send tFIL from the faucet wallet to the miner's owner
#   migration-check [address]      network version, chain head, and an actor's state (default:
#                                  MINER_ADDR) read back after an upgrade migration
#   pledge <count>                 pledge <count> CC sectors
#   withdraw <amount-tfil>         withdraw from the miner actor's available balance
#   terminate <sectorNum...>       terminate sectors, then flush the termination batch
#   extend <sectorNum...>          extend sectors' expiration (sectors must be chain-Active)
#   precommit-batch                send the pending precommit batch now
#   commit-batch                   send the pending commit batch now
#   control-addresses [addr...]    set the miner's control addresses; with no args, create and
#                                  fund two new wallets and use those
#
# Env overrides (defaults in parentheses):
#   MINER_HOST           (scratch-0.butterfly.fildev.network)
#   FAUCET_HOST          (toolshed-0.butterfly.fildev.network)
#   FAUCET_ADDR          (the --from of the lotus-fountain service on FAUCET_HOST)
#   PARAMS_SOURCE_HOST   (preminer-0.butterfly.fildev.network): a host that already has the params.
#                        Set to empty to always use the public gateway.
#   BINARY_SOURCE_HOST   (preminer-0.butterfly.fildev.network): where to copy lotus-miner from
#   AWS_PROFILE_PARAMS   (filoz) and AWS_REGION_PARAMS (us-east-1): used to look up private IPs
#   LOTUS_PATH_REMOTE    (/var/lib/lotus)
#   LOTUS_USER_REMOTE    (fc)
#   LOTUS_MINER_PATH_REMOTE (/home/<LOTUS_USER_REMOTE>/.lotusminer)
#   SECTOR_SIZE          (512MiB)
#   EXTEND_EPOCHS        (unset: lotus-miner's default --extension) for `extend`
#   CONTROL_FUND_TFIL    (2): funding for each wallet `control-addresses` creates
#   MINER_ADDR           (required by every subcommand that changes the miner or sends funds):
#                        the miner actor you expect, e.g. t01010. init-miner prints it. A
#                        spare host can be shared, and a stale api file in the repo can reach
#                        someone else's miner, so the script refuses to act on any other one.

set -euo pipefail

MINER_HOST="${MINER_HOST:-scratch-0.butterfly.fildev.network}"
FAUCET_HOST="${FAUCET_HOST:-toolshed-0.butterfly.fildev.network}"
FAUCET_ADDR="${FAUCET_ADDR:-}"
PARAMS_SOURCE_HOST="${PARAMS_SOURCE_HOST-preminer-0.butterfly.fildev.network}"
BINARY_SOURCE_HOST="${BINARY_SOURCE_HOST:-preminer-0.butterfly.fildev.network}"
AWS_PROFILE_PARAMS="${AWS_PROFILE_PARAMS:-filoz}"
AWS_REGION_PARAMS="${AWS_REGION_PARAMS:-us-east-1}"
LOTUS_PATH_REMOTE="${LOTUS_PATH_REMOTE:-/var/lib/lotus}"
LOTUS_USER_REMOTE="${LOTUS_USER_REMOTE:-fc}"
# lotus-miner's default repo is ~/.lotusminer, which for the fc user is this.
LOTUS_MINER_PATH_REMOTE="${LOTUS_MINER_PATH_REMOTE:-/home/${LOTUS_USER_REMOTE}/.lotusminer}"
SECTOR_SIZE="${SECTOR_SIZE:-512MiB}"
EXTEND_EPOCHS="${EXTEND_EPOCHS:-}"
CONTROL_FUND_TFIL="${CONTROL_FUND_TFIL:-2}"
MINER_ADDR="${MINER_ADDR:-}"
PARAMS_DIR_REMOTE="/var/tmp/filecoin-proof-parameters"

log() { printf '\n==> %s\n' "$*" >&2; }
die() { echo "$*" >&2; exit 1; }

# Runs "$@", leaving its combined stdout/stderr in $out. On failure it prints
# that output and exits; a plain out=$(cmd) under set -e would exit with the
# error message trapped inside the variable, unseen.
capture() {
  local rc=0
  out=$("$@" 2>&1) || rc=$?
  if [ "$rc" -ne 0 ]; then
    printf '%s\n' "$out" >&2
    die "failed (exit ${rc}): $*"
  fi
}

# lotus/lotus-miner print multi-line human output with the message CID on its
# own line. Never pass that raw output on to another remote command (each line
# would run as a separate shell command on the far end); pull out the CIDs.
extract_cids() { grep -oE 'bafy2[a-z2-7]{20,}' || true; }

remote() {
  local host="$1"; shift
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${host}" "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} $*"
}
remote_lotus() { remote "$MINER_HOST" lotus "$@"; }
remote_faucet_lotus() { remote "$FAUCET_HOST" lotus "$@"; }
remote_miner() { remote "$MINER_HOST" "LOTUS_MINER_PATH=${LOTUS_MINER_PATH_REMOTE}" lotus-miner "$@"; }

# Plain ubuntu-user SSH for host administration (authorized_keys, files);
# anything that needs root uses its own explicit sudo.
admin() {
  local host="$1"; shift
  # shellcheck disable=SC2029
  ssh -o BatchMode=yes -o ConnectTimeout=10 "ubuntu@${host}" "$*"
}

doc_block() { printf '\nCommand(s):\n%s\n\nOutput:\n%s\n' "$1" "$2"; }

miner_addr() { { remote_miner info 2>/dev/null || true; } | awk '/^Miner:/{print $2; exit}'; }

# Guard for anything that changes the miner or sends funds: the miner answering
# at LOTUS_MINER_PATH_REMOTE must be the one in MINER_ADDR.
require_miner() {
  local running
  running=$(miner_addr)
  [ -n "$running" ] || die "no lotus-miner answering at ${LOTUS_MINER_PATH_REMOTE} on ${MINER_HOST}"
  [ -n "$MINER_ADDR" ] || die "lotus-miner on ${MINER_HOST} is ${running}; set MINER_ADDR=${running} if that's the miner you mean"
  [ "$running" = "$MINER_ADDR" ] || die "lotus-miner on ${MINER_HOST} is ${running}, not MINER_ADDR=${MINER_ADDR}; refusing"
}

# The faucet wallet is whatever lotus-fountain sends from. The faucet host holds
# other keys too, so guessing from `wallet list` picks the wrong one.
faucet_addr() {
  if [ -n "$FAUCET_ADDR" ]; then echo "$FAUCET_ADDR"; return; fi
  local a
  a=$({ admin "$FAUCET_HOST" "systemctl show -p ExecStart --value lotus-fountain" || true; } | grep -oE -- '--from [^ ;]+' | awk '{print $2}' | tr -d '"' || true)
  [ -n "$a" ] || die "could not read lotus-fountain's --from on ${FAUCET_HOST}; set FAUCET_ADDR"
  echo "$a"
}

# Sends <amount> tFIL from the faucet wallet to <to>, waits for it to land, and
# prints the message CID.
faucet_send() {
  local to="$1" amount="$2" from cid
  from=$(faucet_addr)
  capture remote_faucet_lotus send --from "$from" "$to" "$amount"
  cid=$(extract_cids <<<"$out" | tail -n1)
  [ -n "$cid" ] || die "could not find a message CID in: $out"
  capture remote_faucet_lotus state wait-msg --timeout 5m "$cid"
  echo "$cid"
}

private_ip_for() {
  command -v aws >/dev/null || return 1
  aws ec2 describe-instances --profile "$AWS_PROFILE_PARAMS" --region "$AWS_REGION_PARAMS" \
    --filters "Name=tag:Name,Values=$1" \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text 2>/dev/null \
    | grep -E '^[0-9.]+$'
}

gateway_fetch() {
  log "Fetching ${SECTOR_SIZE} params from the public gateway on ${MINER_HOST}"
  remote "$MINER_HOST" "/usr/local/bin/lotus fetch-params ${SECTOR_SIZE}"
}

# Copies proof params MINER_HOST is missing from PARAMS_SOURCE_HOST (a preminer,
# which already paid the ~24GB download) over the AWS private network, which is
# far faster than the public gateway. It copies every *.params/*.srs file the
# source has that the miner host lacks; preminers only hold the ones for their
# own sector size. To pull, it adds a throwaway key to the source's
# authorized_keys that only allows read-only rsync of the params directory from
# the miner host's IP (via rrsync), and removes it afterwards.
cmd_fetch_params() {
  [ -n "$PARAMS_SOURCE_HOST" ] || { gateway_fetch; return; }

  log "Diffing proof params between ${PARAMS_SOURCE_HOST} and ${MINER_HOST}"
  # bash -c so the cd happens under sudo -u fc; otherwise find exits 1 trying to
  # return to ubuntu's home directory, which fc can't read.
  local find_cmd="bash -c 'cd ${PARAMS_DIR_REMOTE} && find . -maxdepth 1 \\( -name \"*.params\" -o -name \"*.srs\" \\) -printf \"%f %s\\n\"'"
  local src_list dst_list missing
  if ! src_list=$(remote "$PARAMS_SOURCE_HOST" "$find_cmd" 2>/dev/null); then
    log "Could not list params on ${PARAMS_SOURCE_HOST}"
    gateway_fetch; return
  fi
  dst_list=$(remote "$MINER_HOST" "$find_cmd" 2>/dev/null || true)
  missing=$(comm -23 <(sort <<<"$src_list") <(sort <<<"$dst_list") | awk '{print $1}')
  if [ -z "$missing" ]; then
    echo "${MINER_HOST} already has every param file ${PARAMS_SOURCE_HOST} has."
    return
  fi
  echo "missing on ${MINER_HOST}:"; echo "$missing"

  local src_ip dst_ip
  src_ip=$(private_ip_for "${PARAMS_SOURCE_HOST%%.*}") || true
  dst_ip=$(private_ip_for "${MINER_HOST%%.*}") || true
  if [ -z "$src_ip" ] || [ -z "$dst_ip" ]; then
    log "Could not resolve private IPs via AWS"
    gateway_fetch; return
  fi

  log "Adding a temporary read-only rsync key on ${PARAMS_SOURCE_HOST} for ${MINER_HOST} (${dst_ip})"
  key_dir=$(mktemp -d)
  key_tag="butterfly-params-relay-$(date +%s)"
  ssh-keygen -t ed25519 -f "${key_dir}/relay" -N "" -C "$key_tag" -q
  cleanup_key() {
    admin "$PARAMS_SOURCE_HOST" "grep -vF '${key_tag}' ~/.ssh/authorized_keys > /tmp/ak.new.\$\$ && mv /tmp/ak.new.\$\$ ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys" 2>/dev/null || true
    admin "$MINER_HOST" "sudo rm -f /tmp/params-relay-key" 2>/dev/null || true
    rm -rf "$key_dir"
  }
  # EXIT, not RETURN: a RETURN trap would also fire when nested functions
  # return and revoke the key mid-copy. Registered before the key is added so
  # a failure at any point still removes it.
  trap cleanup_key EXIT
  admin "$PARAMS_SOURCE_HOST" "echo 'restrict,from=\"${dst_ip}\",command=\"/usr/bin/rrsync -ro ${PARAMS_DIR_REMOTE}/\" $(cat "${key_dir}/relay.pub")' >> ~/.ssh/authorized_keys"
  scp -q -o BatchMode=yes -o ConnectTimeout=10 "${key_dir}/relay" "ubuntu@${MINER_HOST}:/tmp/params-relay-key"
  admin "$MINER_HOST" "sudo chown ${LOTUS_USER_REMOTE} /tmp/params-relay-key && sudo chmod 600 /tmp/params-relay-key"

  local includes="" f
  for f in $missing; do includes+=" --include=$(printf '%q' "$f")"; done
  log "rsyncing $(wc -w <<<"$missing" | tr -d ' ') file(s) ${PARAMS_SOURCE_HOST} -> ${MINER_HOST} over the private network"
  # Paths are relative to the params directory: rrsync roots the source there.
  admin "$MINER_HOST" "sudo -u ${LOTUS_USER_REMOTE} rsync -a --partial \
    -e 'ssh -i /tmp/params-relay-key -o StrictHostKeyChecking=accept-new -o BatchMode=yes' \
    ${includes} --exclude='*' ubuntu@${src_ip}:./ ${PARAMS_DIR_REMOTE}/"
  cleanup_key
  trap - EXIT
  echo "params copied from ${PARAMS_SOURCE_HOST}"
}

# Starts `lotus-miner run` if it isn't already and waits for its API. Non-
# preminer hosts have no systemd unit for a miner, so this is a plain
# background process and won't survive a reboot.
cmd_ensure_running() {
  if remote_miner info >/dev/null 2>&1; then
    echo "lotus-miner is already running on ${MINER_HOST}"
    return
  fi
  log "Starting lotus-miner run on ${MINER_HOST} (log: /tmp/lotus-miner.log; it re-hashes the proof params on every start, which takes a few minutes)"
  # The log goes to /tmp because the > redirect is opened by ubuntu's shell
  # before sudo runs, and ubuntu can't write in fc's home directory.
  #
  # C2_512M_BASE_MIN_MEMORY: the miner is also its own worker here, and Lotus's
  # default resource table needs 11GB of physical RAM to schedule a 512MiB
  # Commit2 (10GB BaseMinMemory for params + 1GB MinMemory). An m5a.large has
  # 8GB, swap doesn't count, and the job just never runs (no error). The 512MiB
  # PoRep params file is about 2GB, so 3GB leaves headroom. It must be set
  # before sectors are in flight: restarting to add it throws away running
  # PC1/PC2 work.
  admin "$MINER_HOST" "sudo -u ${LOTUS_USER_REMOTE} -H env LOTUS_PATH=${LOTUS_PATH_REMOTE} LOTUS_MINER_PATH=${LOTUS_MINER_PATH_REMOTE} C2_512M_BASE_MIN_MEMORY=3221225472 nohup /usr/local/bin/lotus-miner run --nosync > /tmp/lotus-miner.log 2>&1 < /dev/null & disown"
  local waited=0
  until remote_miner info >/dev/null 2>&1; do
    sleep 15; waited=$((waited + 15))
    [ "$waited" -lt 600 ] || die "lotus-miner still not up after 10m; check /tmp/lotus-miner.log on ${MINER_HOST}"
  done
  echo "lotus-miner API is up after ${waited}s"
}

# Ansible only installs lotus-miner on preminers. Copy it via a temp file and
# check the checksum, so an interrupted copy can't leave a truncated binary
# that later runs pass over.
copy_miner_binary() {
  log "Copying lotus-miner from ${BINARY_SOURCE_HOST} to ${MINER_HOST}"
  local want got
  want=$(admin "$BINARY_SOURCE_HOST" "sha256sum /usr/local/bin/lotus-miner" | awk '{print $1}')
  admin "$BINARY_SOURCE_HOST" "cat /usr/local/bin/lotus-miner" | admin "$MINER_HOST" "cat > /tmp/lotus-miner.partial"
  got=$(admin "$MINER_HOST" "sha256sum /tmp/lotus-miner.partial" | awk '{print $1}')
  if [ -z "$want" ] || [ "$want" != "$got" ]; then
    admin "$MINER_HOST" "rm -f /tmp/lotus-miner.partial"
    die "lotus-miner copy failed checksum (want ${want:-?}, got ${got:-?})"
  fi
  admin "$MINER_HOST" "sudo install -m 755 /tmp/lotus-miner.partial /usr/local/bin/lotus-miner && rm -f /tmp/lotus-miner.partial"
}

cmd_init_miner() {
  local fund_amount="${1:?usage: init-miner <owner-fund-tfil>}"

  if remote "$MINER_HOST" test -f "${LOTUS_MINER_PATH_REMOTE}/config.toml" 2>/dev/null; then
    echo "A miner repo already exists at ${LOTUS_MINER_PATH_REMOTE} on ${MINER_HOST}; not re-initializing." >&2
    echo "Remove it first if you really want a fresh miner." >&2
    remote_miner info 2>/dev/null | grep '^Miner:' || true
    return
  fi

  remote "$MINER_HOST" test -x /usr/local/bin/lotus-miner 2>/dev/null || copy_miner_binary
  cmd_fetch_params

  log "Creating an owner wallet and funding it with ${fund_amount} tFIL from the faucet"
  capture remote_lotus wallet new bls
  local owner_addr="$out" fund_cid
  echo "owner wallet: ${owner_addr}"
  fund_cid=$(faucet_send "$owner_addr" "$fund_amount")

  # --owner explicitly: otherwise lotus-miner init uses the daemon's default
  # wallet, which is only the new one if no default existed yet.
  log "lotus-miner init --sector-size=${SECTOR_SIZE} --owner=${owner_addr}"
  capture remote_miner init --sector-size="$SECTOR_SIZE" --owner="$owner_addr" --from="$owner_addr" --nosync
  echo "$out"

  cmd_ensure_running

  local miner_id daemon_peer miner_peer
  miner_id=$(miner_addr)
  daemon_peer=$(remote_lotus net id 2>/dev/null || true)
  miner_peer=$(remote_miner net id 2>/dev/null || true)
  doc_block "lotus wallet new bls
lotus send --from <faucet> ${owner_addr} ${fund_amount}
lotus-miner init --sector-size=${SECTOR_SIZE} --owner=${owner_addr} --from=${owner_addr} --nosync" \
    "MinerID: ${miner_id:-unknown}
Owner/worker: ${owner_addr} (funded in ${fund_cid})
Daemon PeerID: ${daemon_peer:-unknown}
Miner PeerID: ${miner_peer:-unknown}"
  echo
  echo "For the other subcommands: export MINER_ADDR=${miner_id}"
}

cmd_fund() {
  require_miner
  local amount="${1:?usage: fund <amount-tfil>}" owner cid
  # The first column of `actor control list` is the row name ("owner"); the
  # address is the key column, shown in full only with --verbose.
  owner=$({ remote_miner actor control list --verbose 2>/dev/null || true; } | awk '$1=="owner"{print $3; exit}')
  [ -n "$owner" ] || die "could not find the miner's owner address (is lotus-miner running on ${MINER_HOST}?)"
  cid=$(faucet_send "$owner" "$amount")
  doc_block "lotus send --from <faucet> ${owner} ${amount}" "TX: ${cid}"
}

cmd_migration_check() {
  local addr="${1:-}" nv head actor
  [ -n "$addr" ] || addr="$MINER_ADDR"
  [ -n "$addr" ] || die "usage: migration-check <actor-address> (or set MINER_ADDR)"
  capture remote_lotus state network-version; nv="$out"
  capture remote_lotus chain head; head="$out"
  capture remote_lotus state get-actor "$addr"; actor="$out"
  printf '%s\n%s\n%s\n' "$nv" "$head" "$actor"
  doc_block "lotus state network-version
lotus chain head
lotus state get-actor ${addr}" "${nv}
head: ${head}
${actor}"
}

cmd_pledge() {
  require_miner
  local count="${1:?usage: pledge <count>}" i sectors=()
  for i in $(seq 1 "$count"); do
    log "Pledging sector ${i}/${count}"
    capture remote_miner sectors pledge
    echo "$out"
    sectors+=("$(awk '/Created CC sector/{print $NF}' <<<"$out")")
  done
  doc_block "lotus-miner sectors pledge   # x${count}" "created CC sectors: ${sectors[*]}"
}

cmd_withdraw() {
  require_miner
  local amount="${1:?usage: withdraw <amount-tfil>}"
  capture remote_miner actor withdraw "$amount"
  echo "$out"
  doc_block "lotus-miner actor withdraw ${amount}" "TX: $(extract_cids <<<"$out" | tail -n1)
$(grep -i 'withdrew' <<<"$out" || true)"
}

cmd_terminate() {
  require_miner
  [ "$#" -ge 1 ] || die "usage: terminate <sectorNum...>"
  local s cmds="" tries=0
  for s in "$@"; do
    capture remote_miner sectors terminate --really-do-it "$s"
    cmds+="lotus-miner sectors terminate --really-do-it ${s}"$'\n'
  done
  # The terminations reach the batcher asynchronously; flush can briefly say
  # nothing is queued yet.
  until out=$(remote_miner sectors terminate flush 2>&1); do
    tries=$((tries + 1))
    if ! grep -q 'no sectors were queued' <<<"$out" || [ "$tries" -ge 4 ]; then
      printf '%s\n' "$out" >&2; die "sectors terminate flush failed"
    fi
    sleep 15
  done
  echo "$out"
  doc_block "${cmds}lotus-miner sectors terminate flush" "TX: $(extract_cids <<<"$out" | tail -n1)"
}

# Sectors must be chain-Active (past their first WindowPoSt), not just Proving
# locally, or lotus-miner refuses with "sector N is not active". It also
# silently skips sectors whose new expiration would be capped or fall within
# --tolerance (default 7 days) of the current one, printing "nothing to extend"
# and exiting 0, so check for the success line.
cmd_extend() {
  require_miner
  [ "$#" -ge 1 ] || die "usage: extend <sectorNum...>"
  local flags=(--really-do-it)
  [ -z "$EXTEND_EPOCHS" ] || flags+=(--extension "$EXTEND_EPOCHS")
  capture remote_miner sectors extend "${flags[@]}" "$@"
  echo "$out"
  grep -q 'sectors extended' <<<"$out" || die "no sectors were extended (see output above)"
  doc_block "lotus-miner sectors extend ${flags[*]} $*" "$(extract_cids <<<"$out" | sed 's/^/TX: /')
$(grep 'sectors extended' <<<"$out")"
}

# Without --publish-now these commands ask "publish now? (yes/no)" and fail on
# EOF over ssh. If nothing is queued they fail with "no sectors to publish".
cmd_precommit_batch() {
  require_miner
  capture remote_miner sectors batching precommit --publish-now
  echo "$out"
  doc_block "lotus-miner sectors batching precommit --publish-now" "$out"
}

cmd_commit_batch() {
  require_miner
  capture remote_miner sectors batching commit --publish-now
  echo "$out"
  doc_block "lotus-miner sectors batching commit --publish-now" "$out"
}

# `actor control set` replaces the miner's whole on-chain control address list,
# and each address must already exist on chain. The addresses get no roles on
# chain: WindowPoSt uses any control address automatically, while deal
# publishing uses whichever one is listed under DealPublishControl in the
# miner's config.toml [Addresses] (only relevant once a market node runs).
cmd_control_addresses() {
  require_miner
  local addrs=("$@") a funding=""
  if [ "${#addrs[@]}" -eq 0 ]; then
    for _ in 1 2; do
      capture remote_lotus wallet new bls; a="$out"
      funding+="${a}: $(faucet_send "$a" "$CONTROL_FUND_TFIL")"$'\n'
      addrs+=("$a")
    done
  fi
  capture remote_miner actor control set --really-do-it "${addrs[@]}"
  echo "$out"
  local cid; cid=$(extract_cids <<<"$out" | tail -n1)
  [ -z "$cid" ] || capture remote_lotus state wait-msg --timeout 5m "$cid"
  capture remote_miner actor control list; echo "$out"
  doc_block "lotus-miner actor control set --really-do-it ${addrs[*]}" "${funding:+funded with ${CONTROL_FUND_TFIL} tFIL each:
${funding}}TX: ${cid}
${out}"
}

sub="${1:-}"; shift || true
case "$sub" in
  fetch-params)      cmd_fetch_params "$@" ;;
  ensure-running)    cmd_ensure_running "$@" ;;
  init-miner)        cmd_init_miner "$@" ;;
  fund)              cmd_fund "$@" ;;
  migration-check)   cmd_migration_check "$@" ;;
  pledge)            cmd_pledge "$@" ;;
  withdraw)          cmd_withdraw "$@" ;;
  terminate)         cmd_terminate "$@" ;;
  extend)            cmd_extend "$@" ;;
  precommit-batch)   cmd_precommit_batch "$@" ;;
  commit-batch)      cmd_commit_batch "$@" ;;
  control-addresses) cmd_control_addresses "$@" ;;
  *) die "usage: $0 <fetch-params|ensure-running|init-miner|fund|migration-check|pledge|withdraw|terminate|extend|precommit-batch|commit-batch|control-addresses> [args...]" ;;
esac
