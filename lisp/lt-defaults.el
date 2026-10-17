;;; lt-defaults.el --- editor defaults that have nothing to do with a package -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(set-default-coding-systems 'utf-8)

;;;; the better defaults
(setq select-enable-clipboard t
      select-enable-primary t
      save-interprogram-paste-before-kill t
      mouse-yank-at-point t
      require-final-newline t
      visible-bell t
      load-prefer-newer t
      inhibit-startup-screen t
      create-lockfiles nil
      make-backup-files nil
      column-number-mode t
      scroll-error-top-bottom t
      show-paren-delay 0.5
      sentence-end-double-space nil
      ediff-window-setup-function 'ediff-setup-windows-plain
      fit-window-to-buffer-horizontally t)
;;
(setq browse-url-browser-function 'browse-url-default-browser)

;; buffer local variables
(setq-default
 indent-tabs-mode nil
 tab-width 4
 c-basic-offset 4)

;; auto-revert will reload buffer when the file changes underneath
(global-auto-revert-mode)

;; automatically save buffers
(auto-save-visited-mode 1)
(setq auto-save-visited-interval 1)

;; cleanup whitespace on save
(require 'whitespace)
(add-hook 'before-save-hook 'whitespace-cleanup)

(menu-bar-mode -1)
(when (fboundp 'tool-bar-mode)
  (tool-bar-mode -1))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode -1))
(when (fboundp 'horizontal-scroll-bar-mode)
  (horizontal-scroll-bar-mode -1))

(show-paren-mode 1)

;; tabs are evil
(setq-default indent-tabs-mode nil)
;; don't wrap long lines by default
(setq-default truncate-lines t)

(setq treesit-font-lock-level 4)

;; y/n for yes/no
(setq use-short-answers t) ;; emacs28
;;(defalias 'yes-or-no-p 'y-or-n-p)
(setq confirm-kill-emacs 'y-or-n-p)

(recentf-mode)

;; automatically save dirty buffers
(use-package super-save
  :config
  (setq super-save-auto-save-when-idle t)
  (super-save-mode +1))

(require 'server)
(unless (server-running-p)
  (server-start))

(provide 'lt-defaults)
;;; lt-defaults.el ends here
