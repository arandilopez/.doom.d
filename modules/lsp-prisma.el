;;; lsp-prisma.el --- Prisma server configuration    -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Arandi Lopez

;; Author: Arandi Lopez <arandilopez.93@gmail.com>
;; Keywords: prisma
;;
;; Code:

(require 'lsp-mode)

(defgroup lsp-prisma nil
  "LSP support for prisma files, using the prisma language server"
  :group 'lsp-mode
  :link '(uri-link "https://www.npmjs.com/package/@prisma/language-server")
  :package-version '(lsp-mode . "6.1"))

;; Register lsp-language-id
(add-to-list 'lsp-language-id-configuration '(prisma-mode . "prisma"))

;; Prisma
(lsp-register-client
 (make-lsp-client
  :new-connection (lsp-stdio-connection
                   '("prisma-language-server" "--stdio"))
  :major-modes '(prisma-mode)
  :priority -1
  :server-id 'prisma-ls))

;; (provide 'lsp-prisma)
;;; lsp-prisma.el ends here
