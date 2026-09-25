(local M {})

(fn M.action [...]
  (vim.fn.system [:zellij :action ...]))

(fn M.resize [direction ?dec]
  (let [dec (or ?dec false)
        kind (if dec :decrease :increase)]
    (M.action :resize kind direction)))

(fn M.increase [direction]
  (M.resize direction))

(fn M.decrease [direction]
  (M.resize direction true))

(fn M.new-tab []
  (M.action :new-tab))

(fn M.toggle-floating []
  (M.action :toggle-floating-panes))

(fn M.new-pane [?direction]
  (let [direction (or ?direction :down)]
    (M.action :new-pane :--direction direction)))

;; command builder
(fn Command [name]
  {: name :argv []})

(fn Arg [val]
  {:kind :arg : val})

(fn Flag [k ?v]
  {:kind :flag :key k :value ?v})

(fn push [c x]
  (table.insert c.argv x)
  c)

(fn arg [c a]
  (push c (Arg a)))

(fn flag [c k ?v]
  (push c (Flag k ?v)))

(fn compile [c]
  (let [out []]
    (each [_ inst (ipairs c.argv)]
      (match inst
        {:kind :arg :val v} (table.insert out v)
        {:kind :flag :key k :value v} (do
                                        (table.insert out k)
                                        (table.insert out v))
        {:kind :flag :key k} (table.insert out k)))
    out))

(fn run [c]
  (let [cmd [:zellij :run]]
    (each [_ arg (ipairs (compile c))]
      (print arg)
      (table.insert cmd arg))
    (table.insert cmd "--")
    (table.insert cmd c.name)
    (vim.fn.system cmd)))

(fn close-on-exit [c] (flag c :-c))
(fn floating [c] (flag c :-f))
(fn x [c x] (flag c :-x x))
(fn y [c y] (flag c :-y y))
(fn width [c width] (flag c :--width width))
(fn height [c height] (flag c :--height height))
(fn name [c name] (flag c :--name name))

(local lazygit (-> (Command :lazygit)
                   (x "2%")
                   (y "4%")
                   (width "96%")
                   (height "98%")
                   (close-on-exit)
                   (name :lazygit)
                   (floating)))

(set M.run {})
(fn M.run.lazygit []
  (run lazygit))

M
