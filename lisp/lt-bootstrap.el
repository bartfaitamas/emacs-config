;;; lt-bootstrap.el --- package system, startup, housekeeping -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


;; The default is 800 kilobytes.  Measured in bytes.
(setq gc-cons-threshold (* 50 1000 1000))
(setq package-install-upgrade-built-in t)

;; Profile emacs startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "*** Emacs loaded in %s seconds with %d garbage collections."
                     (emacs-init-time "%.2f")
                     gcs-done)))

;; Silence compiler warnings as they can be pretty disruptive
(require 'comp-run)
(setq native-comp-async-report-warnings-errors nil)

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)

(package-initialize)

(setq use-package-always-ensure t)

(require 'use-package)

;; Keep generated files out of the way, in etc/ and var/.
(use-package no-littering
  :demand t
  :config
  (no-littering-theme-backups))

;; Keep customization settings in a temporary file (thanks Ambrevar!)
(setq custom-file
      (if (boundp 'server-socket-dir)
          (expand-file-name "custom.el" server-socket-dir)
        (expand-file-name (format "emacs-custom-%s.el" (user-uid)) temporary-file-directory)))
(load custom-file t)

(provide 'lt-bootstrap)
;;; lt-bootstrap.el ends here
