;;; prisma-mode.el --- Major mode for editing Prisma schemas        -*- lexical-binding: t; -*-

;; Copyright (C) 2016, 2017  David Vazquez Pua

;; Author: David Vazquez Pua <davazp@gmail.com>
;; Keywords: languages
;; Package-Requires: ((emacs "24.3"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package implements a major mode to edit Prisma schemas and
;; query.  The basic functionality includes:
;;
;;    - Syntax highlight
;;    - Automatic indentation
;;
;; Additionally, it is able to
;;    - Sending Prisma queries to an end-point URL
;;
;; Files with the .prisma and .gql extensions are automatically
;; opened with this mode.


;;; Code:

(require 'newcomment)
(require 'json)
(require 'url)
(require 'cl-lib)
(require 'let-alist)

;;; User Customizations:

(defgroup prisma nil
  "Major mode for editing Prisma schemas and queries."
  :tag "Prisma"
  :group 'languages)

(defcustom prisma-indent-level 2
  "Number of spaces for each indentation step in `prisma-mode'."
  :tag "Prisma"
  :type 'integer
  :safe 'integerp
  :group 'prisma)

(defcustom prisma-url nil
  "URL address of the prisma server endpoint."
  :tag "Prisma"
  :type 'string
  :group 'prisma)

(defcustom prisma-variables-file nil
  "File name containing prisma variables."
  :tag "Prisma"
  :type 'file
  :group 'prisma)

(defcustom prisma-extra-headers '()
  "Headers to send to the prisma endpoint."
  :tag "Prisma"
  :type 'list
  :group 'prisma)

(defun prisma-locate-config (dir)
  "Locate a prisma config starting in DIR."
  (if-let ((config-dir (locate-dominating-file dir ".prismaconfig")))
      (concat config-dir ".prismaconfig")
    (error "Could not find a .prismaconfig file")))

(defun prisma--completing-read-endpoint (endpoints)
  "Select an endpoint configuration from a list of ENDPOINTS."
  (completing-read "Select Prisma Endpoint:" (mapcar 'car endpoints)))

(defun prisma-open-config ()
  "Open the prisma config."
  (interactive)
  (find-file (prisma-locate-config ".")))

(defun prisma-select-endpoint ()
  "Set parameters based off of the endpoints listed in a .prismaconfig file."
  (interactive)
  (let ((config (json-read-file (prisma-locate-config "."))))
    (let-alist config
      (if-let ((endpoints .extensions.endpoints)
               (endpoint (cdr (assq (intern (prisma--completing-read-endpoint endpoints)) endpoints))))
          (let-alist endpoint
            (setq prisma-url .url
                  prisma-extra-headers .headers))
          (error "No endpoint configurations in .prismaconfig")))))

(defun prisma-encode-json (query &optional operation variables)
  "Put together a json like object with QUERY, OPERATION, and VARIABLES."
  (let* ((body '()))
    (push (cons 'query query) body)
    (when (and operation (not (string= operation "")))
      (push (cons 'operationName operation) body))
    (when variables
      (push (cons 'variables variables) body))
    (json-encode body)))

(defun prisma--query (query &optional operation variables)
  "Send QUERY to the server and return the response.

The query is sent as a HTTP POST request to the URL at
`prisma-url'.  The query can be any Prisma definition (query,
mutation or subscription).  OPERATION is a name for the
operation.  VARIABLES is the JSON string that specifies the values
of the variables used in the query."
  ;; Note that we need to get the value of prisma-url in the current
  ;; before before we switch to the temporary one.
  (let ((url prisma-url))
    (prisma-post-request url query operation variables)))

(declare-function request "request")
(declare-function request-response-data "request")
(declare-function request-response--raw-header "request")

(defun prisma-post-request (url query &optional operation variables)
  "Make post request to prisma server with url and body.

URL hostname, path, search parameters, such as operationName and variables
QUERY query definition(s) of query, mutation, and/or subscription
OPERATION name of the operation if multiple definition is given in QUERY
VARIABLES list of variables for query operation"
  (or (require 'request nil t)
      (error "prisma-post-request needs the request package.  \
Please install it and try again."))
  (let* ((body (prisma-encode-json query operation variables))
         (headers (append '(("Content-Type" . "application/json")) prisma-extra-headers)))
    (request url
             :type "POST"
             :data body
             :headers headers
             :parser 'json-read
             :sync t
             :complete (lambda (&rest _)
                         (message "%s" (if (string-equal "" operation)
                                           url
                                         (format "%s?operationName=%s"
                                                 url operation)))))))

(defun prisma-beginning-of-query ()
  "Move the point to the beginning of the current query."
  (interactive)
  (while (and (> (point) (point-min))
              (or (> (current-indentation) 0)
                  (> (car (syntax-ppss)) 0)))
    (forward-line -1)))

(defun prisma-end-of-query ()
  "Move the point to the end of the current query."
  (interactive)
  (while (and (< (point) (point-max))
              (or (> (current-indentation) 0)
                  (> (car (syntax-ppss)) 0)))
    (forward-line 1)))

(defun prisma-current-query ()
  "Return the current query/mutation/subscription definition."
  (let ((start
         (save-excursion
           (prisma-beginning-of-query)
           (point)))
        (end
         (save-excursion
           (prisma-end-of-query)
           (point))))
    (if (not (equal start end))
    (buffer-substring-no-properties start end)
      (save-excursion
    (let ((saved-point (point))
          (line (thing-at-point 'line t)))
      (when (string-match-p (regexp-quote "}") line)
        (search-backward "}" (beginning-of-line)))
      (when (string-match-p (regexp-quote "{") line)
        (search-forward "{" (end-of-line)))
      (if (= (point) saved-point)
          nil
        (prisma-current-query)))))))

(defun prisma-current-operation ()
  "Return the name of the current prisma query."
  (let* ((query
         (save-excursion
           (replace-regexp-in-string "^[ \t\n]*" ""
                     (or (prisma-current-query) ""))))
         (tokens
          (split-string query "[ \f\t\n\r\v]+"))
         (first (nth 0 tokens)))

    (if (or (string-equal first "{") (string-equal first ""))
        nil
      (replace-regexp-in-string "[({].*" "" (nth 1 tokens)))))

(defun prisma-current-variables (filename)
  "Return the current variables contained in FILENAME."
  (if (and filename
           (not (string-equal filename ""))
           (not (file-directory-p filename))
           (file-exists-p filename))
      (condition-case nil
          (progn (get-buffer-create (find-file-noselect filename))
                 (json-read-file filename))
        (error nil))
    nil))

(define-minor-mode prisma-query-response-mode
  "Allows Prisma query response buffer to be closed with (q)"
  :lighter " Prisma Response"
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "q") 'quit-window)
            map))

(defun prisma-send-query ()
  "Send the current Prisma query/mutation/subscription to server."
  (interactive)
  (let* ((url (or prisma-url (read-string "Prisma URL: " )))
         (var (or prisma-variables-file (read-file-name "Prisma Variables: "))))
    (let ((prisma-url url)
          (prisma-variables-file var))

      (let* ((query (buffer-substring-no-properties (point-min) (point-max)))
             (operation (prisma-current-operation))
             (variables (prisma-current-variables var))
             (response (prisma--query query operation variables)))
        (with-current-buffer-window
         "*Prisma*" 'display-buffer-pop-up-window nil
         (erase-buffer)
         (when (fboundp 'json-mode)
           (json-mode))
         (insert (json-encode (request-response-data response)))
         (json-pretty-print-buffer)
         (goto-char (point-max))
         (insert "\n\n"
                 (propertize (request-response--raw-header response)
                             'face 'font-lock-comment-face
                             'font-lock-face 'font-lock-comment-face))
         (prisma-query-response-mode))))
    ;; If the query was successful, then save the value of prisma-url
    ;; in the current buffer (instead of the introduced local
    ;; binding).
    (setq prisma-url url)
    (setq prisma-variables-file var)
    nil))

(defvar prisma-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-c") 'prisma-send-query)
    (define-key map (kbd "C-c C-l") 'prisma-select-endpoint)
    map)
  "Key binding for Prisma mode.")

(defvar prisma-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?\# "<" st)
    (modify-syntax-entry ?\n ">" st)
    (modify-syntax-entry ?\$ "'" st)
    st)
  "Syntax table for Prisma mode.")


(defun prisma-indent-line ()
  "Indent Prisma schema language."
  (let ((position (point))
        (indent-pos))
    (save-excursion
      (let ((level (car (syntax-ppss (point-at-bol)))))

        ;; Handle closing pairs
        (when (looking-at "\\s-*\\s)")
          (setq level (1- level)))

        (indent-line-to (* prisma-indent-level level))
        (setq indent-pos (point))))

    (when (< position indent-pos)
      (goto-char indent-pos))))

(defvar prisma-keywords
  '("datasource" "generator" "model" "enum"
    "type" "input" "interface" "fragment"
    "query" "enum" "mutation" "subscription"
    "Int" "Float" "String" "Boolean" "ID"
    "true" "false" "null" "extend"
    "scalar" "union"))

(defun prisma-completion-at-point ()
  "Return the list of candidates for completion.
This is the function to be used for the hook `completion-at-point-functions'."
  (let* ((bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end prisma-keywords . nil)))


(defvar prisma-definition-regex
  (concat "\\(" (regexp-opt '("datasource" "generator" "model" "enum"
                              "type" "input" "interface" "fragment" "query"
                              "mutation" "subscription" "enum" "extend"
                              "scalar" "union")) "\\)"
                              "[[:space:]]+\\(\\_<.+?\\_>\\)")
  "Keyword Regular Expressions.")

(defvar prisma-builtin-types
  '("Int" "Float" "String" "Boolean" "ID")
  "Built-in Prisma Types.")

(defvar prisma-constants
  '("true" "false" "null")
  "Constant Prisma Types.")


;;; Check if the point is in an argument list.
(defun prisma--in-arguments-p ()
  "Return t if the point is in the arguments list of a Prisma query."
  (let ((opening (cl-second (syntax-ppss))))
    (eql (char-after opening) ?\()))


(defun prisma--field-parameter-matcher (limit)
  (catch 'end
    (while t
      (cond
       ;; If we are inside an argument list, try to match the first
       ;; argument that we find or exit the argument list otherwise, so
       ;; the search can continue.
       ((prisma--in-arguments-p)
        (let* ((end (save-excursion (up-list) (point)))
               (match (search-forward-regexp "\\(\\_<.+?\\_>\\):" end t)))
          (if match
              ;; unless we are inside a string or comment
              (let ((state (syntax-ppss)))
                (when (not (or (nth 3 state)
                               (nth 4 state)))
                  (throw 'end t)))
            (up-list))))
       (t
        ;; If we are not inside an argument list, jump after the next
        ;; opening parenthesis, and we will try again there.
        (skip-syntax-forward "^(" limit)
        (and (eobp) (throw 'end nil))
        (forward-char))))))


(defvar prisma-font-lock-keywords
  `(
    ;; Type definition
    ("\\(type\\)[[:space:]]+\\(\\_<.+?\\_>\\)"
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face)
     ("[[:space:]]+\\(implements\\)\\(?:[[:space:]]+\\(\\_<.+?\\_>\\)\\)?"
      nil nil
      (1 font-lock-keyword-face)
      (2 font-lock-function-name-face)))

    ;; Definitions
    (,prisma-definition-regex
     (1 font-lock-keyword-face)
     (2 font-lock-function-name-face))

    ;; Constants
    (,(regexp-opt prisma-constants) . font-lock-constant-face)

    ;; Variables
    ("\\$\\_<.+?\\_>" . font-lock-variable-name-face)

    ;; Types
    (":[[:space:]]*\\[?\\(\\_<.+?\\_>\\)\\]?"
     (1 font-lock-type-face))

    ;; Directives
    ("@\\_<.+?\\_>" . font-lock-keyword-face)

    ;; Field parameters
    (prisma--field-parameter-matcher
     (1 font-lock-variable-name-face)))
  "Font Lock keywords.")


;;;###autoload
(define-derived-mode prisma-mode prog-mode "Prisma"
  "A major mode to edit Prisma schemas."
  (setq-local comment-start "// ")
  (setq-local comment-start-skip "//+[\t ]*")
  (setq-local indent-line-function 'prisma-indent-line)
  (setq font-lock-defaults
        `(prisma-font-lock-keywords
          nil
          nil
          nil))
  (font-lock-add-keywords nil '(("//.+" . font-lock-comment-face)))
  (setq imenu-generic-expression `((nil ,prisma-definition-regex 2)))
  (add-hook 'completion-at-point-functions 'prisma-completion-at-point nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.prisma\\'" . prisma-mode))


(provide 'prisma-mode)
;;; prisma-mode.el ends here
