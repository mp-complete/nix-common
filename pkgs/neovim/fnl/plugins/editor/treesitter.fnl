;; Treesitter configuration
;; Incremental selection via treesitter node hierarchy + highlighting/indent

(local au (require :lib.auto-cmd))
(local keymap (require :lib.keymap))

;; -- Incremental selection state --

(var node-stack [])

(fn select-node [node]
  (let [(sr sc er ec) (node:range)]
    (vim.fn.setpos "'<" [0 (+ sr 1) (+ sc 1) 0])
    (vim.fn.setpos "'>" [0 (+ er 1) ec 0])
    (vim.cmd "normal! gv")))

(fn init-selection []
  (let [node (vim.treesitter.get_node)]
    (when node
      (set node-stack [node])
      (select-node node))))

(fn node-incremental []
  (if (= (length node-stack) 0)
      (init-selection)
      (let [current (. node-stack (length node-stack))
            parent (current:parent)]
        (when parent
          (table.insert node-stack parent)
          (select-node parent)))))

(fn node-decremental []
  (when (> (length node-stack) 1)
    (table.remove node-stack)
    (select-node (. node-stack (length node-stack)))))

;; Reset stack when leaving visual mode
(au.on! [:ModeChanged] {:pattern "[vV\x16]*:*"
                         :callback #(when (not (: (vim.fn.mode) :match "[vV\x16]"))
                                      (set node-stack []))})

(fn start-ts [buf]
  (when (pcall vim.treesitter.start buf)
    (set (. vim.bo buf :indentexpr)
         "v:lua.require'nvim-treesitter'.indentexpr()")))

(fn after []
  (let [ts (require :nvim-treesitter)]
    (ts.setup {}))

  ;; Enable treesitter highlighting and indentation for future filetypes
  (au.on! [:FileType] {:callback (fn [args] (start-ts args.buf))})

  ;; Kick treesitter for buffers that loaded before this spec ran
  (each [_ buf (ipairs (vim.api.nvim_list_bufs))]
    (when (and (vim.api.nvim_buf_is_loaded buf)
              (~= (. vim.bo buf :filetype) ""))
      (start-ts buf))))

(fn before []
  ;; Incremental selection keymaps
  (keymap.map :<C-space> init-selection {:desc "Incremental selection"})
  (keymap.map :<C-space> node-incremental {:mode :x :desc "Expand selection"})
  (keymap.map :<bs> node-decremental {:mode :x :desc "Shrink selection"}))

{:name :nvim-treesitter
 :event :DeferredUIEnter
 :after after
 :before before}
