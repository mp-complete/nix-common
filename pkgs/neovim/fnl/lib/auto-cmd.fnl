;; Autocommand utilities
;;
;; Usage:
;;   (local au (require :lib.auto-cmd))
;;
;;   ;; Create a group with autocmds
;;   (au.group! :my-group
;;     [[:BufWritePre] {:pattern "*.fnl" :callback #(print "saving fennel")}]
;;     [[:FileType]    {:pattern :lua     :callback #(set vim.bo.shiftwidth 2)}])
;;
;;   ;; One-off autocmd (no group)
;;   (au.on! [:BufEnter] {:pattern "*.md" :callback #(set vim.wo.wrap true)})
;;
;;   ;; Buffer-local autocmd
;;   (au.on-buf! [:BufWritePre] bufnr #(vim.lsp.buf.format))
;;
;;   ;; FileType shorthand
;;   (au.on-ft! :lua #(set vim.bo.shiftwidth 2))
;;   (au.on-ft! [:lua :fennel] #(set vim.bo.expandtab true))

(local M {})

(local api vim.api)

;; Create an augroup, clearing any previous autocmds in it.
;; Returns the group id.
(fn M.augroup! [name]
  (api.nvim_create_augroup name {:clear true}))

;; Create a single autocommand.
;; `events` is a string or sequential table of event names.
;; `opts` follows nvim_create_autocmd — :callback, :pattern, :group, :buffer, etc.
(fn M.on! [events opts]
  (api.nvim_create_autocmd events opts))

;; Create an augroup and register multiple autocmds in it.
;; Each spec is [events opts]. The group is automatically injected.
;;
;;   (au.group! :name
;;     [[:BufWritePre] {:pattern "*" :callback cb}]
;;     [[:FileType]    {:pattern :lua :callback cb2}])
(fn M.group! [name ...]
  (let [group (M.augroup! name)]
    (each [_ spec (ipairs [...])]
      (let [[events opts] spec]
        (M.on! events (vim.tbl_extend :force opts {:group group}))))
    group))

;; Buffer-local autocommand shorthand.
;; `events` is a string or table. `bufnr` is the buffer number.
;; `callback` is a function. Extra opts can be passed in `?opts`.
(fn M.on-buf! [events bufnr callback ?opts]
  (let [base {:buffer bufnr :callback callback}]
    (M.on! events (if ?opts
                      (vim.tbl_extend :force base ?opts)
                      base))))

;; FileType shorthand — runs callback when filetype matches.
;; `ft` is a string or table of filetypes.
;; `callback` receives the autocmd args table.
(fn M.on-ft! [ft callback ?opts]
  (let [pattern (if (= (type ft) :string) ft
                    (table.concat ft ","))
        base {:pattern pattern :callback callback}]
    (M.on! [:FileType] (if ?opts
                           (vim.tbl_extend :force base ?opts)
                           base))))

M
