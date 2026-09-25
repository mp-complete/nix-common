return {
  cmd = { 'basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'pyrightconfig.json',
    '.git',
  },
  settings = {
    basedpyright = {
      -- Let ruff own linting and import organizing; pyright only does types.
      disableOrganizeImports = true,
      analysis = {
        typeCheckingMode = 'standard',
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
      },
    },
  },
}
