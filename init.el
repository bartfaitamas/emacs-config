;;; init.el --- composition -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))

(require 'lt-bootstrap)
(load (expand-file-name "local.el" user-emacs-directory) t t)

(setopt mcp-hub-servers
      '(("nixos" . (:command "uvx" :args ("mcp-nixos")))))

(use-package pinentry
  :config
  (pinentry-start))

(require 'lt-defaults)
(require 'lt-platform)
(require 'lt-ui)
(require 'lt-window)
(require 'lt-editing)
(require 'lt-dired)
(require 'lt-completion)
(require 'lt-project)
(require 'lt-vc)
(require 'lt-org)
(require 'lt-pkm)
(require 'lt-ai)
(require 'lt-ai-openrouter)
(require 'lt-lsp)
(require 'lt-lang-scala)
(require 'lt-lang-haskell)
(require 'lt-lang-android)
(require 'lt-lang-extra)
(require 'lt-formats)
(require 'lt-nix)
(require 'lt-finance)

(provide 'init)
;;; init.el ends here
