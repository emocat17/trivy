#!/bin/bash

# Check arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <target> <output_directory>"
    echo "Example: $0 /home/Gitworks/trivy/Test/NanoLog-master /home/Gitworks/trivy/Output"
    exit 1
fi

TARGET="$1"
OUTPUT_DIR="$2"
TRIVY_BIN="./trivy"

# Check if trivy binary exists
if [ ! -f "$TRIVY_BIN" ]; then
    echo "Error: trivy binary not found in current directory."
    exit 1
fi

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Determine Scan Type and Basename
if [ -e "$TARGET" ]; then
    # It exists as a file or directory -> FS Scan
    SCAN_TYPE="fs"
    # Extract basename for filename (remove trailing slash if present)
    BASENAME=$(basename "${TARGET%/}")

    # ==========================================
    # Auto-Dependency Generation (Heuristic)
    # ==========================================
    if [ -d "$TARGET" ]; then
        ./auto_gen_deps.sh "$TARGET"
    fi

else
    # Does not exist locally -> Assume Image Scan
    SCAN_TYPE="image"
    # Sanitize image name for filename (replace : and / with _)
    BASENAME=$(echo "$TARGET" | tr '/:' '__')
fi

# Define Output Files
JSON_OUT="${OUTPUT_DIR}/${BASENAME}.json"
MD_OUT="${OUTPUT_DIR}/${BASENAME}.md"
SBOM_OUT="${OUTPUT_DIR}/${BASENAME}.cdx.json"

echo "=========================================="
echo "Target: $TARGET"
echo "Type: $SCAN_TYPE"
echo "Output Directory: $OUTPUT_DIR"
echo "=========================================="

# 1. Generate JSON Report
echo "[1/3] Generating JSON Report (Vuln, Secret, Misconfig, License)..."
"$TRIVY_BIN" "$SCAN_TYPE" \
    --scanners vuln,secret,misconfig,license \
    --format json \
    --output "$JSON_OUT" \
    "$TARGET"

if [ $? -eq 0 ]; then
    echo "✅ JSON Report saved to: $JSON_OUT"
else
    echo "❌ JSON Scan failed."
    exit 1
fi

# 2. Generate Table Report (saved as MD)
echo "[2/3] Generating Markdown Table Report..."
"$TRIVY_BIN" "$SCAN_TYPE" \
    --scanners vuln,secret,misconfig,license \
    --format table \
    --output "$MD_OUT" \
    "$TARGET"

if [ $? -eq 0 ]; then
    echo "✅ Markdown Report saved to: $MD_OUT"
else
    echo "❌ Table/Markdown Scan failed."
    exit 1
fi

# 3. Generate SBOM (CycloneDX)
echo "[3/3] Generating SBOM (CycloneDX)..."
"$TRIVY_BIN" "$SCAN_TYPE" \
    --format cyclonedx \
    --output "$SBOM_OUT" \
    "$TARGET"

if [ $? -eq 0 ]; then
    echo "✅ SBOM saved to: $SBOM_OUT"
else
    echo "❌ SBOM Generation failed."
    exit 1
fi

echo "=========================================="
echo "All scans completed successfully."
