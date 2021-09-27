;; Enable LSP
(add-hook! 'vuejs-mode-hook #'lsp!)

;; Enable formating
(add-hook! 'vuejs-mode-hook #'format-all-mode)

(after! eglot
  :config
  (set-eglot-client! 'vuejs-mode '("vls", "--stdio")))
