(local snacks (require :snacks))

(local M {})

(fn pick [source ?opts]
  (let [picker-fn (. snacks.picker source)
        opts (or ?opts {})]
    (picker-fn opts)))

;; Files and buffers
(fn M.smart [?opts]
  (pick :smart ?opts))

(fn M.files [?opts]
  (pick :files ?opts))

(fn M.git-files [?opts]
  (pick :git_files ?opts))

(fn M.recent [?opts]
  (pick :recent ?opts))

(fn M.buffers [?opts]
  (pick :buffers ?opts))

(fn M.projects [?opts]
  (pick :projects ?opts))

(fn M.explorer [?opts]
  (pick :explorer ?opts))

;; Search
(fn M.grep [?opts]
  (pick :grep ?opts))

(fn M.grep-buffers [?opts]
  (pick :grep_buffers ?opts))

(fn M.grep-word [?opts]
  (pick :grep_word ?opts))

(fn M.lines [?opts]
  (pick :lines ?opts))

;; Help

(fn M.help [?opts]
  (pick :help ?opts))

(fn M.keymaps [?opts]
  (pick :keymaps ?opts))

(fn M.commands [?opts]
  (pick :commands ?opts))

(fn M.autocmds [?opts]
  (pick :autocmds ?opts))

(fn M.man [?opts]
  (pick :man ?opts))

(fn M.registers [?opts]
  (pick :registers ?opts))

(fn M.highlights [?opts]
  (pick :highlights ?opts))

;; UI
(fn M.colorschemes [?opts]
  (pick :colorschemes ?opts))

(fn M.icons [?opts]
  (pick :icons ?opts))

;; History

(fn M.command-history [?opts]
  (pick :command_history ?opts))

(fn M.search-history [?opts]
  (pick :search_history ?opts))

(fn M.resume [?opts]
  (pick :resume ?opts))

(fn M.undo [?opts]
  (pick :undo ?opts))

(fn M.jumps [?opts]
  (pick :jumps ?opts))

(fn M.marks [?opts]
  (pick :marks ?opts))

;; Diagnostics and lists
(fn M.diagnostics [?opts]
  (pick :diagnostics ?opts))

(fn M.diagnostics-buffer [?opts]
  (pick :diagnostics_buffer ?opts))

(fn M.qflist [?opts]
  (pick :qflist ?opts))

(fn M.loclist [?opts]
  (pick :loclist ?opts))

(fn M.notifications [?opts]
  (pick :notifications ?opts))

;; Git
(fn M.git-status [?opts]
  (pick :git_status ?opts))

(fn M.git-branches [?opts]
  (pick :git_branches ?opts))

(fn M.git-log [?opts]
  (pick :git_log ?opts))

(fn M.git-log-file [?opts]
  (pick :git_log_file ?opts))

(fn M.git-log-line [?opts]
  (pick :git_log_line ?opts))

(fn M.git-diff [?opts]
  (pick :git_diff ?opts))

(fn M.git-stash [?opts]
  (pick :git_stash ?opts))

(fn M.git-grep [?opts]
  (pick :git_grep ?opts))

;; LSP
(fn M.lsp-definitions [?opts]
  (pick :lsp_definitions ?opts))

(fn M.lsp-declarations [?opts]
  (pick :lsp_declarations ?opts))

(fn M.lsp-references [?opts]
  (pick :lsp_references ?opts))

(fn M.lsp-implementations [?opts]
  (pick :lsp_implementations ?opts))

(fn M.lsp-type-definitions [?opts]
  (pick :lsp_type_definitions ?opts))

(fn M.lsp-incoming-calls [?opts]
  (pick :lsp_incoming_calls ?opts))

(fn M.lsp-outgoing-calls [?opts]
  (pick :lsp_outgoing_calls ?opts))

(fn M.lsp-document-symbols [?opts]
  (pick :lsp_symbols ?opts))

(fn M.lsp-symbols [?opts]
  (pick :lsp_symbols ?opts))

(fn M.lsp-workspace-symbols [?opts]
  (pick :lsp_workspace_symbols ?opts))

M
