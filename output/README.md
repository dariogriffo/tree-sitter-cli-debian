# Tree-sitter CLI

**Develop, test, and use Tree-sitter grammars from the command line.**

![GitHub Release](https://img.shields.io/github/v/release/tree-sitter/tree-sitter?display_name=tag)
![GitHub License](https://img.shields.io/github/license/tree-sitter/tree-sitter)

## About

Tree-sitter is a parser generator tool and an incremental parsing library. It
can build a concrete syntax tree for a source file and efficiently update the
syntax tree as the source file is edited. Tree-sitter aims to be:

- **General** enough to parse any programming language
- **Fast** enough to parse on every keystroke in a text editor
- **Robust** enough to provide useful results even in the presence of syntax
  errors
- **Dependency-free** so that the runtime library (which is written in pure C)
  can be embedded in any application

This package provides the `tree-sitter` command.

**[Read the documentation](https://tree-sitter.github.io/tree-sitter/)**

## Runtime requirements

The `tree-sitter` binary itself has no dependencies beyond the C library, but
some commands need tools that must be present at runtime:

- To generate a parser from a grammar, `tree-sitter generate` runs `grammar.js`
  with [node](https://nodejs.org) by default. Pass `--js-runtime native` (or set
  `TREE_SITTER_JS_RUNTIME=native`) to use the built-in QuickJS runtime instead.
- To build, run and test parsers you need a C (and, for some grammars, C++)
  compiler, e.g. `sudo apt install build-essential`.
- `tree-sitter build --wasm` downloads the wasi-sdk toolchain on first use
  (amd64 and arm64 only).
- `tree-sitter playground` serves a local web playground and opens it in your
  browser (amd64 and arm64 embed the playground assets; armhf and i386 load
  them from tree-sitter.github.io).

## Commands

```
init-config     Generate a default config file
init            Initialize a grammar repository
generate        Generate a parser
build           Compile a parser
parse           Parse files
test            Run a parser's tests
version         Display or increment the version of a grammar
fuzz            Fuzz a parser
query           Search files using a syntax tree query
highlight       Highlight a file
tags            Generate a list of tags
playground      Start local playground for a parser in the browser
dump-languages  Print info about all known language parsers
complete        Generate shell completions
```

## Shell completions

This package installs completions for bash, fish, zsh and nushell
automatically. They are generated with `tree-sitter complete --shell <shell>`,
which also supports elvish and PowerShell if you need them.

## Documentation

- [Documentation site](https://tree-sitter.github.io/tree-sitter/)
- [Creating parsers](https://tree-sitter.github.io/tree-sitter/creating-parsers)
- [Release notes](https://github.com/tree-sitter/tree-sitter/releases)
- [Upstream repository](https://github.com/tree-sitter/tree-sitter)
