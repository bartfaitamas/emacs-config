;;; lt-dired.el --- dired and icons -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;;; dired

(defun lt/dired-listing-switches ()
  "Return Dired listing switch appropriate for the current OS and ls binary.
On MacOS, returns plain \"-al\" unless `insert-directory-program' is gls
(GNU ls); in all other cases returns the full GNU ls flags including
--group-directories-first."
  (if (and (eq system-type 'darwin)
           (not (string= (file-name-nondirectory insert-directory-program) "gls")))
      "-al"
    "-al --group-directories-first --time-style \"+%m-%d-%Y %H:%M:%S\""))

(use-package dired
  :ensure nil
  :config
  (setq dired-dwim-target t
        dired-listing-switches (lt/dired-listing-switches)
        dired-omit-files "^\\.[^.].*")
  (add-hook 'dired-mode-hook
            (lambda ()
              (interactive)
              (dired-omit-mode 1)
              ;; (all-the-icons-dired-mode 1)
              (hl-line-mode 1)))
  (autoload 'dired-omit-mode "dired-x"))

(use-package dired-collapse)

(provide 'lt-dired)
;;; lt-dired.el ends here
