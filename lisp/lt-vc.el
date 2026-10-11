;;; lt-vc.el --- git -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; Magit, VC
(use-package magit
  :custom
  (magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1)

  :config
  (require 'magit-extras)

  (keymap-unset magit-section-mode-map "M-1")
  (keymap-unset magit-section-mode-map "M-2")
  (keymap-unset magit-section-mode-map "M-3")
  (keymap-unset magit-section-mode-map "M-4"))

(use-package magit-todos
  :config
  (magit-todos-mode)
  (setq magit-todos-exclude-globs '("*.js.map" "*.css.map")))

(use-package forge
  :after (magit))

(with-eval-after-load 'project
  (which-key-add-key-based-replacements "C-x p m" "magit")
  (keymap-set project-prefix-map "m" #'magit-project-status)
  (add-to-list 'project-switch-commands
               '(magit-project-status "Magit") t))

(provide 'lt-vc)
;;; lt-vc.el ends here
