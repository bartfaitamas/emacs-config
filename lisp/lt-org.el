;;; lt-org.el --- org-mode, capture, babel -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; org-mode, calendar, diary
(use-package org
  :demand t
  :mode (("\\.org$" . org-mode))
  :bind (("C-c o c" . org-capture)
         ("C-c o a" . org-agenda))

  :hook
  (org-mode . org-indent-mode)
  (org-mode . visual-line-mode)
  (org-mode . variable-pitch-mode) ; Enable mixed-pitch in Org
  ;; NOTE: `visual-wrap-prefix-mode' must NOT be used together with
  ;; `org-indent-mode'.  Both set the `wrap-prefix' text property; the
  ;; former overwrites the latter on every redisplay, which is why
  ;; `org-indent-indent-buffer' had to be called repeatedly.  org-indent
  ;; already provides a correct `wrap-prefix' for soft-wrapped lines.

  :init
  (which-key-add-key-based-replacements "C-c o" "org-mode")

  (add-hook 'org-shiftup-final-hook 'windmove-up)
  (add-hook 'org-shiftleft-final-hook 'windmove-left)
  (add-hook 'org-shiftdown-final-hook 'windmove-down)
  (add-hook 'org-shiftright-final-hook 'windmove-right)

  :config
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map)

  (setq ;;org-pretty-entities nil
        ;; Edit settings
        org-fold-catch-invisible-edits 'show-and-error
        org-special-ctrl-a/e t
        org-insert-heading-respect-content t
        org-hide-emphasis-markers t      ; Hide *bold*, /italic/ markup tags
        org-pretty-entities t            ; Render LaTeX/symbols nicely (e.g., \alpha -> α)
        org-use-sub-superscripts nil     ; Don't render x_y as subscript (keep underscores visible)
        org-auto-align-tags nil          ; Prevent tag misalignment with variable-pitch fonts
        org-startup-align-all-tables t   ; Align all tables when visiting a file
        org-tags-column 0
        org-ellipsis "…"                 ; Subtle indicator for folded headers
        org-adapt-indentation nil
        org-hide-leading-stars t
        org-export-backends '(html beamer ascii latex md)
        org-agenda-files (list (expand-file-name "Inbox.org" org-directory))
        ;; Org styling, hide markup etc.
        org-agenda-tags-column 0
        org-refile-targets '((nil . (:maxlevel . 4))))

  (require 'org-capture)
  (require 'org-protocol)
  (require 'org-tempo)   ;; for <src expansion
  (add-to-list 'org-structure-template-alist '("src" . "src"))
  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("sc" . "src scheme"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
  (add-to-list 'org-structure-template-alist '("yaml" . "src yaml"))
  (add-to-list 'org-structure-template-alist '("json" . "src json"))
  (add-to-list 'org-structure-template-alist '("md" . "src markdown"))
  (add-to-list 'org-structure-template-alist '("puml" . "src plantuml"))
  (add-to-list 'org-structure-template-alist '("e" . "example"))
  (add-to-list 'org-structure-template-alist '("C" . "comment"))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((shell . t)
     (mermaid . t)
     (plantuml . t)))

  (setq org-plantuml-exec-mode 'plantuml)
  (put 'org-plantuml-exec-mode 'safe-local-variable 'symbolp)

  ;;; Org Capture
  ;;;; Thank you random guy from StackOverflow
  ;;;; http://stackoverflow.com/questions/23517372/hook-or-advice-when-aborting-org-capture-before-template-selection
  ;;;; https://fuco1.github.io/2017-09-02-Maximize-the-org-capture-buffer.html
  (defadvice org-capture
      (after make-full-window-frame activate)
    "Advise capture to be the only window when used as a popup"
    (if (equal "org-protocol-capture" (frame-parameter nil 'name))
        (delete-other-windows)))

  (add-hook 'org-capture-after-finalize-hook #'lt/org-capture-cleanup-when-org-protocol)

  ;;; Capture Templates
  ;; keys description type(entry|item|checkitem|table-line|plain) target template &rest
  ;; where &rest is properties
  (add-to-list
   'org-capture-templates
   '("t" "Todo" entry (file "Inbox.org")
     "* TODO %?\n   :PROPERTIES:\n   %t\n   :END:\n   %i\n    %a\n"
     :prepend t)))

(use-package ob-mermaid)

(use-package org-modern
  :ensure t
  :custom
  (org-modern-table nil)
  :config
  (global-org-modern-mode))

(use-package verb)

;; ------- end of vulpea

(defun lt/org-capture-cleanup-when-org-protocol ()
  "Clean up the frame created while capturing via org-protocol."
  (if (equal "org-protocol-capture" (frame-parameter nil 'name))
      (delete-frame)))

(provide 'lt-org)
;;; lt-org.el ends here
