;;; lt-project.el --- projects and terminals -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


;;;; use some terminal emulators
(use-package eat)

;;;; Project keybindings (C-x p prefix)
(use-package vterm
  :commands vterm)

(defun lt/project-vterm (&optional arg)
  "Open a vterm at the current project's root directory.
Reuse an existing project vterm buffer if one exists.
With prefix ARG, always create a new vterm buffer."
  (interactive "P")
  (let* ((pr (project-current t))
         (default-directory (project-root pr))
         (buf-name (format "*vterm[%s]*" (file-name-nondirectory
                                          (directory-file-name default-directory))))
         (existing (and (not arg) (get-buffer buf-name))))
    (if existing
        (pop-to-buffer existing)
      (vterm buf-name))))



(with-eval-after-load 'project
  (which-key-add-key-based-replacements "C-x p v" "project-vterm")
  (keymap-set project-prefix-map "v" #'lt/project-vterm))

(use-package xterm-color)

(provide 'lt-project)
;;; lt-project.el ends here
