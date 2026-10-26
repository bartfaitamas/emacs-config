;;; lt-ui.el --- fonts, theme, frame, modeline -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package all-the-icons)
(use-package all-the-icons-dired)

;; Add frame borders and window dividers
(modify-all-frames-parameters
 '((right-divider-width . 20)
   (internal-border-width . 20)))
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))


;; A family that is not installed is substituted by Emacs, so naming them
;; here is safe on a machine that has a different set.
(set-face-attribute 'default nil
                    :family "Iosevka Term"
                    :height (if (eq system-type 'darwin) 150 110)
                    :weight 'medium)

;; Prose, in org and elsewhere.
(set-face-attribute 'variable-pitch nil
                    :family "Iosevka Aile"
                    :height 1.05)

;; Keeps code blocks and tables in org monospaced.
(set-face-attribute 'fixed-pitch nil
                    :family "Iosevka"
                    :height 1.0)

;; Breathing room between lines.
(setq-default line-spacing 0.15)

;; Enable Spacious Padding (if installed)
(use-package spacious-padding
  :ensure t
  :init
  (setq spacious-padding-widths
        '( :internal-border-width 15
           :header-line-width 4
           :mode-line-width 6
           :custom-button-width 3
           :tab-width 4
           :right-divider-width 30
           :scroll-bar-width 8
           :fringe-width 8))
  (setq spacious-padding-subtle-frame-lines t)
  (spacious-padding-mode 1))

(use-package beacon
  :config
  (setq beacon-blink-when-window-scroll nil)
  (beacon-mode 1))

(use-package delight)
(use-package modus-themes
  :bind ("<f5>" . modus-themes-toggle)
  :custom
  (custom-enabled-themes '(modus-operandi modus-vivendi))
  (modus-themes-bold-constructs t)
  (modus-themes-italic-constructs t)
  (modus-themes-mixed-fonts t)        ; Enables variable pitch support in themes
  (modus-themes-variable-pitch-ui t)
  (modus-themes-org-blocks 'tinted)  ; Subtle background tint for code blocks
  :init
  (require-theme 'modus-themes)
  (setq modus-themes-slanted-constructs t
        modus-themes-bold-constructs t)
  :config
  (load-theme 'modus-operandi t t)
  (load-theme 'modus-vivendi t t))


(use-package auto-dark
  :custom
  (auto-dark-themes '((modus-vivendi) (modus-operandi)))
  (auto-dark-polling-interval-seconds 5)
  ;; Only consulted on macOS, where it is the way to read the system theme.
  (auto-dark-allow-osascript t)
  (auto-dark-allow-powershell nil)
  :config
  (auto-dark-mode 1))


(use-package which-key
  :config
  (which-key-mode))

(use-package minions
  :config
  (setq minions-mode-line-lighter ";-")
  (minions-mode 1))

(provide 'lt-ui)
;;; lt-ui.el ends here
