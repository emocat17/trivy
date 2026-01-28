#!/bin/bash

TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
    echo "Usage: $0 <target_directory>"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Skipping auto-generation: Target is not a directory."
    exit 0
fi

echo "🔍 [Auto-Gen] Analyzing project in: $TARGET_DIR"

# ==========================================
# 1. Python Strategy
# ==========================================
if compgen -G "${TARGET_DIR}/*.py" > /dev/null; then
    echo "   -> Detected Python source files."
    if [ ! -f "${TARGET_DIR}/requirements.txt" ] && [ ! -f "${TARGET_DIR}/Pipfile.lock" ] && [ ! -f "${TARGET_DIR}/poetry.lock" ]; then
        echo "   -> No dependency file found. Attempting to generate requirements.txt..."
        
        if ! command -v pipreqs &> /dev/null; then
            echo "      Installing pipreqs..."
            pip install pipreqs -q
        fi
        
        if command -v pipreqs &> /dev/null; then
            pipreqs "$TARGET_DIR" --savepath "${TARGET_DIR}/requirements.txt" --force
            echo "      ✅ Generated requirements.txt"
        else
            echo "      ⚠️ Failed to install/run pipreqs. Skipping Python dependency generation."
        fi
    else
        echo "   -> Dependency file already exists."
    fi
fi

# ==========================================
# 2. Node.js Strategy
# ==========================================
if [ -f "${TARGET_DIR}/package.json" ]; then
    echo "   -> Detected package.json."
    if [ ! -f "${TARGET_DIR}/package-lock.json" ] && [ ! -f "${TARGET_DIR}/yarn.lock" ]; then
        echo "   -> No lockfile found. Generating package-lock.json..."
        if command -v npm &> /dev/null; then
            (cd "$TARGET_DIR" && npm install --package-lock-only --silent)
            echo "      ✅ Generated package-lock.json"
        else
            echo "      ⚠️ npm not found. Skipping."
        fi
    else
        echo "   -> Lockfile already exists."
    fi
fi

# ==========================================
# 3. Golang Strategy
# ==========================================
if [ -f "${TARGET_DIR}/go.mod" ]; then
    echo "   -> Detected go.mod."
    if [ ! -f "${TARGET_DIR}/go.sum" ]; then
        echo "   -> Generating go.sum..."
        if command -v go &> /dev/null; then
            (cd "$TARGET_DIR" && go mod tidy)
            echo "      ✅ Generated go.sum"
        else
            echo "      ⚠️ go binary not found. Skipping."
        fi
    else
        echo "   -> go.sum already exists."
    fi
fi

# ==========================================
# 4. C/C++ Strategy (Conan)
# ==========================================
if compgen -G "${TARGET_DIR}/*.c" > /dev/null || compgen -G "${TARGET_DIR}/*.cpp" > /dev/null; then
    echo "   -> Detected C/C++ source files."
    if [ ! -f "${TARGET_DIR}/conan.lock" ]; then
        echo "   -> No conan.lock found."
        
        # Check/Install Conan
        if ! command -v conan &> /dev/null; then
            echo "      Installing conan (this may take a moment)..."
            pip install conan -q
        fi

        if command -v conan &> /dev/null; then
            # If no conanfile exists, create a basic heuristic one
            if [ ! -f "${TARGET_DIR}/conanfile.txt" ] && [ ! -f "${TARGET_DIR}/conanfile.py" ]; then
                echo "      Creating heuristic conanfile.txt (guessing common libs)..."
                # Heuristic: Scan for common includes
                REQUIRES=""
                grep -r "openssl" "$TARGET_DIR" &> /dev/null && REQUIRES="$REQUIRES\nopenssl/1.1.1q"
                grep -r "zlib" "$TARGET_DIR" &> /dev/null && REQUIRES="$REQUIRES\nzlib/1.2.11"
                grep -r "curl" "$TARGET_DIR" &> /dev/null && REQUIRES="$REQUIRES\nlibcurl/7.84.0"
                
                if [ -n "$REQUIRES" ]; then
                    echo -e "[requires]$REQUIRES\n\n[generators]\ntxt" > "${TARGET_DIR}/conanfile.txt"
                    echo "      -> Detected potential deps: $REQUIRES"
                else
                    echo "      -> No obvious common libs (openssl/zlib) detected. Skipping conanfile generation."
                fi
            fi

            # Generate Lockfile if conanfile exists (either original or generated)
            if [ -f "${TARGET_DIR}/conanfile.txt" ] || [ -f "${TARGET_DIR}/conanfile.py" ]; then
                echo "      Generating conan.lock..."
                # Try conan v2 command first, then v1
                (cd "$TARGET_DIR" && conan lock create . &> /dev/null || conan lock create . --user=user --channel=channel &> /dev/null)
                
                if [ -f "${TARGET_DIR}/conan.lock" ]; then
                     echo "      ✅ Generated conan.lock"
                else
                     echo "      ⚠️ Failed to generate conan.lock (check conan configuration)."
                fi
            fi
        else
             echo "      ⚠️ Conan not found/installable. Skipping C++ dependency generation."
        fi
    else
        echo "   -> conan.lock already exists."
    fi
fi

echo "🏁 Auto-generation check complete."
