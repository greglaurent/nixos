# Home-manager user packages: dev toolchains + LSP servers, paired with Doom
# (dots/doom via users/greg/emacs.nix). Per language: the toolchain plus the
# LSP server Doom's eglot drives. Doom modules with +lsp (nix/rust/cc/python/
# js/lua/sh) auto-wire eglot; typst/markdown/toml/sql are registered by hand in
# config.el but still need their servers here.
{ pkgs, lib, ... }:
{
  home.packages = with pkgs; [
    nixd
    nixfmt

    # Rust — stable from nixpkgs, NOT rustup. rustup unpacks each toolchain into
    # ~/.rustup and bakes its own store path into it (patchelf'd rustc, a wrapped
    # gcc-ld/ld.lld). ~/.rustup is not a GC root, so every nixpkgs bump of rustup
    # or glibc orphans those paths and nix.gc (modules/nixos/system.nix) collects
    # them 30 days later, breaking every installed toolchain. A nix-built toolchain
    # is a store path in this generation and cannot be collected. Projects needing
    # nightly pin it in their own rust-toolchain.toml and get it from a flake
    # devShell via direnv — nightly never lands in the system profile.
    cargo
    rustc
    clippy
    rustfmt
    (lib.hiPrio rust-analyzer)   # real rust-analyzer instead of proxy shim
    cargo-deny                   # dependency license/advisory/ban linting (deny.toml)
    cargo-nextest                # faster test runner (`cargo nextest run`)

    # C/C++
    clang-tools

    # Python
    python3
    pyright
    ruff

    # JavaScript / TypeScript
    nodejs
    pnpm
    typescript-language-server
    vscode-langservers-extracted # html/css/json LSPs + eslint

    # Lua
    luarocks
    lua-language-server

    # Typst
    typst
    tectonic
    tinymist

    # Shell
    shellcheck
    bash-language-server

    # Markup Formats
    marksman
    yaml-language-server
    taplo
    sqls
    epubcheck        # EPUB3 validation (XHTML/OPF/NCX conformance)
    pandoc           # Org export via ox-pandoc (docx/epub/… ); the backend is inert without it

    # tree-sitter
    tree-sitter

    # Wayland diagnostics (wayland-info: list compositor globals/protocols)
    wayland-utils
  ];
}
