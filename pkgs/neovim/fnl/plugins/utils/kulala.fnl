;; kulala.nvim — HTTP REST client
;; Triggered on http/rest filetypes, keymaps under <leader>R.

(fn after []
  (let [kulala (require :kulala)]
    (kulala.setup {:global_keymaps true
                   :global_keymaps_prefix :<leader>R
                   :kulala_keymaps_prefix ""})))

{:name :kulala.nvim
 :ft [:http :rest]
 : after}
