(fn after []
  (let [trouble (require :trouble)
        key (require :lib.keymap)]
    (trouble.setup {:modes {:lsp {:win {:position :right}}}})
    (key.map :<leader>xx "<cmd>Trouble diagnostics toggle<cr>")))

{:name :trouble.nvim :event :DeferredUIEnter : after}
