;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "Arandi Lopez"
      user-mail-address "arandilopez.93@gmail.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 14))
(setq doom-font (font-spec :family "Fira Mono" :size (if ( string-equal system-type "darwin") 16 18 )))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
;; (setq doom-theme 'atom-one-dark)
(setq doom-theme 'doom-dracula)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/Code/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq projectile-project-search-path '("~/Code" "~/Code/osom" "~/Code/arandilopez"))

;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c g k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c g d') to jump to their definition and see how
;; they are implemented.

(load! "modules/xml")

;; Disable menu bar
(menu-bar-mode -1)

;; I don't remember where I readed it but this fixes identations guides when using emacsclient
(after! highlight-indent-guides
  (highlight-indent-guides-auto-set-faces))

;; Enable Wakatime
(setq wakatime-cli-path "$(which wakatime)")
(global-wakatime-mode)

;; Keymaps
(map! :leader
      :desc "Find file in dotfiles" "f t" #'find-in-dotfiles)

;; OS X Mapping
(map! (:when IS-MAC ;; My mac XD
       :g "M-1" "|"
       :g "M-2" "@"
       :g "M-3" "#"
       :g "M-º" "\\"
       :g "M-ç" "}"
       :g "M-+" "]"
       :g "M-ñ" "~"))

;; LSP mode settings
(setq lsp-auto-configure t)
(setq lsp-enable-snippet t)
(setq lsp-log-io nil)
(setq lsp-enable-folding nil)
(setq lsp-enable-links nil)
(setq lsp-enable-symbol-highlighting nil)
(setq lsp-restart 'auto-restart)

;; Company settings suggested by lsp-mode
(setq company-minimum-prefix-length 1
      company-idle-delay 0.0) ;; default is 0.2

;; Vue mode settings + LSP
(use-package vue-mode
  :mode "\\.vue\\'"
  :config
  ;; Enable lsp on vue files,
  ;; but it doesn't seem to work;
  ;; at least with coffeescript in vue files
  (add-hook! 'vue-mode-hook #'lsp!)
  ;; Fix identation problems
  (add-hook! 'vue-mode-hook (lambda () (setq syntax-ppss-table nil)))
  (setq mmm-js-mode-enter-hook (lambda () (setq syntax-ppss-table nil)))
  ;; 0, 1, or 2, representing (respectively) none, low, and high coloring
  (setq mmm-submode-decoration-level 0))

;; LSP dart settings
;; (setq lsp-dart-sdk-dir "~/flutter/bin/cache/dart-sdk")
