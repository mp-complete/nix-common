(fn win-action [name ?opts]
  (let [opts (or ?opts {})]
    (tset opts 1 name)
    opts))

(local opts {:picker {:actions {:trouble_open (fn [...]
                                                (let [trouble (require :trouble.sources.snacks)]
                                                  (trouble.actions.trouble_open.action ...)))}
                      :win {:input {:keys {:<a-t> (win-action :trouble_open
                                                              {:mode [:n :i]})}}}}
             :input {}
             :notify {}
             :notifier {}
             :bufdelete {}
             :toggle {}})

(local snacks (require :snacks))

(snacks.setup opts)
