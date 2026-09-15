tree_sitter_cli_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$tree_sitter_cli_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <tree_sitter_cli_version> <build_version> [architecture]"
    echo "Example: $0 0.27.0 1 arm64"
    echo "Example: $0 0.27.0 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armhf, i386, all"
    exit 1
fi

# Upstream tags carry a "v" prefix (e.g. v0.27.0).
UPSTREAM_URL="https://github.com/tree-sitter/tree-sitter/releases/download/v${tree_sitter_cli_VERSION}"

# Completions are generated from upstream's amd64 release binary; they do not
# depend on the target architecture. That binary needs GLIBC_2.39, which the
# build host (ubuntu-latest, or any trixie/noble machine) has.
COMPLETIONS_RELEASE="tree-sitter-linux-x64"

# The packaged binary is NOT upstream's release binary: that one requires
# GLIBC_2.39 and does not run on bookworm or jammy. build_binary.sh compiles it
# from the upstream source tag on jammy instead, so a single binary per
# architecture runs on every suite. It is linked against glibc and libgcc_s,
# hence the dependencies (the libc6 floor is read from the compiled binary).
get_package_depends() {
    local arch=$1
    echo "libc6 (>= $(cat "tree-sitter-linux-${arch}/glibc-version")), libgcc-s1"
}

# Generate the shell completions once, from upstream's amd64 binary.
generate_completions() {
    if [ -f completions/tree-sitter.bash ] && [ -f completions/tree-sitter.fish ] \
        && [ -f completions/_tree-sitter ] && [ -f completions/tree-sitter.nu ]; then
        echo "Using existing completions/"
        return 0
    fi

    echo "Generating shell completions from ${COMPLETIONS_RELEASE}..."
    rm -rf completions "$COMPLETIONS_RELEASE" || true
    mkdir -p completions "$COMPLETIONS_RELEASE"

    # The asset is a bare gzipped binary, not a tarball.
    if ! wget -q "${UPSTREAM_URL}/${COMPLETIONS_RELEASE}.gz" -O "${COMPLETIONS_RELEASE}/tree-sitter.gz"; then
        echo "❌ Failed to download ${COMPLETIONS_RELEASE}.gz for completion generation"
        return 1
    fi
    gunzip "${COMPLETIONS_RELEASE}/tree-sitter.gz"
    chmod +x "${COMPLETIONS_RELEASE}/tree-sitter"

    "./${COMPLETIONS_RELEASE}/tree-sitter" complete --shell bash    > completions/tree-sitter.bash
    "./${COMPLETIONS_RELEASE}/tree-sitter" complete --shell zsh     > completions/_tree-sitter
    "./${COMPLETIONS_RELEASE}/tree-sitter" complete --shell fish    > completions/tree-sitter.fish
    "./${COMPLETIONS_RELEASE}/tree-sitter" complete --shell nushell > completions/tree-sitter.nu
    rm -rf "$COMPLETIONS_RELEASE"

    for f in completions/tree-sitter.bash completions/_tree-sitter completions/tree-sitter.fish completions/tree-sitter.nu; do
        if [ ! -s "$f" ]; then
            echo "❌ Completion file $f is empty"
            return 1
        fi
    done
    echo "✅ Completions generated"
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1

    case "$build_arch" in
        amd64|arm64|armhf|i386) ;;
        *)
            echo "❌ Unsupported architecture: $build_arch"
            echo "Supported architectures: amd64, arm64, armhf, i386"
            return 1
            ;;
    esac

    echo "Building for architecture: $build_arch"

    if ! ./build_binary.sh "$tree_sitter_cli_VERSION" "$build_arch"; then
        echo "❌ Failed to prepare tree-sitter binary for $build_arch"
        return 1
    fi

    local package_depends
    package_depends=$(get_package_depends "$build_arch")

    # The binary is compiled against jammy's glibc (2.35), so it works on
    # every Debian suite we target.
    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$tree_sitter_cli_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "tree-sitter-cli-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg tree_sitter_cli_VERSION="$tree_sitter_cli_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg TS_BINARY_DIR="tree-sitter-linux-$build_arch" \
            --build-arg PACKAGE_DEPENDS="$package_depends"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "tree-sitter-cli-$dist-$build_arch")"
        if ! docker cp "$id:/tree-sitter-cli_$FULL_VERSION.deb" - > "./tree-sitter-cli_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./tree-sitter-cli_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    echo "✅ Successfully built for $build_arch"
    return 0
}

if ! generate_completions; then
    exit 1
fi

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building tree-sitter-cli $tree_sitter_cli_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    ARCHITECTURES=("amd64" "arm64" "armhf" "i386")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la tree-sitter-cli_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
