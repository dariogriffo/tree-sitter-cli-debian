#!/bin/bash
# Compiles the tree-sitter CLI for one architecture inside a jammy container
# (see Dockerfile.build) and leaves it in tree-sitter-linux-<arch>/.
#
# build_debian.sh and build_ubuntu.sh both call this; the binary is compiled
# once per architecture and reused for every suite, so an existing
# tree-sitter-linux-<arch>/ directory is kept as is.
tree_sitter_cli_VERSION=$1
ARCH=$2

if [ -z "$tree_sitter_cli_VERSION" ] || [ -z "$ARCH" ]; then
    echo "Usage: $0 <tree_sitter_cli_version> <architecture>"
    echo "Example: $0 0.27.0 arm64"
    echo "Supported architectures: amd64, arm64, armhf, i386"
    exit 1
fi

OUT_DIR="tree-sitter-linux-${ARCH}"

if [ -f "$OUT_DIR/tree-sitter" ] && [ -f "$OUT_DIR/glibc-version" ] \
    && [ "$(cat "$OUT_DIR/version" 2>/dev/null)" = "$tree_sitter_cli_VERSION" ]; then
    echo "Using existing $OUT_DIR/"
    exit 0
fi

echo "Compiling tree-sitter $tree_sitter_cli_VERSION for $ARCH..."
rm -rf "$OUT_DIR" || true

if ! docker build . -f Dockerfile.build -t "tree-sitter-cli-build-$ARCH" \
    --build-arg tree_sitter_cli_VERSION="$tree_sitter_cli_VERSION" \
    --build-arg ARCH="$ARCH"; then
    echo "❌ Failed to compile tree-sitter for $ARCH"
    exit 1
fi

id="$(docker create "tree-sitter-cli-build-$ARCH")"
mkdir -p "$OUT_DIR"
if ! docker cp "$id:/out/." "$OUT_DIR/"; then
    docker rm "$id" > /dev/null
    echo "❌ Failed to copy the compiled binary for $ARCH"
    exit 1
fi
docker rm "$id" > /dev/null

if [ ! -f "$OUT_DIR/tree-sitter" ] || [ ! -f "$OUT_DIR/glibc-version" ]; then
    echo "❌ Build output for $ARCH is incomplete"
    exit 1
fi
chmod 755 "$OUT_DIR/tree-sitter"
echo "$tree_sitter_cli_VERSION" > "$OUT_DIR/version"

echo "✅ Compiled tree-sitter for $ARCH (requires glibc >= $(cat "$OUT_DIR/glibc-version"))"
