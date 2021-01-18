;;; liquid-mode.el --- Web mode derived mode for Liquid template files  -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Arandi Lopez
;; Author: Arandi Lopez <arandilopez.93@gmail.com>

;; A new derived mode (liquid-mode) from web-mode to hook for lsp
(define-derived-mode liquid-mode web-mode "Liquid"
  "Major mode for editing Web & Liquid templates.\\{web-liquid-map}"
  (setq web-mode-script-padding 2
        web-mode-style-padding 2
        web-mode-block-padding 2))
        ;; web-mode-engines-alist '((\"django\"  . \"\\\\.liquid\\\\.\"))))

;; Set as default mode for liquid files
(add-to-list 'auto-mode-alist '("\\.liquid\\'" . liquid-mode))

;; Enable LSP
;; (when (featurep! :tools lsp)
;;   (add-hook! 'liquid-mode-hook #'lsp!))

;; Enable formating
;; (when (featurep! :editor format)
;;   (setq-hook! 'liquid-mode-hook +format-with 'html-tidy))
