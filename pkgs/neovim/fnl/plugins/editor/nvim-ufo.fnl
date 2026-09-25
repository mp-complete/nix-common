(fn provider-selector [_ filetype buftype]
  (let [disabled {:neo-tree true
                  :help true
                  :qf true
                  :prompt true
                  :nofile true}]
    (if (or (. disabled filetype) (. disabled buftype))
        ""
        [:treesitter :indent])))

(fn after []
  (let [ufo (require :ufo)]
    (ufo.setup {:provider_selector provider-selector
                :open_fold_hl_timeout 0})))

{:name :nvim-ufo :event :DeferredUIEnter : after}
