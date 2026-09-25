return {
  cmd = { 'nixd' },
  filetypes = { 'nix' },
  root_markers = { 'flake.nix', '.git' },
  settings = {
    nixpkgs = {
      expr = 'import <nixpkgs> { }',
    },
    formatting = { command = { 'nixfmt' } },
  },
}
