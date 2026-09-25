;; blink.cmp + LSP — lazy-loaded on first buffer open.
;; blink must be set up before LSP so capabilities are available.

(fn direction-priority []
  (let [blink (require :blink.cmp)
        ctx (blink.get_context)
        item (blink.get_selected_item)]
    (if (or (= ctx nil) (= item nil))
        [:s :n]
        (let [item-text (or (and item.textEdit item.textEdit.newText)
                            item.insertText item.label)
              is-multi-line (not= (item-text:find "\n") nil)]
          (if (or is-multi-line (= vim.g.blink_cmp_upwards_ctx_id ctx.id))
              (do
                (set vim.g.blink_cmp_upwards_ctx_id ctx.id)
                [:n :s])
              [:s :n])))))

(local blink-opts
       {:keymap {:preset :default}
        :fuzzy {:implementation :prefer_rust_with_warning}
        :completion {:documentation {:auto_show false}
                     :ghost_text {:enabled true}
                     :menu {:direction_priority direction-priority}}
        :sources {:default [:lsp :path :snippets :buffer]
                  :providers {:cmdline {:enabled (fn []
                                                   (or (not= (vim.fn.getcmdtype)
                                                             ":")
                                                       (not (: (vim.fn.getcmdline)
                                                               :match
                                                               "^[%%0-9,'<>%-]*!"))))
                                        :async true}}}})

(fn after []
  (let [blink (require :blink.cmp)]
    (blink.setup blink-opts))
  (require :config.lsp))

{:name :blink.cmp :event [:BufReadPre :BufNewFile] : after}
