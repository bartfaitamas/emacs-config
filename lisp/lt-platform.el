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
  (exec-path-from-shell-initialize))

(provide 'lt-platform)
;;; lt-platform.el ends here
