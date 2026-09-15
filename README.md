![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/dariogriffo/tree-sitter-cli-debian/total)
![GitHub Downloads (all assets, latest release)](https://img.shields.io/github/downloads/dariogriffo/tree-sitter-cli-debian/latest/total)
![GitHub Release](https://img.shields.io/github/v/release/dariogriffo/tree-sitter-cli-debian)
![GitHub Release Date](https://img.shields.io/github/release-date/dariogriffo/tree-sitter-cli-debian)

<h1>
   <p align="center">
     <a href="https://tree-sitter.github.io/tree-sitter/"><img src="https://github.com/dariogriffo/tree-sitter-cli-debian/blob/main/tree-sitter.png" alt="Tree-sitter Logo" width="128" style="margin-right: 20px"></a>
     <a href="https://www.debian.org/"><img src="https://github.com/dariogriffo/tree-sitter-cli-debian/blob/main/debian-logo.png" alt="Debian Logo" width="104" style="margin-left: 20px"></a>
     <br>tree-sitter-cli for Debian
   </p>
</h1>
<p align="center">
 The Tree-sitter CLI generates, builds, tests and runs Tree-sitter parsers from the command line.
</p>

# tree-sitter-cli for Debian

This repository contains build scripts to produce the _unofficial_ Debian packages
(.deb) for the [Tree-sitter CLI](https://github.com/tree-sitter/tree-sitter/) hosted at [deb.griffo.io](https://deb.griffo.io)

Currently supported Debian distros are:
- Bookworm (v12)
- Trixie (v13)
- Forky (v14)
- Sid (testing)

Currently supported Ubuntu distros are:
- Jammy (22.04)
- Noble (24.04)
- Questing (25.10)
- Resolute (26.04)

Supported architectures:
- amd64 (x86_64) - All distributions
- arm64 (aarch64) - All distributions
- armhf (ARMv7 hard-float) - All distributions
- i386 (x86) - All distributions

These are all the Linux architectures upstream publishes binaries for, except
big-endian powerpc64, which is not a Debian release architecture.

> **The package is called `tree-sitter-cli`, the command it installs is `tree-sitter`.**

The packages include the `tree-sitter` binary and shell completions for bash,
fish, zsh and nushell. Upstream ships no man page; run `tree-sitter --help` for
the command reference and see the
[documentation](https://tree-sitter.github.io/tree-sitter/) for the rest.

### Why the binary is compiled from source

Upstream's prebuilt Linux binaries are built on Ubuntu 24.04 and require
glibc 2.39, so they do not run on Bookworm (glibc 2.36) or Jammy (glibc 2.35).
Nothing in tree-sitter needs glibc 2.39, so this repository compiles the
upstream release tag with `cargo` inside an Ubuntu 22.04 container (the oldest
glibc of all supported suites) and ships that one binary per architecture to
every suite. The build fails if the binary ever requires a glibc newer than
2.35.

The build mirrors upstream's release builds: amd64 and arm64 are compiled with
the `wasm` feature (loading Wasm parsers) and embed the web playground, while
armhf and i386 use the default features, exactly like upstream's binaries for
those architectures.

> ℹ️ The package only depends on the C library (`libc6`, `libgcc-s1`), like
> upstream's release binary. Some commands need extra tools at runtime that are
> **not** installed automatically: building or testing a parser needs a C
> compiler (`sudo apt install build-essential`), and `tree-sitter generate`
> runs `grammar.js` with `node` unless you pass `--js-runtime native` to use the
> built-in QuickJS runtime.

This is an unofficial community project to provide a package that's easy to
install on Debian. If you're looking for the tree-sitter source code, see
[tree-sitter](https://github.com/tree-sitter/tree-sitter/).

## Install/Update

📖 **Step-by-step install guide:** [Debian](https://deb.griffo.io/install-latest-tree-sitter-cli-in-debian.html) · [Ubuntu](https://deb.griffo.io/install-latest-tree-sitter-cli-in-ubuntu.html)

### The Debian way

> ⚠️ **From 1 October 2026, apt access requires a yearly subscription**
> ([deb.griffo.io](https://deb.griffo.io)). To use this tool for free, download
> the .deb from the [Releases](https://github.com/dariogriffo/tree-sitter-cli-debian/releases) page
> and install it manually (see below).

```sh
sudo install -d -m 0755 /etc/apt/keyrings
curl -fsSL https://deb.griffo.io/EA0F721D231FDD3A0A17B9AC7808B4DD62C41256.asc | sudo gpg --dearmor --yes -o /etc/apt/keyrings/deb.griffo.io.gpg
echo "deb [signed-by=/etc/apt/keyrings/deb.griffo.io.gpg] https://deb.griffo.io/apt $(lsb_release -sc 2>/dev/null) main" | sudo tee /etc/apt/sources.list.d/deb.griffo.io.list
sudo apt update
sudo apt install -y tree-sitter-cli
```

### Manual Installation

1. Download the .deb package for your Debian version available on
   the [Releases](https://github.com/dariogriffo/tree-sitter-cli-debian/releases) page.
2. Install the downloaded .deb package.

```sh
sudo dpkg -i <filename>.deb
```
## Updating

To update to a new version, just follow any of the installation methods above. There's no need to uninstall the old version; it will be updated correctly.

## Building

Building requires Docker. The binary for each architecture is compiled once
(`build_binary.sh`, cached in `tree-sitter-linux-<arch>/`) and reused for every
suite.

### Build for single architecture
```sh
./build.sh <tree_sitter_cli_version> <build_version> <architecture>
# Example: ./build.sh 0.27.0 1 arm64
```

### Build for all architectures
```sh
./build.sh <tree_sitter_cli_version> <build_version> all
# Example: ./build.sh 0.27.0 1 all
```

## Roadmap

- [x] Produce a .deb package on GitHub Releases
- [x] Set up a debian mirror for easier updates
- [x] Multi-architecture support (amd64, arm64, armhf, i386)

## Disclaimer

- This repo is not open for issues related to tree-sitter. This repo is only for _unofficial_ Debian packaging.
