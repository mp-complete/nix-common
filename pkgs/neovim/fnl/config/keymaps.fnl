;; Keymaps

;; Nav
(let [km (require :lib.keymap)
      plugin-utils (require :lib.plugin-utils)]
  (km.group :<leader>f :file)
  (km.group :<leader>h :help {:icon " "})
  (km.group :<leader>s :search)
  (km.group "[" :prev)
  (km.group "]" :next)
  (km.group :<leader>c :code)
  (km.group :<leader>d :debug)
  (km.group :<leader>g :git)
  (km.group :<leader>gh :hunks)
  (km.group :<leader>o :toggle)
  (km.group :<leader>oc :conform)
  (km.group :<leader>u :ui)
  (km.group :<leader>x :diagnostics)
  (km.group :<leader>w :window
            {:expand (fn []
                       ((. (require :which-key.extras) :expand :win)))})
  (km.group :<leader>b :buffer
            {:expand (fn []
                       ((. (require :which-key.extras) :expand :buf)))})
  (km.hydra :<c-w><space> :<c-w>)
  (if vim.env.ZELLIJ
      (let [zj (require :lib.zellij)]
        (km.group :<c-w>z :Zellij)
        (km.map :<c-h> :<cmd>ZellijNavigateLeftTab<cr> {:desc "Navigate left"})
        (km.map :<c-l> :<cmd>ZellijNavigateRightTab<cr>
                {:desc "Navigate right"})
        (km.map :<c-j> :<cmd>ZellijNavigateDown<cr> {:desc "Navigate down"})
        (km.map :<c-k> :<cmd>ZellijNavigateUp<cr> {:desc "Navigate up"}) ; tabs
        (km.map :<c-w>zt #(zj.new-tab) {:desc "New zellij tab"}) ; panes
        (km.map :<c-t> #(zj.new-tab) {:desc "New zellij tab"})
        (km.map :<a-f> #(zj.toggle-floating) {:desc "Toggle floating panes"})
        (km.map :<a-n> #(zj.new-pane))
        (km.map :<c-w>zp #(zj.new-pane) {:desc "New pane"}) ; pane sizing
        (km.map :<c-w>zh #(zj.increase :left) {:desc "Increase pane left"})
        (km.map :<c-w>zH #(zj.decrease :left) {:desc "Decrease pane left"})
        (km.map :<c-w>zj #(zj.increase :down) {:desc "Increase pane down"})
        (km.map :<c-w>zJ #(zj.decrease :down) {:desc "Decrease pane down"})
        (km.map :<c-w>zl #(zj.increase :right) {:desc "Increase pane right"})
        (km.map :<c-w>zL #(zj.decrease :right) {:desc "Decrease pane right"})
        (km.map :<c-w>zk #(zj.increase :up) {:desc "Increase pane up"})
        (km.map :<c-w>zK #(zj.decrease :up) {:desc "Decrease pane up"})
        ;; misc.
        (km.map :<a-g> #(zj.run.lazygit))
        (km.map :<leader>gg #(zj.run.lazygit) {:desc :Lazygit}))
      (do
        (km.map :<C-h> :<C-w>h {:desc "Navigate left"})
        (km.map :<C-l> :<C-w>l {:desc "Navigate right"})
        (km.map :<C-j> :<C-w>j {:desc "Navigate down"})
        (km.map :<C-k> :<C-w>k {:desc "Navigate up"})))
  ;; Toggles
  (let [snacks (require :snacks)]
    (km.toggle :<leader>ocf {:name "Format on Save"
                             :get #(not vim.g.disable_autoformat)
                             :set #(set vim.g.disable_autoformat (not $1))})
    (km.toggle :<leader>od (snacks.toggle.diagnostics))
    (km.toggle :<leader>oi (snacks.toggle.inlay_hints))
    (km.toggle :<leader>os (snacks.toggle.option :spell {:name :Spelling}))
    (km.toggle :<leader>ow (snacks.toggle.option :wrap {:name "Word Wrap"}))
    (km.toggle :<leader>or
               (snacks.toggle.option :relativenumber
                                     {:name "Relative Numbers"})))
  (km.map :s #(plugin-utils.flash.jump) {:desc :Flash :mode [:n :x :o]})
  (km.map :S #(plugin-utils.flash.treesitter)
          {:desc "Flash Treesitter" :mode [:n :x :o]})
  (let [picker (require :lib.picker)]
    (km.map :<leader>ff #(picker.files) {:desc "Find files"})
    (km.map :<leader>fr #(picker.recent) {:desc "Recent Files"})
    (km.map "<leader>," #(picker.buffers) {:desc "Find buffers"})
    (km.map :<leader>hh #(picker.help) {:desc "Find help tags"})
    (km.map :<leader>hk #(picker.keymaps) {:desc "Find keymaps"})
    (km.map :<leader>hc #(picker.colorschemes) {:desc :Colorschemes})
    (km.map :<leader>/ #(picker.grep))
    (km.map :<leader>sg #(picker.grep) {:desc "Live Grep"})
    (km.map :<leader>sG #(picker.grep {:live false}) {:desc :Grep})
    (km.map :<leader>sw #(picker.grep-word)
            {:mode [:n :x] :desc "Grep selection or word"})
    (km.map :<leader>sR #(picker.resume) {:desc "Resume Search"})
    (km.map :<leader>sj #(picker.jumps) {:desc "Search jumps"})
    (km.map :<leader>sm #(picker.marks) {:desc "Search Marks"})
    (km.map :<leader>sh #(picker.search-history) {:desc "Search history"})
    (km.map :<leader>sz #(picker.undo) {:desc :Undotree}))
  (km.map :gs "<Plug>(nvim-surround-normal)" {:desc :Surround})
  (km.map :gss "<Plug>(nvim-surround-normal-cur)" {:desc "Surround Current"})
  (km.map :gsS "<Plug>(nvim-surround-normal-line)" {:desc "Surround Line"})
  (km.map :gsa "<Plug>(nvim-surround-visual)" {:mode :x :desc :Surround})
  (km.map :gsA "<Plug>(nvim-surround-visual-line)"
          {:mode :x :desc "Surround Line"})
  (km.map :gsd "<Plug>(nvim-surround-delete)" {:desc "Delete Surround"})
  (km.map :gsr "<Plug>(nvim-surround-change)" {:desc "Change Surround"})
  (km.map :gsR "<Plug>(nvim-surround-change-line)"
          {:desc "Change Surround - New Line"})
  (km.map :<c-g>s "<Plug>(nvim-surround-insert)" {:desc :Surround}))
