;;; adonis-edge-mode.el -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Arandi Lopez

;; Author: Arandi Lopez <arandilopez.93@gmail.com>


;; A new derived mode (adonis-edge-mode) from web-mode
(define-derived-mode adonis-edge-mode web-mode "Edge"
  "Major mode for editing Adonis' Edge templates.\\{web-edge-map}"
  (setq web-mode-script-padding 2
        web-mode-style-padding 2
        web-mode-block-padding 2
        web-mode-engines-alist '((\"blade\"  . \"\\\\.blade\\\\.\"))))

;; Set as default mode for vuejs files
(add-to-list 'auto-mode-alist '("\\.edge\\'" . adonis-edge-mode))
