(fn after []
  (let [fzf-lua (require :fzf-lua)]
    (fzf-lua.setup {:files {:previewer :bat}})
    (fzf-lua.register_ui_select)))

{:name :fzf-lua :event :DeferredUIEnter :dep_of :trouble.nvim : after}
