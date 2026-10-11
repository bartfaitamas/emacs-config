;;; lt-editing.el --- editing, parens, snippets, outlines -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;; Stefan Monnier <foo at acm.org>. It is the opposite of fill-paragraph
(defun unfill-paragraph (&optional region)
  "Take a multi-line paragraph as REGION and make it into a single line of text."
  (interactive (progn (barf-if-buffer-read-only) '(t)))
  (let ((fill-column (point-max))
        ;; This would override `fill-column' if it's an integer.
        (emacs-lisp-docstring-fill-column t))
    (fill-paragraph nil region)))

;; Handy key definition
(define-key global-map "\M-Q" 'unfill-paragraph)

(use-package undo-tree
  :delight
  :config
  (setq undo-tree-auto-save-history nil)
  (global-undo-tree-mode 1))

(use-package smart-hungry-delete
  :bind (("<backspace>" . smart-hungry-delete-backward-char)
         ("C-d" . smart-hungry-delete-forward-char))
  :config
  (smart-hungry-delete-add-default-hooks))



;;;;; AI
(use-package markdown-mode
  :hook
  (markdown-mode . visual-line-mode)
  (markdown-mode . (lambda () (setq truncate-lines nil))))

(use-package editorconfig
  :config
  (editorconfig-mode 1))


;; activate smartparens
(use-package smartparens
  :bind (:map smartparens-mode-map
              ("s-<delete>" . sp-kill-sexp)
              ("s-<backspace>" . sp-backward-kill-sexp))
  :hook (prog-mode text-mode markdown-mode)
  :config
  (require 'smartparens-config)

  (sp-use-smartparens-bindings)

  (sp-pair "(" ")" :wrap "C-(") ;; how do people live without this?
  (sp-pair "[" "]" :wrap "M-[") ;; C-[ sends ESC
  (sp-pair "{" "}" :wrap "C-{"))


(use-package rainbow-delimiters
  :hook (prog-mode))

(use-package rainbow-mode
  :hook (org-mode
         emacs-lisp-mode
         web-mode
         typescript-mode
         js2-mode))

(use-package whitespace
  :config
  (setq whitespace-style '(face tabs newline empty
                                trailing tab-mark)))

(use-package hydra)

(use-package outline
  :ensure nil ; built-in
  :hook ((prog-mode . outline-minor-mode))
  :config
  ;; outline-cycle                     (<right-margin> <mouse-1>)
  ;; outline-cycle-buffer              (<right-margin> S-<mouse-1>)
  ;; outline-next-heading
  ;; outline-headers-as-kill
  ;; outline-previous-heading
  ;; outline-apply-default-state
  ;; outline-hide-by-heading-regexp    (C-c @ / h)
  ;; outline-show-by-heading-regexp    (C-c @ / s)
  (require 'outline)

  (defhydra hydra-outline (global-map "M-o")
    "outline"
    ("TAB" outline-cycle "cycle" :column "hide/show")
    ("h" outline-show-only-headings "show-only-headings")
    ("c" outline-toggle-children "toggle-children")
    ("E" outline-hide-entry "hide-entry")
    ("e" outline-show-entry "show-entry")
    ("t" outline-hide-body "hide-body")
    ("S" outline-hide-subtree "hide-subtree")
    ("s" outline-show-subtree "show-subtree")
    ("l" outline-hide-leaves "hide-leaves")
    ("k" outline-show-branches "show-branches")
    ("q" outline-hide-sublevels "hide-sublevels")
    ("o" outline-hide-other "hide-other")
    ("a" outline-show-all "show-all")

    ("u" outline-up-heading "up-heading" :column "Navigation")
    ("f" outline-forward-same-level "forward-same-level")
    ("b" outline-backward-same-level "backward-same-level")
    ("n" outline-next-visible-heading "next-visible-heading")
    ("p" outline-previous-visible-heading "previous-visible-heading")
    ;; (">" outline-demote)
    ;; ("<" outline-promote)
    ;; ("@" outline-mark-subtree)
    ;; ("RET" outline-insert-heading)
    ;; ("^" outline-move-subtree-up)
    ;; ("v" outline-move-subtree-down)
    ))

(use-package yasnippet
  :hook
  (prog-mode . yas-minor-mode))

(provide 'lt-editing)
;;; lt-editing.el ends here
