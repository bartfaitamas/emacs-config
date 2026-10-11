;;; lt-lang-haskell.el --- haskell -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;;; Haskell

(use-package haskell-mode
  :hook
  (haskell-mode . lsp-deferred)
  (haskell-mode . interactive-haskell-mode)
  :config
  ;; (require 'ghcid)
  (require 'haskell-interactive-mode)
  (require 'haskell-process)
  (require 'haskell-hoogle)

  (define-key haskell-mode-map (kbd "C-c C-h") 'hoogle)
  (setq haskell-hoogle-command (lambda () (executable-find "hoogle")))

  (setq
   haskell-indentation-left-offset 4
   haskell-indentation-layout-offset 4
   haskell-indentation-starter-offset 4
   haskell-indentation-where-pre-offset 2
   haskell-indentation-where-post-offset 2
   ;; haskell-process-type 'cabal-repl
   haskell-process-suggest-remove-import-lines t
   haskell-process-auto-import-loaded-modules t
   haskell-process-log t))
;; TODO: this doesn't work, the haskell-snippets-initialize resolve the wrong relative directory
;; (setup (:pkg haskell-snippets))

(use-package lsp-haskell
  :config
  (setq lsp-haskell-server-path "haskell-language-server"
        lsp-haskell-formatting-provider "stylish-haskell"))

(provide 'lt-lang-haskell)
;;; lt-lang-haskell.el ends here
