return {
  cmd = { 'lua-language-server' },
  filetypes = { 'lua' },
  root_markers = { 'stylua.toml', '.luarc.jsonc', '.git' },
  settings = {
    Lua = {
      runtime = {
        version = 'LuaJIT',
      },
      diagnostics = {
        globals = { 'vim', 'Snacks' },
      },
    },
  },
}
