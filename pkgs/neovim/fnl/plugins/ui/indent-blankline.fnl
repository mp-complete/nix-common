;; indent-blankline — visual indent guides

(fn after []
  (let [ibl (require :ibl)]
    (ibl.setup {:indent {:char "│"}
                :scope {:enabled true
                        :show_start true
                        :show_end false}})))

{:name :indent-blankline.nvim
 :event :DeferredUIEnter
 :after after}
