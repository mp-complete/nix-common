;; Debug — nvim-dap + dap-ui + dap-virtual-text
;; Full DAP stack with pwa-node adapter for JS/TS debugging.

(local dap-icons {:Stopped ["󰁕 " :DiagnosticWarn :DapStoppedLine]
                  :Breakpoint " "
                  :BreakpointCondition " "
                  :BreakpointRejected [" " :DiagnosticError]
                  :LogPoint ".>"})

(fn setup-signs []
  (each [name sign (pairs dap-icons)]
    (let [sign (if (= (type sign) :table) sign [sign])]
      (vim.fn.sign_define (.. :Dap name)
                          {:text (. sign 1)
                           :texthl (or (. sign 2) :DiagnosticInfo)
                           :linehl (. sign 3)
                           :numhl (. sign 3)}))))

(fn setup-adapters [dap]
  (set dap.adapters.pwa-node
       {:type :server
        :host :localhost
        :port "${port}"
        :executable {:command :js-debug :args ["${port}"]}}))

(fn dap-after []
  (let [dap (require :dap)]
    (setup-signs)
    (setup-adapters dap)))

(fn dapui-after []
  (let [dap (require :dap)
        dapui (require :dapui)]
    (dapui.setup {})
    (set dap.listeners.after.event_initialized.dapui_config #(dapui.open {}))
    (set dap.listeners.before.event_terminated.dapui_config #(dapui.close {}))
    (set dap.listeners.before.event_exited.dapui_config #(dapui.close {}))))

[{:name :nvim-dap
  :keys [:<leader>db
         :<leader>dT
         :<leader>dC
         :<leader>dr
         :<leader>dc
         :<leader>di
         :<leader>do
         :<leader>dO
         :<leader>dw
         :<leader>du
         :<leader>de]
  :after (fn []
           (dap-after)
           (let [dap (require :dap)
                 km (require :lib.keymap)]
             (km.map :<leader>db #(dap.toggle_breakpoint)
                     {:desc "Toggle Breakpoint"})
             (km.map :<leader>dT #(dap.terminate) {:desc :Terminate})
             (km.map :<leader>dC #(dap.run_to_cursor) {:desc "Run to Cursor"})
             (km.map :<leader>dr #(dap.repl.toggle) {:desc "Toggle REPL"})
             (km.map :<leader>dc #(dap.continue) {:desc :Continue})
             (km.map :<leader>di #(dap.step_into) {:desc "Step Into"})
             (km.map :<leader>do #(dap.step_over) {:desc "Step Over"})
             (km.map :<leader>dO #(dap.step_out) {:desc "Step Out"})
             (km.map :<leader>dw #((. (require :dap.ui.widgets) :hover))
                     {:desc :Widgets})))
  :dep_of :nvim-dap-ui}
 {:name :nvim-dap-ui :after dapui-after}
 {:name :nvim-dap-virtual-text}]
