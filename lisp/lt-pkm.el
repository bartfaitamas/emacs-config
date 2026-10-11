;;; lt-pkm.el --- notes as a graph: vulpea and PARA -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


(require 'lt-org)

;; ------- vulpea
(use-package vulpea
  :ensure t
  :bind (("C-c o f" . vulpea-find)
         ("C-c o i" . vulpea-insert))
  :config
  (require 'vulpea)
  (setopt vulpea-db-location (no-littering-expand-var-file-name "vulpea.db")
          vulpea-db-sync-directories (list (file-name-as-directory org-directory))
          vulpea-db-index-heading-level nil) ; Disable heading-level notes for performance
  (vulpea-db-autosync-mode 1))

(use-package vui
  :ensure t)

(use-package vulpea-ui
  :ensure t
  :bind (("C-c o t" . vulpea-ui-sidebar-toggle))
  :config
  (require 'vulpea)
  (require 'vui)
  (setq vulpea-ui-sidebar-position 'right
        vulpea-ui-sidebar-size 0.3))

(use-package vulpea-journal
  :ensure t
  :bind (("C-c o j" . vulpea-journal))
  :config
  (require 'vulpea)
  (require 'vulpea-ui)
  (vulpea-journal-setup)
  (setq vulpea-journal-default-template
        '(:file-name "Daily/%Y-%m-%d.org"
          :title "%Y-%m-%d"
          :tags ("journal")
          :head "#+created: %<[%Y-%m-%d]>")))

(use-package vulpea-para
  :demand t
  :vc ( :url "https://github.com/d12frosted/vulpea-para"
        :rev :newest)
  :ensure t
  :bind (("C-c o p" . vulpea-para-find-project)
         ("C-c o r" . vulpea-para-find-resource)
         ("C-c o v" . vulpea-para-find-area)
         ("C-c o P" . vulpea-para-capture-project)
         ("C-c o A" . vulpea-para-capture-area)
         ("C-c o g" . vulpea-para-agenda-main))
  :config
  (require 'vulpea)
  (vulpea-para-setup-defaults)

  (defcustom lt/vulpea-para-capture-resource-file-name "${timestamp}_${slug}.org"
    "File-name template for a new resource or person, passed to `vulpea-create'."
    :type 'string
    :group 'vulpea-para)

  (defcustom lt/vulpea-para-capture-resource-body "* Notes"
    "Body seeded into a new resource note by `lt/vulpea-para-capture-resource'."
    :type 'string
    :group 'vulpea-para)

  (defcustom lt/vulpea-para-capture-person-body "* Notes\n\n* Meetings"
    "Body seeded into a new person note by `lt/vulpea-para-capture-person'.

The `* Meetings' heading is where `vulpea-para-capture-meeting-target'
files meetings about that person."
    :type 'string
    :group 'vulpea-para)

  (defun lt/vulpea-para-capture-resource (title &optional no-visit)
    "Create a resource note titled TITLE and return it.

Like `vulpea-para-capture-area', but for a plain PARA resource: a
file-level note with no special tag (resources are the baseline
facet).  Seeds `lt/vulpea-para-capture-resource-body' and visits the
note unless NO-VISIT."
    (interactive (list (string-trim (read-string "Resource: "))))
    (when (string-empty-p title)
      (user-error "Resource name cannot be empty"))
    (let ((note (vulpea-create
                 title lt/vulpea-para-capture-resource-file-name
                 :body lt/vulpea-para-capture-resource-body)))
      (unless no-visit
        (vulpea-visit note))
      note))

  (defun lt/vulpea-para-capture-person (title &optional no-visit)
    "Create a person note titled TITLE and return it.

A person is a resource tagged with `vulpea-para-people-tag', so
meetings and tasks can be filed under them.  Seeds
`lt/vulpea-para-capture-person-body' (with a `* Meetings' heading) and
visits the note unless NO-VISIT."
    (interactive (list (string-trim (read-string "Person: "))))
    (when (string-empty-p title)
      (user-error "Person name cannot be empty"))
    (let ((note (vulpea-create
                 title lt/vulpea-para-capture-resource-file-name
                 :tags (list vulpea-para-people-tag)
                 :body lt/vulpea-para-capture-person-body)))
      (unless no-visit
        (vulpea-visit note))
      note))

  (defun lt/vulpea-para-capture-resource-target ()
    "Org capture target for a new resource note.

Prompts for the title, creates the file with
`lt/vulpea-para-capture-resource' (no-visit), and leaves point at the
top of the new note; the template inserts nothing extra."
    (let* ((title (string-trim (read-string "Resource: ")))
           (note (lt/vulpea-para-capture-resource title 'no-visit))
           (path (vulpea-note-path note)))
      (set-buffer (org-capture-target-buffer path))
      (unless (derived-mode-p 'org-mode)
        (org-mode))
      (org-capture-put-target-region-and-position)
      (widen)
      (goto-char (point-min))))

  (defun lt/vulpea-para-capture-person-target ()
    "Org capture target for a new person note.

Like `lt/vulpea-para-capture-resource-target', but creates a person
tagged with `vulpea-para-people-tag'."
    (let* ((title (string-trim (read-string "Person: ")))
           (note (lt/vulpea-para-capture-person title 'no-visit))
           (path (vulpea-note-path note)))
      (set-buffer (org-capture-target-buffer path))
      (unless (derived-mode-p 'org-mode)
        (org-mode))
      (org-capture-put-target-region-and-position)
      (widen)
      (goto-char (point-min))))

  ;; add-to-list instead of append so re-evaluating the config does not
  ;; duplicate the entries (that is how "p"/"m" ended up twice).
  (add-to-list
   'org-capture-templates
   '("r" "Resource" plain
     (function lt/vulpea-para-capture-resource-target)
     "%?"
     :unnarrowed t
     :kill-buffer t)
   t)
  (add-to-list
   'org-capture-templates
   '("e" "Person" plain
     (function lt/vulpea-para-capture-person-target)
     "%?"
     :unnarrowed t
     :kill-buffer t)
   t))

(defun lt/vulpea-web-capture-target ()
  "Org capture target for a web page captured via org-protocol.

Creates the note with `vulpea-create' so it gets an ID, a slugged
file name and a db entry."
  (let* ((link (plist-get org-store-link-plist :link))
         (title (or (org-string-nw-p (plist-get org-store-link-plist :description))
                    link
                    "Untitled web capture"))
         (note (vulpea-create
                title
                (lambda (title)
                  (expand-file-name
                   (format "%s_%s.org"
                           (format-time-string "%Y%m%d%H%M%S")
                           (truncate-string-to-width (vulpea-title-to-slug title) 60))
                   (expand-file-name "web/" org-directory)))
                :tags '("reference")
                :meta (when link `(("source" . ,link)))))
         (path (vulpea-note-path note)))
    (set-buffer (org-capture-target-buffer path))
    (unless (derived-mode-p 'org-mode)
      (org-mode))
    (org-capture-put-target-region-and-position)
    (widen)
    (goto-char (point-max))))

(with-eval-after-load 'org-capture
  (add-to-list
   'org-capture-templates
   '("l" "Web capture" plain
     (function lt/vulpea-web-capture-target)
     "%i\n\n%?"
     :unnarrowed t)
   t))

(provide 'lt-pkm)
;;; lt-pkm.el ends here
