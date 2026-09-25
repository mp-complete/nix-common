(fn lsp-info []
  "Comma-separated names of active LSP clients for the current buffer."
  (let [clients (vim.lsp.get_clients {:bufnr 0})
        names (icollect [_ c (ipairs clients)] c.name)]
    (table.concat names ", ")))

(fn has-lsp []
  (> (length (vim.lsp.get_clients {:bufnr 0})) 0))

(fn after []
  (let [lualine (require :lualine)
        noice (require :noice)]
    (lualine.setup
      {:options {:theme :auto
                 :icons_enabled true
                 :component_separators {:left "" :right ""}
                 :section_separators {:left "" :right ""}
                 :globalstatus true
                 :disabled_filetypes {:statusline [:alpha :dashboard]}}
       :sections {:lualine_a [:mode]
                  :lualine_b [:branch :diff :diagnostics]
                  :lualine_c [{1 :filename
                               :path 1
                               :symbols {:modified " ●"
                                         :readonly " "
                                         :unnamed "[No Name]"
                                         :newfile " [New]"}}]
                  :lualine_x [{1 noice.api.status.mode.get
                               :cond noice.api.status.mode.has
                               :color :Constant}
                              {1 noice.api.status.search.get
                               :cond noice.api.status.search.has
                               :color :DiagnosticInfo}
                              {1 noice.api.status.command.get
                               :cond noice.api.status.command.has
                               :color :Statement}]
                  :lualine_y [{1 lsp-info :icon " " :cond has-lsp}
                              :filetype]
                  :lualine_z [:progress :location]}
       :extensions [:neo-tree :trouble]})))

{:name :lualine.nvim
 :event :DeferredUIEnter
 :after after}
