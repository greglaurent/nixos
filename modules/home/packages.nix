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

    # Rust
    rustup
    (lib.hiPrio rust-analyzer)   # real rust-analyzer instead of proxy shim
    cargo-deny                   # dependency license/advisory/ban linting (deny.toml)

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

    # tree-sitter
    tree-sitter
  ];
}
