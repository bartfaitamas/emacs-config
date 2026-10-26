;;; lt-lang-scala.el --- scala -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:


;;;; Scala
;; Enable scala-mode for highlighting, indentation and motion commands
;; (use-package scala-mode
;;   :mode ("\\.sc\\'" . scala-mode)
;;   :interpreter ("scala" . scala-mode)
;;   :config
;;   (add-hook 'scala-mode-hook
;;             (lambda () (show-paren-mode)))
;;   (setq scala-indent:use-javadoc-style nil))

(use-package scala-ts-mode
  :mode (("\\.sc\\'" . scala-ts-mode)
         ("\\.scala\\'" . scala-ts-mode))
  :init
  (add-to-list 'major-mode-remap-alist '(scala-mode . scala-ts-mode))
  ;; scala-ts-mode does not say where its grammar comes from, so a machine
  ;; without packaged grammar cannot install it.
  (with-eval-after-load 'treesit
    (add-to-list 'treesit-language-source-alist
                 '(scala "https://github.com/tree-sitter/tree-sitter-scala")))
  :interpreter ("scala" . scala-ts-mode)
  :hook (scala-ts-mode . (lambda () (show-paren-mode)))
  :config
  ;; Runs while the first Scala file autoloads the mode, before the mode
  ;; checks for the grammar; offers to install it when it is missing
  (when (fboundp 'treesit-ensure-installed)
    (treesit-ensure-installed 'scala))
  (add-to-list 'auto-mode-alist '("\\.\\(scala\\|sbt\\|worksheet\\.sc\\)\\'" . scala-ts-mode)))


;; Enable sbt mode for executing sbt commands
(use-package sbt-mode
  :after (scala-ts-mode)
  :commands sbt-start sbt-command
  :config
  ;; WORKAROUND: https://github.com/ensime/emacs-sbt-mode/issues/31
  ;; allows using SPACE when in the minibuffer
  (substitute-key-definition
   'minibuffer-complete-word
   'self-insert-command
   minibuffer-local-completion-map)
   ;; sbt-supershell kills sbt-mode:  https://github.com/hvesalai/emacs-sbt-mode/issues/152
  (setq sbt:program-options '("-Dsbt.supershell=false"))
  (setq sbt:prefer-nested-projects t))


;; Add metals backend for lsp-mode
(use-package lsp-metals
  :init
  (setq lsp-metals-multi-root nil)
  :custom
  ;; ;; You might set metals server options via -J arguments. This might not always work, for instance when
  ;; ;; metals is installed using nix. In this case you can use JAVA_TOOL_OPTIONS environment variable.
  ;; (lsp-metals-server-args '(;; Metals claims to support range formatting by default but it supports range
  ;;                           ;; formatting of multiline strings only. You might want to disable it so that
  ;;                           ;; emacs can use indentation provided by scala-mode.
  ;;                           "-J-Dmetals.allow-multiline-string-formatting=off"
  ;;                           ;; Enable unicode icons. But be warned that emacs might not render unicode
  ;;                           ;; correctly in all cases.
  ;;                           ;;"-J-Dmetals.icons=unicode"
  ;;                           ))
  ;; In case you want semantic highlighting. This also has to be enabled in lsp-mode using
  ;; `lsp-semantic-tokens-enable' variable. Also you might want to disable highlighting of modifiers
  ;; setting `lsp-semantic-tokens-apply-modifiers' to `nil' because metals sends `abstract' modifier
  ;; which is mapped to `keyword' face.
  (lsp-metals-enable-semantic-highlighting t)
  (lsp-metals-start-mcp-server t)
  :config
  (defcustom lsp-metals-start-mcp-server nil
    "Start Metals MCP server."
    :type 'boolean
    :group 'lsp-metals)
  (lsp-register-custom-settings '(("metals.startMcpServer" lsp-metals-start-mcp-server t))))

;;;; Metals MCP, and the preset that uses it

(defun lt/scala-metals-connect ()
  "Connect to the current project's Metals MCP server.
Reads the server URL from `.metals/mcp.json' in the project root,
registers it in `mcp-hub-servers' as \"<project>-metals\", and starts
the connection.  When called from a gptel buffer, also activates the
MCP tools in that buffer."
  (interactive)
  (require 'json)
  (require 'mcp-hub)
  (let* ((pr (project-current t))
         (root (project-root pr))
         (config-file (expand-file-name ".metals/mcp.json" root))
         (server-name (format "%s-metals"
                              (file-name-nondirectory
                               (directory-file-name root)))))
    (unless (file-exists-p config-file)
      (user-error "No .metals/mcp.json in %s" root))
    (let* ((data (with-temp-buffer
                   (insert-file-contents config-file)
                   (let ((json-object-type 'alist)
                         (json-key-type 'string))
                     (json-read))))
           (servers (cdr (assoc "servers" data)))
           (url (cdr (assoc "url" (cdar servers)))))
      (unless url
        (user-error "No server URL in %s" config-file))
      ;; Register/refresh server with current port
      (setf (alist-get server-name mcp-hub-servers nil nil #'equal)
            (list :url url))
      ;; Start server + activate tools
      (if (bound-and-true-p gptel-mode)
          (progn
            (gptel-mcp-connect (list server-name) t) ; sync start
            (message "Metals MCP connected, tools activated in this buffer"))
        ;; Non-gptel buffer: start server, tools activate later
        (mcp-hub--start-server (cons server-name (list :url url)) nil t)
        (message "Metals MCP server started. Run gptel-mcp-connect in a gptel buffer to activate tools")))))

(defun lt/scala--metals-connect-safe ()
  "Connect to Metals MCP for use in a preset `:post' hook.
Swallows the `user-error' raised when `.metals/mcp.json' is absent, so
applying the preset is not aborted."
  (condition-case nil
      (lt/scala-metals-connect)
    (user-error nil)))

(defvar lt/scala-dev-system-prompt
  "You are a Scala development assistant. You work within a Scala/sbt project and produce high-quality, idiomatic Scala code. You prefer a purely functional programming style, favoring immutability, pure functions, and effect types where appropriate.

* sbt Best Practices

Use `sbt --client` for all sbt commands. This preserves Zinc incremental compilation cache across calls (batch-mode `sbt <command>` starts a fresh JVM each time, paying ~10-30s startup per call).

- `sbt --client compile`
- `sbt --client \"testOnly com.example.MySpec\"`
- `sbt --client scalafmtAll`
- `sbt --client reload` (after `build.sbt` changes)

Never run `sbt clean` unless explicitly asked. After changing `build.sbt`, run `sbt --client reload` before compiling.

* Scala 3

Default to Scala 3 idioms when the project uses Scala 3: `given` / `using`, `extension`, `enum`, opaque types, `@main`. Check the project's Scala version before deciding. Follow Scala 2 conventions if the project uses Scala 2.

* Code Style

** No fully qualified class names in code body

Never write fully qualified class names inline in code (e.g. `scala.util.Try`, `java.time.Instant`). Always add an `import` statement at the top of the file and use the simple name. If two imports collide, use an alias import (`as` syntax).

** Prefer recursion over loops

Prefer tail recursion via `@tailrec` over imperative loops (`while`, `for` with `var`). Recursive solutions are clearer, avoid mutable state, and integrate naturally with immutable data.

** Imperative code as last resort

Imperative code (`var`s, `while` loops) can be justified only when these are all true:
- It is local to a single function and has no detectable effect outside it.
- It is a last resort: performance is critical and a recursive/functional approach is measurably worse, or the function wraps an imperative API that cannot be abstracted away.

Otherwise, prefer immutable values and pure functions.

* Effect Systems

Determine the project's effect system (`cats-effect`, `zio`, `akka`) from `build.sbt` dependencies. Do not mix effect systems. Follow existing patterns — check how other files in the project handle effects.

* Code Quality

After edits: format (`format-file` MCP or `sbt --client scalafmtAll`), compile (`compile-file` MCP or `sbt --client compile`), test (`test` MCP or `sbt --client test`)."
  "System prompt for the `scala-dev' gptel preset.")

(with-eval-after-load 'gptel
  (require 'gptel-integrations)
  (gptel-make-preset 'scala-dev
    :description "Scala development with sbt/Metals."
    :post #'lt/scala--metals-connect-safe
    :tools '("Read" "Edit" "Insert" "Glob" "Grep" "Bash" "Eval"
             "WebSearch" "WebFetch" "TodoWrite" "Agent" "AskUserQuestion")
    :system lt/scala-dev-system-prompt
    :use-tools t))

(with-eval-after-load 'project
  (which-key-add-key-based-replacements "C-x p M" "metals-mcp")
  (keymap-set project-prefix-map "M" #'lt/scala-metals-connect))

;;;;; sbt-helpers
(defvar lt/scala-sbt-compile-on-save nil
  "When non-nil, send Test/compile to sbt on every save.")

(defun lt/scala-sbt-toggle-compile-on-save ()
  "Toggle `lt/scala-sbt-compile-on-save' and report the new value."
  (interactive)
  (setq lt/scala-sbt-compile-on-save (not lt/scala-sbt-compile-on-save))
  (message "lt/scala-sbt-compile-on-save: %s" lt/scala-sbt-compile-on-save))

(defun lt/scala--sbt-compile-on-save ()
  "Run Test/compile in sbt if `lt/scala-sbt-compile-on-save' is non-nil."
  (when lt/scala-sbt-compile-on-save
    (defvar sbt:save-some-buffers)
    (let ((sbt:save-some-buffers nil))
      (sbt-command "Test/compile"))))

(defun lt/scala-sbt-scalafmt-only ()
  "Format the current file using scalafmt via sbt."
  (interactive)
  (save-buffer)
  (sbt-command (concat "scalafmtOnly " (buffer-file-name (buffer-base-buffer)))))

(add-hook 'scala-ts-mode-hook
  (lambda () (add-hook 'after-save-hook #'lt/scala--sbt-compile-on-save nil t)))

(with-eval-after-load 'scala-ts-mode
  (keymap-set scala-ts-mode-map "C-c C-v f" #'lt/scala-sbt-scalafmt-only))

(provide 'lt-lang-scala)
;;; lt-lang-scala.el ends here
