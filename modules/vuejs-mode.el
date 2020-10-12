;;; vuejs-mode.el --- Web mode derived mode for Vuejs files  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Arandi Lopez

;; Author: Arandi Lopez <arandilopez.93@gmail.com>


;; A new derived mode (vuejs-mode) from web-mode to hook for lsp
(define-derived-mode vuejs-mode web-mode "Vuejs"
  "Major mode for editing Web & Vuejs templates.\\{web-vue-map}"
  (setq web-mode-script-padding 2
        web-mode-style-padding 2
        web-mode-block-padding 2))

;; Set as default mode for vuejs files
(add-to-list 'auto-mode-alist '("\\.vue\\'" . vuejs-mode))

;; Enable LSP fue vuejs files
(when (featurep! :tools lsp)
  (add-hook! 'vuejs-mode-hook #'lsp!))
