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

(defun lt/split-window-left (&optional size window-to-split)
  "Split WINDOW-TO-SPLIT, creating a new window on its left.
WINDOW-TO-SPLIT defaults to the selected window.  Positive SIZE sets the
width of WINDOW-TO-SPLIT, negative SIZE the width of the new window.
Return the new window."
  (interactive `(,(when current-prefix-arg
                   (prefix-numeric-value current-prefix-arg))
                 ,(selected-window)))
  (let (new-window)
    (when (and size (< size 0) (< (- size) window-min-width))
      ;; `split-window' would not signal an error here
      (error "Size of new window too small"))
    (setq new-window (split-window window-to-split size 'left))
    ;; Always copy quite-restore parameter in interactive use.
    (let ((quit-restore (window-parameter window-to-split 'quit-restore)))
      (when quit-restore
        (set-window-parameter new-window 'quit-restore quit-restore)))
    new-window))

;; TODO: take side window into consideration somehow
(defun lt/split-root-window-left (&optional size)
  "Split the frame's root window, creating a full-height window on the left.
SIZE is as in `lt/split-window-left'."
  (interactive `(,(when current-prefix-arg
                    (prefix-numeric-value current-prefix-arg))))
  (lt/split-window-left size (frame-root-window)))


;; TODO: Setup corfu, vertico, orderless, marginalia, embark
(use-package ace-window
  :bind
  (("C-c w a" . ace-select-window)
   ("C-c w s" . ace-swap-window)
   ("C-c w d" . ace-delete-window)
   ("C-c w D" . ace-delete-other-windows))
  :init
  (which-key-add-key-based-replacements "C-c w" "window"))

(use-package popper
  :bind (("C-`" . popper-toggle)
         ("M-`" . popper-cycle)
         ("C-M-`" . popper-toggle-type))
  :init
  (setq popper-reference-buffers
        '("\\*Messages\\*"
          "Output\\*$"
          "\\*Async Shell Command\\*"
          help-mode
          compilation-mode))
  (popper-mode +1)
  (popper-echo-mode +1))

(provide 'lt-window)
;;; lt-window.el ends here
