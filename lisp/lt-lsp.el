;;; lt-lsp.el --- language server, diagnostics, debugger -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; Programming

;; Enable nice rendering of diagnostics like compile errors.
(use-package flycheck
  :init (global-flycheck-mode)
  :custom
  (flycheck-emacs-lisp-load-path 'inherit)
  (flycheck-emacs-lisp-initialize-packages t))


(use-package lsp-mode
  ;; Optional - enable lsp-mode automatically in scala files
  ;; You could also swap out lsp for lsp-deffered in order to defer loading
  :hook
  ;;(scala-mode . lsp-deferred)
  (scala-ts-mode . lsp-deferred)
  (lsp-mode . lsp-lens-mode)
  (lsp-mode . (lambda ()
                       (let ((lsp-keymap-prefix "C-c l"))
                         (lsp-enable-which-key-integration))))
  :bind-keymap
  ("C-c l" . lsp-command-map)
  :bind
  (:map lsp-command-map ("g s" . lsp-treemacs-symbols))

  :config
  ;; Uncomment following section if you would like to tune lsp-mode performance according to
  ;; https://emacs-lsp.github.io/lsp-mode/page/performance/
  ;; (setq gc-cons-threshold 100000000) ;; 100mb
  ;; (setq read-process-output-max (* 1024 1024)) ;; 1mb
  ;; (setq lsp-idle-delay 0.500)
  ;; (setq lsp-log-io nil)
  ;;(setq lsp-completion-provider :capf)

  ;; Makes LSP shutdown the metals server when all buffers in the project are closed.
  ;; https://emacs-lsp.github.io/lsp-mode/page/settings/mode/#lsp-keep-workspace-alive
  (setq lsp-eldoc-enable-hover nil
        lsp-signature-render-documentation nil
        lsp-keep-workspace-alive nil
        lsp-verify-signature nil
        lsp-completion-provider :capf
        lsp-headerline-breadcrumb-icons-enable 1
        lsp-headerline-arrow ">"))

;; Enable nice rendering of documentation on hover
;;   Warning: on some systems this package can reduce your emacs responsiveness significally.
;;   (See: https://emacs-lsp.github.io/lsp-mode/page/performance/)
;;   In that case you have to not only disable this but also remove from the packages since
;;   lsp-mode can activate it automatically.
(use-package lsp-ui)
(use-package lsp-treemacs)

;; Posframe is a pop-up tool that must be manually installed for dap-mode
(use-package posframe)

;; Use the Debug Adapter Protocol for running tests and debugging
(use-package dap-mode
  :hook
  (lsp-mode . dap-mode)
  (lsp-mode . dap-ui-mode))

(provide 'lt-lsp)
;;; lt-lsp.el ends here
