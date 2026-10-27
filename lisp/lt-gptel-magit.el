;;; lt-gptel-magit.el --- Generate commit messages for magit using gptel -*- lexical-binding: t; -*-

;; Copyright (C) 2025 Authors
;; SPDX-License-Identifier: Apache-2.0

;; Vendored and modified from gptel-magit 20250520.833 (f27c01821b67)
;; by Ragnar Dahlén <r.dahlen@gmail.com>,
;; https://github.com/ragnard/gptel-magit

;;; Commentary:

;; Generate commit messages and explain diffs in magit using gptel.

;;; Code:

(require 'gptel)
(require 'magit)
(require 'markdown-mode)

(defvar lt-gptel-magit-model nil
  "The gptel model to use, defaults to `gptel-model' if nil.")

(defvar lt-gptel-magit-backend nil
  "The gptel backend to use, defaults to `gptel-backend' if nil.")

(defvar lt-gptel-magit-commit-prompt
  "You are an expert at writing Git commits. Your job is to write a short clear commit message that summarizes the changes.

The commit message should be structured as follows:

    <type>(<optional scope>): <description>

    [optional body]

- Commits MUST be prefixed with a type, which consists of one of the followings words: build, chore, ci, docs, feat, fix, perf, refactor, style, test
- The type feat MUST be used when a commit adds a new feature
- The type fix MUST be used when a commit represents a bug fix
- An optional scope MAY be provided after a type. A scope is a phrase describing a section of the codebase enclosed in parenthesis, e.g., fix(parser):
- A description MUST immediately follow the type/scope prefix. The description is a short description of the code changes, e.g., fix: array parsing issue when multiple spaces were contained in string.
- Try to limit the whole subject line to 72 characters
- Capitalize the subject line
- Use the imperative mood in the subject line
- Do not end the subject line with any punctuation
- If you can accurately express the change in just the subject line, don't include anything in the message body. Only use the body when it is providing *useful* information.
- A longer commit body MAY be provided after the short description, providing additional contextual information about the code changes. The body MUST begin one blank line after the description.
- When the body describes several changes, write it as a bullet list. Each bullet starts with \"- \" at the beginning of a line.
- Don't repeat information from the subject line in the message body.
- Wrap body lines at approximately 72 characters
- Keep the body short and concise (omit it entirely if not useful)"
  "The system prompt for generating a commit message from a staged diff.
Adapted from Conventional Commits (https://www.conventionalcommits.org/en/v1.0.0/).")

(defvar lt-gptel-magit-diff-explain-prompt
  "You are an expert at understanding and explaining code changes by reading diff output. Your job is to write a short clear summary explanation of the changes. Answer in Markdown format."
  "The system prompt for explaining a diff.")

(defun lt-gptel-magit--request (system prompt callback)
  "Send PROMPT with SYSTEM prompt, call CALLBACK with the text response."
  (let ((gptel-backend (or lt-gptel-magit-backend gptel-backend))
        (gptel-model (or lt-gptel-magit-model gptel-model)))
    (gptel-request prompt
      :system system
      :context nil
      :callback (lambda (response info)
                  (cond ((stringp response) (funcall callback response))
                        ((null response)
                         (message "gptel-magit: %s" (plist-get info :status))))))))

(defun lt-gptel-magit--format-commit-message (message)
  "Fill commit MESSAGE body at 72 columns as Markdown.
Trailer lines are kept as separate paragraphs."
  (with-temp-buffer
    (insert (string-trim message))
    (delay-mode-hooks (markdown-mode))
    (setq-local fill-column 72
                paragraph-start (concat "[A-Za-z-]+: \\|BREAKING CHANGE: \\|"
                                        paragraph-start))
    (goto-char (point-min))
    (forward-line 1)
    (fill-region (point) (point-max))
    (buffer-string)))

(defun lt-gptel-magit--generate (callback)
  "Generate a commit message for the staged changes, then call CALLBACK."
  (lt-gptel-magit--request lt-gptel-magit-commit-prompt
                           (magit-git-output "diff" "--cached")
                           (lambda (response)
                             (funcall callback
                                      (lt-gptel-magit--format-commit-message
                                       response)))))

(defun lt-gptel-magit-generate-message ()
  "Generate a commit message when in the git commit buffer."
  (interactive)
  (unless (magit-commit-message-buffer)
    (user-error "No commit in progress"))
  (lt-gptel-magit--generate (lambda (message)
                              (with-current-buffer (magit-commit-message-buffer)
                                (save-excursion
                                  (goto-char (point-min))
                                  (insert message)))))
  (message "gptel-magit: Generating commit message..."))

(defun lt-gptel-magit-commit-generate (&optional args)
  "Create a new commit with a generated commit message.
Uses ARGS from transient mode."
  (interactive (list (magit-commit-arguments)))
  (lt-gptel-magit--generate
   (lambda (message)
     (magit-commit-create (append args `("--message" ,message "--edit")))))
  (message "gptel-magit: Generating commit..."))

(defun lt-gptel-magit--show-explanation (text)
  "Pop up a Markdown buffer showing TEXT."
  (with-current-buffer (get-buffer-create "*gptel-magit diff-explain*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert text))
    (markdown-view-mode)
    (goto-char (point-min))
    (pop-to-buffer (current-buffer))))

(defun lt-gptel-magit-diff-explain ()
  "Ask for an explanation of diff at current section."
  (interactive)
  (when-let* ((section (magit-current-section))
              (content (buffer-substring (oref section content)
                                         (oref section end))))
    (lt-gptel-magit--request lt-gptel-magit-diff-explain-prompt
                             content
                             #'lt-gptel-magit--show-explanation)
    (message "gptel-magit: Explaining diff...")))

(provide 'lt-gptel-magit)
;;; lt-gptel-magit.el ends here
