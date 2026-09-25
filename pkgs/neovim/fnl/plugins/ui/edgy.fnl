
(local help {:ft :help
             :size {:height 20}
             :filter (fn [buf]
                       (= (. (. vim.bo buf) :buftype) :help))})

(local neotest-output {:ft :neotest-output-panel
                       :size {:height 15}
                       :title "Test Output"})

(local dap-repl {:ft :dap-repl
                 :size {:height 15}
                 :title "DAP REPL"})

(local dap-console {:ft :dapui_console
                    :size {:height 15}
                    :title "DAP Console"})

(local neotest-summary {:ft :neotest-summary
                        :title "Test Summary"
                        :size {:width 40}})

(local bottom [help neotest-output dap-repl dap-console])
(local right [neotest-summary])

(local opts {:bottom bottom :right right})

(fn after []
  (let [edgy (require "edgy")]
    (edgy.setup opts)))

{:name :edgy.nvim
 :after after}
