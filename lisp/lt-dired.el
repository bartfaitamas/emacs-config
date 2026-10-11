;;; lt-dired.el --- dired and icons -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;;; dired

(use-package dired
  :ensure nil
  :config
  (setq dired-dwim-target t
        dired-listing-switches "-al --group-directories-first --time-style \"+%m-%d-%Y %H:%M:%S\""
        dired-omit-files "^\\.[^.].*")
  (add-hook 'dired-mode-hook
            (lambda ()
              (interactive)
              (dired-omit-mode 1)
              ;; (all-the-icons-dired-mode 1)
              (hl-line-mode 1)))
  (autoload 'dired-omit-mode "dired-x"))

(provide 'lt-dired)
;;; lt-dired.el ends here
