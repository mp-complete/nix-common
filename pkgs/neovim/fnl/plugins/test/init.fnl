;; Test — neotest + neotest-vitest
;; Test runner framework with Vitest adapter and trouble.nvim integration.

(fn trouble-consumer [client]
  (fn client.listeners.results [adapter-id results is-partial]
    (when (not is-partial)
      (let [tree (assert (client:get_position nil {:adapter adapter-id}))]
        (var failed 0)
        (each [pos-id result (pairs results)]
          (when (and (= result.status :failed) (tree:get_key pos-id))
            (set failed (+ failed 1))))
        (vim.schedule
          #(let [trouble (require :trouble)]
             (when (trouble.is_open)
               (trouble.refresh)
               (when (= failed 0)
                 (trouble.close))))))))
  {})

(fn setup-neotest []
  (let [neotest (require :neotest)
        vitest (require :neotest-vitest)]
    (neotest.setup
      {:adapters [vitest]
       :consumers {:trouble trouble-consumer}})

    ;; Neotest's subprocess spawns nvim with -u NONE and can't find
    ;; Nix-managed treesitter grammars (separate store path). The
    ;; fallback (child_failed) doesn't trigger because the error is
    ;; thrown via nio futures instead of returned. Disable subprocess
    ;; so discovery uses the main process instead.
    (let [subprocess (require :neotest.lib.subprocess)]
      (set subprocess.enabled (fn [] false)))

    (vim.api.nvim_create_autocmd :FileType
      {:pattern [:neotest-output]
       :callback (fn [ev]
                   (vim.keymap.set :n :q :<CMD>q<CR>
                     {:buffer ev.buf :silent true :nowait true}))})))

(fn after []
  (setup-neotest)
  (let [nt (require :neotest)
        km (require :lib.keymap)]
    (km.map :<leader>ts #(nt.summary.toggle) {:desc "Test Summary"})
    (km.map :<leader>tt #(nt.run.run (vim.fn.expand "%")) {:desc "Run Test (File)"})
    (km.map :<leader>tT #(nt.run.run (vim.uv.cwd)) {:desc "Run All Test Files"})
    (km.map :<leader>tr #(nt.run.run) {:desc "Run Test (Nearest)"})
    (km.map :<leader>tl #(nt.run.run_last) {:desc "Run Last Test"})
    (km.map :<leader>tw #(nt.watch.toggle (vim.fn.expand "%")) {:desc "Watch File"})
    (km.map :<leader>td #(nt.run.run {:strategy :dap}) {:desc "Debug Test"})
    (km.map :<leader>to #(nt.output.open {:enter true :auto_close true}) {:desc "Show Output"})
    (km.map :<leader>tO #(nt.output_panel.toggle) {:desc "Test Output Panel"})))

[{:name :neotest
  :keys [:<leader>ts :<leader>tt :<leader>tT :<leader>tr
         :<leader>tl :<leader>tw :<leader>td :<leader>to :<leader>tO]
  : after}
 {:name :neotest-vitest}
 {:name :FixCursorHold.nvim}]