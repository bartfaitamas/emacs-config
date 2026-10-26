;;; early-init.el --- before the GUI and the package system -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(if (eq system-type 'darwin)
    (add-to-list 'default-frame-alist '(ns-transparent-titlebar . t))
  (add-to-list 'default-frame-alist '(undecorated . t)))

;; The native compilation cache is the one generated path `no-littering'
;; cannot theme, and it has to move before anything is compiled.
(when (and (fboundp 'startup-redirect-eln-cache)
           (fboundp 'native-comp-available-p)
           (native-comp-available-p))
  (startup-redirect-eln-cache
   (convert-standard-filename
    (expand-file-name "var/eln-cache/" user-emacs-directory))))

;;; early-init.el ends here
