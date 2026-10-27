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

(use-package lt-gptel-magit
  :ensure nil
  :after magit
  :config
  (keymap-set git-commit-mode-map "M-g" #'lt-gptel-magit-generate-message)
  (transient-append-suffix 'magit-commit #'magit-commit-create
    '("g" "Generate commit" lt-gptel-magit-commit-generate))
  (transient-append-suffix 'magit-diff #'magit-stash-show
    '("x" "Explain" lt-gptel-magit-diff-explain)))


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
