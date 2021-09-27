(after! eglot
  :config
  (set-eglot-client! 'prisma-mode '("prisma-language-server" "--stdio")))

(add-hook! 'prisma-mode-hook #'lsp!)
