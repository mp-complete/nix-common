;; Coding plugins — autopairs, mini modules

[{:name :mini.nvim
  :event :DeferredUIEnter
  :after (fn []
           ;; Autopairs — auto-close brackets, quotes, etc.
           (let [pairs (require :mini.pairs)]
             (pairs.setup {}))

           ;; Buffer remove — close buffers without messing up window layout
           (let [bufremove (require :mini.bufremove)
                 km (require :lib.keymap)]
             (bufremove.setup {})
             (km.map :<leader>bd #(bufremove.delete) {:desc "Delete buffer"})
             (km.map :<leader>bD #(bufremove.delete 0 true) {:desc "Delete buffer (force)"})))}]
