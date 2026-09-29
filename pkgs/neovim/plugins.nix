{ pkgs }:
with pkgs.vimPlugins;
let
  treesitter = nvim-treesitter.withPlugins (
    plugins:
    with plugins;
    [
      nix
      lua
      fennel
      c_sharp
      javascript
      typescript
      tsx
      clojure
      regex
      bash
      json
      yaml
      python
    ]
  );
in
{
  # Plugins loaded at startup (always on rtp).
  # Keep this minimal — only plugins that must be available
  # before init.lua runs or that cannot be deferred.
  start = [
    lze

    alpha-nvim
    snacks-nvim
    nui-nvim
    nvim-notify
    nvim-web-devicons
    vim-startuptime
    which-key-nvim

    # Treesitter parsers must be on the rtp at startup so that
    # neotest's headless subprocess can find them.
    treesitter

    # Schema catalog for JSON/YAML LSPs (OpenAPI, etc.)
    SchemaStore-nvim

    # Library plugin required synchronously in the OmniSharp LSP on_attach;
    # must be on the rtp before the server attaches (no setup needed).
    omnisharp-extended-lsp-nvim
  ];

  # Plugins loaded on demand via lze (packadd).
  # Each entry here is a vim plugin derivation.
  # Lazy-load triggers are defined in lua/plugins/*.lua specs.
  opt = [
    blink-cmp
    catppuccin-nvim
    comment-nvim
    conform-nvim
    conjure
    dial-nvim
    edgy-nvim
    flash-nvim
    fzf-lua
    git-conflict-nvim
    gitsigns-nvim
    grug-far-nvim
    indent-blankline-nvim
    lualine-nvim
    mini-nvim
    neo-tree-nvim
    noice-nvim
    nvim-dap
    nvim-dap-ui
    nvim-dap-virtual-text
    nvim-lint
    nvim-surround
    nvim-ufo
    nvim-paredit
    nvim-parinfer
    neotest
    neotest-vitest
    FixCursorHold-nvim
    todo-comments-nvim
    trouble-nvim
    smart-splits-nvim
    zellij-nav-nvim
  ];
}
