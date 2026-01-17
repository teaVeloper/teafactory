#!/usr/bin/env bash
set -euo pipefail

MEM="${MEM:-8192}"
CPUS="${CPUS:-4}"
SSH_PORT="${SSH_PORT:-2222}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_DIR_DEFAULT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
REPO_DIR="${REPO_DIR:-$REPO_DIR_DEFAULT}"

VM_DIR="${VM_DIR:-$SCRIPT_DIR/.vm}"
mkdir -p "$VM_DIR"

BASE_DISK="${BASE_DISK:-$VM_DIR/base.qcow2}"
RUN_DISK="${RUN_DISK:-$VM_DIR/run.qcow2}"

OVMF_CODE="${OVMF_CODE:-$VM_DIR/firmware/OVMF_CODE.4m.fd}"
OVMF_VARS_TEMPLATE="${OVMF_VARS_TEMPLATE:-$VM_DIR/firmware/OVMF_VARS.4m.fd}"
OVMF_VARS_RUN="${OVMF_VARS_RUN:-$VM_DIR/vars-run.fd}"

RESET=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reset) RESET=1; shift ;;
    -h|--help)
      cat <<EOF
Usage: $(basename "$0") [--reset]

--reset  deletes overlay disk + per-run UEFI vars to rollback to pristine base
EOF
      exit 0
      ;;
    *) echo "Unknown arg: $1" >&2; exit 2 ;;
  esac
done

[[ -f "$BASE_DISK" ]] || { echo "ERROR: base disk missing: $BASE_DISK" >&2; exit 2; }
[[ -f "$OVMF_CODE" ]] || { echo "ERROR: OVMF_CODE not found: $OVMF_CODE" >&2; exit 2; }
[[ -f "$OVMF_VARS_TEMPLATE" ]] || { echo "ERROR: OVMF_VARS template not found: $OVMF_VARS_TEMPLATE" >&2; exit 2; }
[[ -d "$REPO_DIR" ]] || { echo "ERROR: repo dir not found: $REPO_DIR" >&2; exit 2; }

if [[ "$RESET" -eq 1 ]]; then
  echo "[*] Resetting overlay + vars"
  rm -f "$RUN_DISK" "$OVMF_VARS_RUN"
fi

if [[ ! -f "$RUN_DISK" ]]; then
  echo "[*] Creating overlay disk: $RUN_DISK (backing: $BASE_DISK)"
  qemu-img create -f qcow2 -F qcow2 -b "$BASE_DISK" "$RUN_DISK" >/dev/null
fi

if [[ ! -f "$OVMF_VARS_RUN" ]]; then
  cp -f "$OVMF_VARS_TEMPLATE" "$OVMF_VARS_RUN"
fi

echo "[*] Booting overlay VM"
echo "[*] SSH: localhost:${SSH_PORT} -> guest:22"
echo "[*] Repo 9p tag: archsetup (guest mount: /host/archsetup)"

exec qemu-system-x86_64 \
  -enable-kvm -cpu host -smp "$CPUS" -m "$MEM" \
  -machine q35 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS_RUN" \
  -drive file="$RUN_DISK",if=virtio,format=qcow2,cache=writeback \
  -boot order=c,menu=on \
  -netdev "user,id=n1,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=n1 \
  -virtfs "local,path=$REPO_DIR,mount_tag=archsetup,security_model=none,id=archsetup" \
  -display gtk

