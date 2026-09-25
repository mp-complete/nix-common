(local opts {:messages {:view_search false}
             :routes [{:filter {:event :notify :find "DEBUG:"}
                       :view :mini
                       :opts {:replace true}}]
             :lsp {:override {:vim.lsp.util.convert_input_to_markdown_lines true
                              :vim.lsp.util.stylize_markdown true
                              :cmp.entry.get_documentation true}}
             :presets {:bottom_search true
                       :command_palette true
                       :long_message_to_split true
                       :inc_rename true
                       :lsp_doc_border true}})

(fn after []
  (let [noice (require :noice)]
    (noice.setup opts)))

{:name :noice.nvim : after :event :DeferredUIEnter :dep_of :lualine.nvim}
