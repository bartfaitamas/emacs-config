;;; lt-platform.el --- things that differ per operating system -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package envrc
  :hook
  ((after-init . envrc-global-mode)))

(use-package exec-path-from-shell
  :config
  (require 'exec-path-from-shell)
  (push "HISTFILE" exec-path-from-shell-variables)
  (push "SSH_AUTH_SOCK" exec-path-from-shell-variables)
  (exec-path-from-shell-initialize))

(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta)
  (menu-bar-mode 1)
  (when (executable-find "gls")
    (setq insert-directory-program "gls")))

(provide 'lt-platform)
;;; lt-platform.el ends here
