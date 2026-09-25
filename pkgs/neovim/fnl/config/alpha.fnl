;; Dashboard (alpha-nvim)
;; Catppuccin-macchiato–friendly startup screen with quick actions.

(local leader :SPC)

(fn text [text ?opts]
  (let [opts (or ?opts {})]
    {:type :text :val text : opts}))

(fn box-text [txt ?opts]
  (let [opts (or ?opts {})
        padding (or opts.padding 3)
        inner (+ (length txt) (* 2 padding))
        txt-opts (or opts.text-opts {})]
    (text [(string.format "╭%s╮" (string.rep "─" inner))
           (string.format "│%s%s%s│" (string.rep " " padding) txt
                          (string.rep " " padding))
           (string.format "╰%s╯" (string.rep "─" inner))]
          txt-opts)))

(fn date-box []
  (let [date-str (os.date "%A, %Y-%m-%d")]
    (box-text date-str {:text-opts {:position :center :hl :Comment}})))

(fn padding [?val]
  (let [val (or ?val 0)]
    {:type :padding : val}))

(fn button [val on-press ?opts]
  {:type :button : val :on_press on-press :opts (or ?opts {})})

(fn menu-button [shortcut txt ?on-press]
  (let [key (-> shortcut
                (: :gsub "%s" "")
                (: :gsub leader :<leader>))
        on-press (or ?on-press
                     (let [key (vim.api.nvim_replace_termcodes (.. key
                                                                   :<Ignore>)
                                                               true false true)]
                       #(vim.api.nvim_feedkeys key :t false)))]
    (local opts {:position :center
                 : shortcut
                 :cursor 3
                 :width 50
                 :align_shortcut :right
                 :hl_shortcut :Keyword})
    (when ?on-press
      (set opts.keymap
           [:n key ?on-press {:noremap true :silent true :nowait true}]))
    (button txt on-press opts)))

(fn group [val ?opts]
  {:type :group : val :opts (or ?opts {})})

(fn config [layout ?opts]
  {: layout :opts (or ?opts {})})

(let [alpha (require :alpha)
      start-plugins (vim.fn.globpath vim.o.packpath :pack/*/start/* 0 1)
      opt-plugins (vim.fn.globpath vim.o.packpath :pack/*/opt/* 0 1)
      eager (length start-plugins)
      lazy (length opt-plugins)
      total (+ eager lazy)
      startup-ms (if vim.g.start_time
                     (string.format "%.1f"
                                    (* 1000
                                       (vim.fn.reltimefloat (vim.fn.reltime vim.g.start_time))))
                     "?")
      v (vim.version)
      ver-str (string.format "v%d.%d.%d" v.major v.minor v.patch)]
  (local header (text ["⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣀⣀⣀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"
                       "⠀⠀⠀⠀⠀⠀⠀⠀⣠⣤⣶⠾⠿⠛⠛⠛⠛⠛⠛⠿⠷⣶⣤⣄⠀⠀⠀⠀⠀⠀⠀⠀"
                       "⠀⠀⠀⠀⠀⣠⣴⡿⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⢿⣶⣄⠀⠀⠀⠀⠀"
                       "⠀⠀⠀⣠⣾⠟⠉⠀⠀⠀⠀⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠻⣷⣄⠀⠀⠀"
                       "⠀⠀⣴⡿⠋⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⣆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⢿⣦⠀⠀"
                       "⠀⣼⡿⠁⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢿⣧⠀"
                       "⢰⣿⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣸⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⣿⡇"
                       "⣾⡟⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⣿"
                       "⣿⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⡟⠘⣿⣿⣿⣿⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿"
                       "⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⣼⣿⣿⠟⠀⠀⠘⣿⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣿"
                       "⢸⣿⡀⠀⠀⠀⠀⠀⢀⣾⣿⣿⠏⠀⠀⠀⠀⠹⣿⣿⣿⣷⣀⣀⣀⣀⡀⠀⠀⠀⣿⡟"
                       "⠀⢿⣷⡀⠀⠀⠀⢀⣾⣿⣿⠏⠀⠀⠀⠀⠀⠀⠹⣿⣿⣿⣿⣿⣿⣿⠇⠀⠀⣼⡿⠁"
                       "⠀⠈⢻⣷⡄⠀⠀⠚⠛⠛⠋⠀⠀⠀⠀⠀⠀⠀⠀⠙⠛⠛⠛⠛⠛⠛⠀⢀⣼⡿⠁⠀"
                       "⠀⠀⠀⠹⣿⣦⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣴⣿⠟⠁⠀⠀"
                       "⠀⠀⠀⠀⠈⠛⢿⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⣿⠟⠁⠀⠀⠀⠀"
                       "⠀⠀⠀⠀⠀⠀⠀⠉⠛⠿⣿⣶⣦⣤⣤⣤⣠⣤⣤⣤⣶⣾⠿⠟⠉⠀⠀⠀⠀⠀⠀⠀"
                       "⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠉⠉⠛⠛⠛⠛⠉⠉⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀"]
                      {:position :center :hl :Type}))
  (local buttons
         (group [(menu-button (string.format "%s f f" leader) :files)
                 (menu-button (string.format "%s f r" leader) :old_files)
                 (menu-button (string.format "%s /" leader) :live_grep)
                 (menu-button (string.format "%s ," leader) :buffers)
                 (menu-button :q :quit #(vim.cmd :qa))]))
  (local footer (text [(string.format "⚡ %d plugins (%d eager · %d lazy)  │  %s  │  %sms"
                                      total eager lazy ver-str startup-ms)]
                      {:position :center :hl :Comment}))
  (alpha.setup (config [(padding 2)
                        header
                        (padding 1)
                        (date-box)
                        (padding 2)
                        buttons
                        (padding 2)
                        footer] {:margin 5})))
