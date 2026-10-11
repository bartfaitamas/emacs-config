;;; lt-window.el --- windows, tabs, movement -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


;;;; tab-bar mode
(use-package tab-bar
  :bind (("M-<tab>" . tab-next)
         ("C-c C-t n" . tab-new)
         ("C-c C-t c" . tab-close)
         ("C-c C-t m" . tab-move)
         ("C-c C-t f" . tab-next)
         ("C-c C-t b" . tab-previous))
  :hook emacs-startup
  :init
  (which-key-add-key-based-replacements "C-c C-t" "tabs")
  :config
  (tab-bar-history-mode -1)
  (setq tab-bar-select-tab-modifiers '(meta)
        tab-bar-tab-hints t
        tab-bar-show nil))



(use-package tab-bar-echo-area
  :config
  (tab-bar-echo-area-mode 1))

(use-package winner
  :config
  (winner-mode))

(use-package mwim
  :bind (("C-a" . mwim-beginning-of-code-or-line)
         ("C-e" . mwim-end-of-code-or-line)))

(use-package windmove
  :demand t
  :bind (("C-c C-w l" . windmove-right)
         ("C-c C-w h" . windmove-left)
         ("C-c C-w j" . windmove-down)
         ("C-c C-w k" . windmove-up)
         ("C-c C-w C-l" . windmove-right)
         ("C-c C-w C-h" . windmove-left)
         ("C-c C-w C-j" . windmove-down)
         ("C-c C-w C-k" . windmove-up))
  :config
  (windmove-default-keybindings))

;; TODO: Setup corfu, vertico, orderless, marginalia, embark
(use-package ace-window
  :bind
  (("C-c w a" . ace-select-window)
   ("C-c w s" . ace-swap-window)
   ("C-c w d" . ace-delete-window)
   ("C-c w D" . ace-delete-other-windows))
  :init
  (which-key-add-key-based-replacements "C-c w" "window"))

(provide 'lt-window)
;;; lt-window.el ends here
