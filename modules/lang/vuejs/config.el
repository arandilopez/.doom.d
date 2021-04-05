;; Enable LSP
(add-hook! 'vuejs-mode-hook #'lsp!)

;; Enable formating
(add-hook! 'vuejs-mode-hook #'format-all-mode)
