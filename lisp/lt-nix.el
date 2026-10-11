;;; lt-nix.el --- nix -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


;;;; nixos
(use-package nix-mode
  :mode ("\\.nix\\'" "\\.nix.in\\'"))
(use-package nix-drv-mode
  :ensure nix-mode
  :mode "\\.drv\\'")
(use-package nix-shell
  :ensure nix-mode
  :commands (nix-shell-unpack nix-shell-configure nix-shell-build))
(use-package nix-repl
  :ensure nix-mode
  :commands (nix-repl))

(provide 'lt-nix)
;;; lt-nix.el ends here
