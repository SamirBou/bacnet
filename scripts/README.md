Build scripts for ARM payloads

Usage

- Ensure Docker Desktop is installed and supports multi-platform emulation.
- Run:

```
./scripts/build-arm.sh
```

The script will build the bacnet-stack (branch `bacnet-stack-1.0`) inside an emulated `linux/arm64` container and copy resulting binaries to `payloads-aarch64/` in the repository root.

Notes

- This script adds built binaries to `payloads-aarch64/` (not `payloads/`) so you can inspect and test before replacing existing payloads.
- The script does not commit any changes; run `git add`/`git commit` yourself when ready.
