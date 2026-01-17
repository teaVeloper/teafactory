#!/usr/bin/env bash
set -euo pipefail

MEM="${MEM:-8192}"
CPUS="${CPUS:-4}"
DISK_SIZE="${DISK_SIZE:-20G}"
SSH_PORT="${SSH_PORT:-2222}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
REPO_DIR_DEFAULT="$(cd -- "$SCRIPT_DIR/.." >/dev/null 2>&1 && pwd)"
REPO_DIR="${REPO_DIR:-$REPO_DIR_DEFAULT}"

VM_DIR="${VM_DIR:-$SCRIPT_DIR/.vm}"
mkdir -p "$VM_DIR"

BASE_DISK="${BASE_DISK:-$VM_DIR/base.qcow2}"

ISO_PATH="${ISO_PATH:-$VM_DIR/arch.iso}"
ISO_PATH="$(readlink -f "$ISO_PATH" 2>/dev/null || realpath "$ISO_PATH")"

OVMF_CODE="${OVMF_CODE:-$VM_DIR/firmware/OVMF_CODE.4m.fd}"
OVMF_VARS_TEMPLATE="${OVMF_VARS_TEMPLATE:-$VM_DIR/firmware/OVMF_VARS.4m.fd}"
OVMF_VARS_BASE="${OVMF_VARS_BASE:-$VM_DIR/vars-base.fd}"

[[ -f "$ISO_PATH" ]] || { echo "ERROR: ISO not found: $ISO_PATH" >&2; exit 2; }
[[ -d "$REPO_DIR" ]] || { echo "ERROR: Repo dir not found: $REPO_DIR" >&2; exit 2; }
[[ -f "$OVMF_CODE" ]] || { echo "ERROR: OVMF_CODE not found: $OVMF_CODE" >&2; exit 2; }
[[ -f "$OVMF_VARS_TEMPLATE" ]] || { echo "ERROR: OVMF_VARS template not found: $OVMF_VARS_TEMPLATE" >&2; exit 2; }

if [[ ! -f "$BASE_DISK" ]]; then
  echo "[*] Creating base disk: $BASE_DISK ($DISK_SIZE)"
  qemu-img create -f qcow2 "$BASE_DISK" "$DISK_SIZE" >/dev/null
else
  echo "[*] Using existing base disk: $BASE_DISK"
fi

if [[ ! -f "$OVMF_VARS_BASE" ]]; then
  cp -f "$OVMF_VARS_TEMPLATE" "$OVMF_VARS_BASE"
fi

exec qemu-system-x86_64 \
  -enable-kvm -cpu host -smp "$CPUS" -m "$MEM" \
  -machine q35 \
  -drive if=pflash,format=raw,readonly=on,file="$OVMF_CODE" \
  -drive if=pflash,format=raw,file="$OVMF_VARS_BASE" \
  -drive file="$BASE_DISK",if=virtio,format=qcow2,cache=writeback \
  -cdrom "$ISO_PATH" -boot order=d,menu=on \
  -netdev "user,id=n1,hostfwd=tcp:127.0.0.1:${SSH_PORT}-:22" \
  -device virtio-net-pci,netdev=n1 \
  -virtfs "local,path=$REPO_DIR,mount_tag=archsetup,security_model=none,id=archsetup" \
  -display gtk
