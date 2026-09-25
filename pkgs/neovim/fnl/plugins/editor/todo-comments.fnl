;; todo-comments — highlight and search TODO/FIXME/HACK/NOTE etc.

(fn after []
  (let [todo (require :todo-comments)
        km (require :lib.keymap)]
    (todo.setup {})
    (km.map "]t" #(todo.jump_next) {:desc "Next TODO comment"})
    (km.map "[t" #(todo.jump_prev) {:desc "Previous TODO comment"})
    (km.map :<leader>xt "<cmd>Trouble todo toggle<cr>" {:desc "TODO (Trouble)"})
    (km.map :<leader>st "<cmd>TodoFzfLua<cr>" {:desc "Search TODOs"})))

{:name :todo-comments.nvim
 :event :DeferredUIEnter
 :after after}
