;;; lt-ai.el --- LLM access -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package gptel
  :vc ( :url "https://github.com/karthink/gptel"
        :rev :newest)
  :bind (("C-c g a" . gptel-add)
         ("C-c g s" . gptel-send)
         ("C-c g r" . gptel-rewrite)
         ("C-c g m" . gptel-menu)
         ("C-c g c" . gptel))
  :init
  (which-key-add-key-based-replacements "C-c g" "gptel")

  :custom
  (gptel-directives
   '((code . "You are an expert software engineer. When editing code, output ONLY the modified code with no explanation unless asked. Preserve existing style and conventions.")
     (review . "You are a senior code reviewer. Analyze the code for bugs, security issues, performance problems, and style. Be specific and actionable. Always format responses as valid org-mode: use * headings, #+begin_src / #+end_src blocks, and Org lists. Do not use Markdown.")
     (refactor . "You are a refactoring expert. Suggest and implement improvements to code structure, readability, and maintainability. Show before/after.")
     (test . "You are a testing expert. Write comprehensive tests for the given code. Cover edge cases, error paths, and typical usage.")
     (explain . "You are a patient teacher. Explain code clearly, covering what it does, why design decisions were made, and potential pitfalls. Always format responses as valid org-mode: use * headings, #+begin_src / #+end_src blocks, and Org lists. Do not use Markdown.")
     (nix . "You are an expert in linux system administration and Nix, NixOS. Help improving my NixOS setup. Always format responses as valid org-mode: use * headings, #+begin_src / #+end_src blocks, and Org lists. Do not use Markdown.")
     (elisp . "You are an Emacs Lisp expert. Write idiomatic, efficient elisp. Use cl-lib where appropriate. Follow Emacs conventions.")))
  (gptel-org-branching-context nil)
  (gptel-default-mode 'org-mode)
  (gptel-include-reasoning nil)

  :config
  (require 'gptel-integrations))

(use-package gptel-magit
  :ensure t
  :hook (magit-mode . gptel-magit-install)

  :config
  (defun my/gptel-magit--request-filter-reasoning (orig-fn prompt &rest kwargs)
    "Advice around `gptel-magit--request' to ignore reasoning blocks.
OpenAI-compatible backends (e.g. OpenRouter) deliver reasoning content
as `(reasoning . text)' cons cells to the callback, which gptel-magit
doesn't handle — it passes the cons cell to `insert', causing
`Wrong type argument: char-or-string-p'.  This wraps the callback to
skip any non-string response.  Fixes both commit generation and
diff-explain, which both go through `gptel-magit--request'."
    (let ((cb (plist-get kwargs :callback)))
      (apply orig-fn prompt
             (if cb
                 (plist-put kwargs :callback
                            (lambda (response info)
                              (when (stringp response)
                                (funcall cb response info))))
               kwargs))))

  (advice-add 'gptel-magit--request :around
              #'my/gptel-magit--request-filter-reasoning)

  ;; Custom commit prompt: extend the default Conventional Commits prompt
  ;; with strict bullet list formatting rules to prevent the LLM from
  ;; starting continuation lines with "-" instead of indenting them.
  (setq gptel-magit-commit-prompt
        (concat gptel-magit-prompt-conventional-commits
                "\n\n"
                "When using bullet lists in the commit body, follow these "
                "formatting rules strictly:\n"
                "- Each bullet starts with \"- \"\n"
                "- Each bullet MUST start at the beginning of a line\n"
                "- Continuation lines of a bullet MUST be indented with 2 "
                "spaces to align with the text after \"- \"\n"
                "- Each bullet must be complete (ending with punctuation or "
                "a closing parenthesis) before the next bullet starts\n"
                "- NEVER start a continuation line with \"-\"\n"
                "- Wrap lines at approximately 70 characters\n\n"
                "Correct example:\n"
                "- Use write-contents-functions + set-visited-file-name "
                "(no key\n"
                "  rebinding)\n"
                "- Sanitize LLM response into a filesystem-safe slug "
                "(50 char max)\n\n"
                "Incorrect (do NOT do this):\n"
                "- Use write-contents-functions + set-visited-file-name "
                "(no key\n"
                "- rebinding) Sanitize LLM response into a filesystem-safe "
                "slug")))


(use-package gptel-agent
  :ensure t
  :vc ( :url "https://github.com/bartfaitamas/gptel-agent"
        :rev "newdirection")
  :config
  (gptel-agent-update))

(use-package mcp
  :after gptel
  :config (require 'mcp-hub))

(use-package agent-shell
  :ensure t)

(with-eval-after-load 'project
  (which-key-add-key-based-replacements "C-x p a" "gptel-agent")
  (keymap-set project-prefix-map "a" #'gptel-agent))

(provide 'lt-ai)
;;; lt-ai.el ends here
