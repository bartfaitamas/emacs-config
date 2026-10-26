;;; lt-pkm.el --- notes as a graph: vulpea and PARA -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


(require 'cl-lib)
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
          vulpea-db-index-heading-level t
          vulpea-db-exclude-archived nil)
  (vulpea-db-autosync-mode 1))

(defun lt/org-ensure-todo-ids ()
  "Add :ID: to any heading with a TODO state that lacks one.
Runs only when vulpea is loaded and the buffer's file is tracked."
  (when (and (derived-mode-p 'org-mode)
             buffer-file-name
             (fboundp 'vulpea-db-sync-tracked-file-p)
             (vulpea-db-sync-tracked-file-p buffer-file-name))
    (org-map-entries
     (lambda ()
       (when (and (org-get-todo-state)
                  (not (org-id-get)))
         (org-id-get-create)))
     nil 'file)))

(add-hook 'before-save-hook #'lt/org-ensure-todo-ids)

(use-package vui
  :ensure t)

(use-package vulpea-ui
  :ensure t
  :bind (("C-c o b" . vulpea-ui-sidebar-toggle))
  :config
  (require 'vulpea)
  (require 'vui)
  (setq vulpea-ui-sidebar-position 'right
        vulpea-ui-sidebar-size 0.3))

(use-package vulpea-journal
  :ensure t
  :bind (("C-c o j" . vulpea-journal-today)
         ("C-c o J" . vulpea-journal-date))
  :config
  (require 'vulpea)
  (require 'vulpea-ui)
  (vulpea-journal-setup)
  (setq vulpea-journal-default-template
        '(:file-name "Daily/%Y-%m-%d.org"
          :title "%Y-%m-%d"
          :tags ("journal")
          :head "#+created: %<[%Y-%m-%d]>"
          :body "* Tasks\n\n* Log\n")))

(use-package vulpea-para
  :demand t
  :vc ( :url "https://github.com/d12frosted/vulpea-para"
        :rev :newest)
  :ensure t
  :bind (("C-c o a" . vulpea-para-agenda-main)
         ("C-c o p" . vulpea-para-find-project)
         ("C-c o P" . vulpea-para-capture-project)
         ("C-c o e" . vulpea-para-find-area)
         ("C-c o E" . vulpea-para-capture-area)
         ("C-c o r" . vulpea-para-find-resource)
         ("C-c o R" . lt/vulpea-para-capture-resource)
         ("C-c o w" . vulpea-para-agenda-person)
         ("C-c o W" . lt/vulpea-para-capture-person)
         ("C-c o n" . lt/vulpea-para-create)
         ("C-c o x" . lt/vulpea-para-archive))
  :config
  (require 'vulpea)
  (setopt vulpea-para-open-work-files '("Inbox.org"))
  (vulpea-para-setup-defaults)

  ;; Extend the main agenda with an "All open tasks" block (idempotent)
  (defun lt/vulpea-para--extend-main-agenda ()
    "Append the All-open-tasks block to the main PARA agenda when missing.
Does nothing when the command is absent from
`org-agenda-custom-commands' (e.g. during tests or if
`vulpea-para-setup-defaults' was not called)."
    (let* ((main   (assoc vulpea-para-agenda-main-key org-agenda-custom-commands))
           (blocks (caddr main)))
      (when main
        (unless (cl-some
                 (lambda (b)
                   (equal (cadr (assq 'org-agenda-overriding-header (caddr b)))
                          "All open tasks"))
                 blocks)
          (setcar (cddr main)
                  (append blocks
                          '((alltodo ""
                                     ((org-agenda-overriding-header "All open tasks")
                                      (org-agenda-todo-ignore-scheduled 'future)
                                      (org-agenda-todo-ignore-deadlines 'future))))))))))

  (lt/vulpea-para--extend-main-agenda)

  ;; Archived-note helpers
  (defun lt/vulpea-para--archived-tags (tags)
    "Return TAGS with `vulpea-para-area-tag' removed and Archive/ARCHIVE added.
\"Archive\" and `org-archive-tag' are appended if they are not already
present, and the original order of the remaining tags is preserved."
    (let ((result (remove vulpea-para-area-tag tags)))
      (dolist (tag (list "Archive" org-archive-tag))
        (unless (member tag result)
          (setq result (append result (list tag)))))
      result))

  (defun lt/vulpea-para-archive ()
    "Archive the current note by adjusting its file-level tags."
    (interactive)
    (save-excursion
      (goto-char (point-min))
      (let ((new-tags (lt/vulpea-para--archived-tags (vulpea-buffer-tags-get))))
        (apply #'vulpea-buffer-tags-set new-tags)
        (save-buffer)
        (message "Archived: %s" (vulpea-buffer-title-get)))))

  ;; PARA note creation
  (defun lt/vulpea-para-create (category title)
    "Create a new PARA note in CATEGORY with TITLE.
CATEGORY is one of \"Area\", \"Resource\", or \"Person\" and is read
interactively via `completing-read'. TITLE is read with `read-string'."
    (interactive
     (list (completing-read "PARA category: " '("Area" "Resource" "Person") nil t)
           (read-string "Title: ")))
    (cond
     ((string= category "Area")     (vulpea-para-capture-area title))
     ((string= category "Resource") (lt/vulpea-para-capture-resource title))
     ((string= category "Person")   (lt/vulpea-para-capture-person title))))

  ;; Deduplicate capture templates - vulpea-para-setup-defaults appends "p"
  ;; and "m" every time it runs, so re-evaluating this config block would
  ;; produce duplicates without this guard
  (setq org-capture-templates
        (cl-remove-duplicates org-capture-templates :key #'car :from-end t))

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

;;;;; lt/query-* - agent-callable knowledge base functions
;;
;; These functions are designed to be called by external agents (e.g. Claude
;; Code) via emacsclient. Each returns a human-readable string.
;;
;; Discovery from the command line
;;   emacsclient --eval '(describe-function (quote lt/query-journal))'
;;   emacsclient --eval '(apropos "lt/query")'
;;
;; Example agent invocations
;;   emacsclient --eval '(lt/query-journal "this-week")'
;;   emacsclient --eval '(lt/query-todos)'
;;   emacsclient --eval '(lt/query-project)'
;;   emacsclient --eval '(lt/query-para "Project")'
;;   emacsclient --eval '(lt/query-para)'
;;   emacsclient --eval '(lt/query-search "Some Area")'
;;   emacsclient --eval '(lt/query-recent 10)'

(declare-function vulpea-db-query "ext:vulpea-db-query")
(declare-function vulpea-db-query-by-tags-every "ext:vulpea-db-query")
(declare-function vulpea-para-projects "ext:vulpea-para-db")
(declare-function vulpea-para-archived-p "ext:vulpea-para-core")
(declare-function vulpea-para-area-of "ext:vulpea-para-db")
(declare-function vulpea-note-title "ext:vulpea-note")
(declare-function vulpea-note-path "ext:vulpea-note")
(declare-function vulpea-note-tags "ext:vulpea-note")
(declare-function vulpea-note-level "ext:vulpea-note")
(declare-function vulpea-note-todo "ext:vulpea-note")
(declare-function vulpea-note-p "ext:vulpea-note")

(defun lt/query-journal (&optional filter)
  "Return a summary of daily journal entries as a formatted string.
FILTER is one of: \"today\", \"yesterday\", \"this-week\" (default),
or a date string \"YYYY-MM-DD\". A date string returns the entries
from that date up to and including today, not just that one day."
  (let* ((filter (or filter "this-week"))
         (today (format-time-string "%Y-%m-%d"))
         (start (cond
                 ((equal filter "today") today)
                 ((equal filter "yesterday")
                  (format-time-string "%Y-%m-%d"
                                      (time-subtract (current-time)
                                                     (days-to-time 1))))
                 ((equal filter "this-week")
                  (format-time-string "%Y-%m-%d"
                                      (time-subtract (current-time)
                                                     (days-to-time 6))))
                 (t filter)))
         (end (if (member filter '("today" "yesterday")) start today))
         (notes (seq-filter
                 (lambda (n)
                   (let ((title (vulpea-note-title n)))
                     (and (string-match-p "^[0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}$" title)
                          (not (string< title start))
                          (not (string> title end)))))
                 (vulpea-db-query-by-tags-every '("journal"))))
         (sorted (seq-sort-by #'vulpea-note-title #'string> notes)))
    (if (null sorted)
        (format "No journal entries found for filter: %s" filter)
      (mapconcat
       (lambda (n)
         (let* ((path (vulpea-note-path n))
                (headings
                 (when (file-exists-p path)
                   (with-temp-buffer
                     (insert-file-contents path)
                     (let (hs)
                       (goto-char (point-min))
                       (while (re-search-forward "^\\*+ " nil t)
                         (push (buffer-substring-no-properties
                                (point) (line-end-position)) hs))
                       (mapconcat #'identity (reverse hs) "\n  "))))))
           (format "=== %s ===\n  %s\n  %s"
                   (vulpea-note-title n) path (or headings "(empty)"))))
       sorted "\n"))))

(defun lt/query-todos ()
  "Return all open TODO and INPROGRESS items as a formatted string."
  (let* ((items (vulpea-db-query
                 (lambda (n)
                   (and (member (vulpea-note-todo n) '("TODO" "INPROGRESS"))
                        (not (vulpea-para-archived-p n))))))
         (sorted (seq-sort-by
                  (lambda (n) (or (vulpea-note-todo n) ""))
                  #'string< items)))
    (if (null sorted)
        "No open TODO items found."
      (mapconcat
       (lambda (n)
         (format "[%s] %s\n      %s"
                 (vulpea-note-todo n)
                 (vulpea-note-title n)
                 (vulpea-note-path n)))
       sorted "\n"))))

(defun lt/query-project ()
  "Return all active PARA projects as a formatted string.
Projects are headings tagged with `vulpea-para-project-tag' inside an area note
and are listed as \"Area > Project\"."
  (let* ((projects (seq-remove #'vulpea-para-archived-p (vulpea-para-projects)))
         (rows (mapcar
                (lambda (p)
                  (let ((area (vulpea-para-area-of p)))
                    (list (format "%s > %s"
                                  (if area (vulpea-note-title area) "?")
                                  (vulpea-note-title p))
                          (or (vulpea-note-todo p) "")
                          (vulpea-note-path p))))
                projects))
         (sorted (seq-sort-by #'car #'string< rows)))
    (if (null sorted)
        "No projects found"
      (mapconcat
       (lambda (r)
         (format "[%-10s] %-50s  %s" (nth 1 r) (nth 0 r) (nth 2 r)))
       sorted "\n"))))

(defun lt/query-search (keyword)
  "Return notes whose title matches KEYWORD (case-insensitive) as a string."
  (let* ((notes (vulpea-db-query
                 (lambda (n)
                   (let ((case-fold-search t))
                     (string-match-p (regexp-quote keyword)
                                     (vulpea-note-title n))))))
         (sorted (seq-sort-by #'vulpea-note-title #'string< notes)))
    (if (null sorted)
        (format "No notes found matching: %s" keyword)
      (mapconcat
       (lambda (n)
         (format "%-50s  %s" (vulpea-note-title n) (vulpea-note-path n)))
       sorted "\n"))))

(defun lt/query-recent (&optional n)
  "Return N (default 10) most recently modified top-level notes as a string."
  (let* ((n (or n 10))
         (all (seq-filter (lambda (note) (= (vulpea-note-level note) 0))
                          (vulpea-db-query-by-level 0)))
         (sorted (seq-sort-by
                  (lambda (note)
                    (let ((path (vulpea-note-path note)))
                      (if (file-exists-p path)
                          (float-time (file-attribute-modification-time
                                       (file-attributes path)))
                        0.0)))
                  #'> all))
         (top (seq-take sorted n)))
    (mapconcat
     (lambda (note)
       (format "%-50s  [%s]  %s"
               (vulpea-note-title note)
               (string-join (vulpea-note-tags note) ", ")
               (vulpea-note-path note)))
     top "\n")))

(defun lt/query-para (&optional category)
  "Return notes in PARA CATEGORY as a formatted string.
CATEGORY is one of: \"Project\", \"Area\", \"Resource\",
\"Archive\", \"Person\", or nil for all categories.

Buckets follow vulpea-para: areas and people are file notes tagged
with `vulpea-para-area-tag' / `vulpea-para-people-tag', projects are
Project headings inside areas, archived notes carry the ARCHIVE tag,
and resources are the remaining live file-level notes."
  (let* ((files (vulpea-db-query (lambda (n) (= (vulpea-note-level n) 0))))
         (archived (seq-filter #'vulpea-para-archived-p files))
         (live (seq-remove #'vulpea-para-archived-p files))
         (tagged (lambda (tag) (seq-filter
                               (lambda (n) (member tag (vulpea-note-tags n)))
                               live)))
         (buckets
          (list (cons "Area" (funcall tagged vulpea-para-area-tag))
                (cons "Person" (funcall tagged vulpea-para-people-tag))
                (cons "Resource"
                      (seq-remove (lambda (n)
                                    (or (member vulpea-para-area-tag
                                                (vulpea-note-tags n))
                                        (member vulpea-para-people-tag
                                                (vulpea-note-tags n))
                                        (member "journal" (vulpea-note-tags n))))
                                  live))
                (cons "Archive" archived)))
         (rows
          (append
           (when (or (null category) (string= category "Project"))
             (mapcar (lambda (p)
                       (let ((area (vulpea-para-area-of p)))
                         (list "Project"
                               (format "%s > %s"
                                       (if area (vulpea-note-title area) "?")
                                       (vulpea-note-title p))
                               (vulpea-note-path p))))
                     ;; archived headings stay in the db (vulpea-db-exclude-archived nil)
                     (seq-remove #'vulpea-para-archived-p (vulpea-para-projects))))
           (mapcan (lambda (b)
                     (when (or (null category) (string= category (car b)))
                       (mapcar (lambda (n)
                                 (list (car b) (vulpea-note-title n)
                                       (vulpea-note-path n)))
                               (cdr b))))
                   buckets)))
         (sorted (seq-sort-by (lambda (r) (concat (nth 0 r) (nth 1 r)))
                              #'string< rows)))
    (if (null sorted)
        (format "No notes found for: %s" (or category "all categories"))
      (mapconcat
       (lambda (r) (format "[%-10s] %-40s  %s" (nth 0 r) (nth 1 r) (nth 2 r)))
       sorted "\n"))))


(provide 'lt-pkm)
;;; lt-pkm.el ends here
