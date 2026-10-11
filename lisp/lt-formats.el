;;; lt-formats.el --- configuration and markup formats -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package yaml-mode)
(use-package just-mode)
(use-package plantuml-mode
  :mode ("\\.puml\\'" "\\.plantuml\\'")
  :config
  (setq plantuml-default-exec-mode 'executable))

(use-package systemd)

(use-package restclient)


;;;;; k8s, terraform
(use-package terraform-mode
  :custom
  (terraform-indent-level 2)
  (terraform-format-on-save t)
  :bind-keymap
  ("C-c t" . terraform-mode-map))

(provide 'lt-formats)
;;; lt-formats.el ends here
