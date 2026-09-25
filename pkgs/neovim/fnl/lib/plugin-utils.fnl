(local M {})

(fn with-plugin [p f]
  (f (require p)))

;; flash

(set M.flash {})

(fn M.flash.jump []
  (with-plugin :flash (fn [flash] (flash.jump))))

(fn M.flash.treesitter []
  (with-plugin :flash (fn [flash] (flash.treesitter))))

M
