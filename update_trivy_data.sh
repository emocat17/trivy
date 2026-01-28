#!/usr/bin/env bash
set -euo pipefail
SCAN_PATH="${1:-/home/Gitworks/trivy/Test}"
command -v clashon >/dev/null 2>&1 && clashon || true
./trivy image --download-db-only
./trivy image --download-java-db-only
./trivy fs --scanners misconfig --skip-db-update --skip-java-db-update --exit-code 0 "$SCAN_PATH" >/dev/null || true
command -v clashoff >/dev/null 2>&1 && clashoff || true
