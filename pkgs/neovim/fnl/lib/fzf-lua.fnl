(local M {})
(fn fzf-exec [fn-name]
  ((. (require :fzf-lua) fn-name)))

(local fns [:files
            :oldfiles
            :buffers
            [:help-tags :help_tags]
            :keymaps
            :colorschemes
            :grep
            [:grep-visual :grep_visual]
            [:live-grep :live_grep]
            :resume
            :jumps
            :marks
            [:search-history :search_history]
            :undotree
            [:lsp-definitions :lsp_definitions]
            [:lsp-references :lsp_references]
            [:lsp-document-symbols :lsp_document_symbols]])

(each [_ func (ipairs fns)]
  (let [is-table (= (type func) :table)
        lhs (if is-table (. func 1) func)
        rhs (if is-table (. func 2) func)]
    (tset M lhs #(fzf-exec rhs))))

M
