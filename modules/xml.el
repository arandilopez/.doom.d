;;; xml.el -*- lexical-binding: t; -*-

;; Pretty print a xml file
(defun nxml-pretty-format ()
  "Pretty print file buffer"
    (interactive)
    (save-excursion
        (shell-command-on-region (point-min) (point-max) "xmllint --format -" (buffer-name) t)
        (nxml-mode)
        (indent-region 0 (count-lines (point-min) (point-max))))
    (message "Ah! much better"))
