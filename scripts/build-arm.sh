#!/usr/bin/env bash
set -euo pipefail

# Cross-build BACnet payloads for aarch64 (ARM64).
# Usage:
#  ./scripts/build-arm.sh              # use Docker emulation (default)
#  ./scripts/build-arm.sh --host-cross # build on host using aarch64 cross-compiler (no Docker)

WORKDIR="$(pwd)"
IMAGE=ubuntu:22.04

if [ "${1:-}" = "--host-cross" ]; then
  echo "Using host cross-compiler (aarch64) to build payloads"
  export DEBIAN_FRONTEND=noninteractive
  sudo apt-get update
  sudo apt-get install -y --no-install-recommends build-essential git autoconf automake libtool pkg-config ca-certificates wget gcc-aarch64-linux-gnu binutils-aarch64-linux-gnu || true

  # Clone bacnet-stack 1.0
  rm -rf /tmp/srcstack
  git clone --branch bacnet-stack-1.0 https://github.com/bacnet-stack/bacnet-stack.git /tmp/srcstack

  # If this repo contains modified apps, copy them into the stack before building
  if [ -f "$WORKDIR/src/bacnet-stack/apps/readprop/main.c" ]; then
    cp "$WORKDIR/src/bacnet-stack/apps/readprop/main.c" /tmp/srcstack/apps/readprop/main.c || true
  fi
  if [ -f "$WORKDIR/src/bacnet-stack/apps/writeprop/main.c" ]; then
    cp "$WORKDIR/src/bacnet-stack/apps/writeprop/main.c" /tmp/srcstack/apps/writeprop/main.c || true
  fi

  cd /tmp/srcstack
  make clean || true
  export CC=aarch64-linux-gnu-gcc
  # Try parallel build, but fallback to single-threaded on failure
  if ! make -j"$(nproc)" CC="$CC"; then
    echo "Parallel host cross build failed; retrying single-threaded build"
    make -j1 CC="$CC"
  fi

  # Copy produced binaries back to host payloads directory
  mkdir -p "$WORKDIR/payloads-aarch64"
  if [ -d apps ]; then
    for f in apps/*; do
      if [ -f "$f" ]; then
        cp "$f" "$WORKDIR/payloads-aarch64/" || true
      fi
    done
  fi
  echo "Built binaries copied to $WORKDIR/payloads-aarch64"
  exit 0
fi

# Cross-build BACnet payloads for aarch64 (ARM64) using an emulated linux/arm64 container.
# Usage: ./scripts/build-arm.sh

WORKDIR="$(pwd)"
IMAGE=ubuntu:22.04

docker run --rm --platform linux/arm64 -v "$WORKDIR":/work -w /work "$IMAGE" bash -lc '
  set -euo pipefail
  export DEBIAN_FRONTEND=noninteractive
  apt-get update
  apt-get install -y --no-install-recommends build-essential git autoconf automake libtool pkg-config ca-certificates wget

  # Clone bacnet-stack 1.0
  rm -rf /tmp/srcstack
  git clone --branch bacnet-stack-1.0 https://github.com/bacnet-stack/bacnet-stack.git /tmp/srcstack

  # If this repo contains modified apps, copy them into the stack before building
  if [ -f /work/src/bacnet-stack/apps/readprop/main.c ]; then
    cp /work/src/bacnet-stack/apps/readprop/main.c /tmp/srcstack/apps/readprop/main.c || true
  fi
  if [ -f /work/src/bacnet-stack/apps/writeprop/main.c ]; then
    cp /work/src/bacnet-stack/apps/writeprop/main.c /tmp/srcstack/apps/writeprop/main.c || true
  fi

  cd /tmp/srcstack
  make clean || true
  # Try parallel build, but fallback to single-threaded on failure (avoids cc1 segmentation faults under qemu/emulation)
  if ! make -j"$(nproc)"; then
    echo "Parallel build failed; retrying single-threaded build"
    make -j1
  fi

  # Copy produced binaries back to host payloads directory if present
  mkdir -p /work/payloads-aarch64
  if [ -d apps ]; then
    for f in apps/*; do
      if [ -f "$f" ]; then
        cp "$f" /work/payloads-aarch64/ || true
      fi
    done
  fi
  echo "Built binaries copied to /work/payloads-aarch64"
'

echo "If Docker fails, ensure Docker Desktop is installed and experimental platforms are enabled."
