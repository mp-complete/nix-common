
{:name :zellij-nav.nvim
 :event :DeferredUIEnter
 :enabled (fn [] vim.env.ZELLIJ)
 :after (fn []
         (let [zellij-nav (require :zellij-nav)]
           (zellij-nav.setup {})))}
