;;; lt-lang-android.el --- android -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(require 'inheritenv)
(require 'treesit)
(eval-when-compile (require 'compile))
(declare-function lsp-register-client "lsp-mode")
(declare-function make-lsp-client "lsp-mode")
(declare-function lsp-stdio-connection "lsp-mode")

;;;; Kotlin

;; kotlin-ts-mode targets the unreleased grammar main branch; nixpkgs ships
;; 0.3.8.  Its broken queries abort all later fontification, so swap them.
(defun lt-android--kotlin-font-lock ()
  (let ((rules
         (append
          ;; Only on grammars without the newer node names.
          (unless (ignore-errors
                    (treesit-query-compile 'kotlin '((interpolation_identifier_start)) t))
            (treesit-font-lock-rules
             :language 'kotlin
             :feature 'string
             '((character_literal) @font-lock-string-face
               (string_literal) @kotlin-ts-mode--fontify-string)

             ;; 0.3.8: template delimiters are anonymous, not interpolation_* nodes.
             :language 'kotlin
             :feature 'string
             :override t
             '((string_literal ["$" "${" "}"] @font-lock-builtin-face))

             ;; 0.3.8: "null" is anonymous, not null_literal.
             :language 'kotlin
             :feature 'constant
             :override t
             '(["null" (boolean_literal)] @font-lock-constant-face
               ((simple_identifier) @font-lock-constant-face
                (:match "^[A-Z_][A-Z_0-9]*$" @font-lock-constant-face)))))
          ;; Use the Emacs 29+ *-use/*-call faces, so uses differ from definitions.
          (treesit-font-lock-rules
           :language 'kotlin
           :feature 'function
           '((call_expression (navigation_expression (navigation_suffix (simple_identifier) @font-lock-function-call-face)))
             (call_expression (simple_identifier) @font-lock-function-call-face)
             (infix_expression _ (simple_identifier) @font-lock-function-call-face _))

           :language 'kotlin
           :feature 'property
           '((navigation_expression (navigation_suffix (simple_identifier) @font-lock-property-use-face)))

           :language 'kotlin
           :feature 'variable
           '((import_header (identifier (simple_identifier) @font-lock-constant-face
                                        (:match "^[A-Z_][A-Z_0-9]*$" @font-lock-constant-face)))
             (import_header (identifier (simple_identifier) @font-lock-type-face
                                        (:match "^[A-Z]" @font-lock-type-face)))
             (simple_identifier) @font-lock-variable-use-face
             (interpolated_identifier) @font-lock-variable-use-face)

           ;; New feature: kotlin-ts-mode does not fontify annotations.
           :language 'kotlin
           :feature 'annotation
           :override t
           '((annotation "@" @font-lock-preprocessor-face)
             (annotation (user_type (type_identifier) @font-lock-preprocessor-face))
             (annotation (constructor_invocation (user_type (type_identifier) @font-lock-preprocessor-face)))
             (file_annotation "@" @font-lock-preprocessor-face)
             (file_annotation (constructor_invocation (user_type (type_identifier) @font-lock-preprocessor-face))))))))
    ;; Replace same-feature settings in place (order matters), append new ones.
    (setq-local treesit-font-lock-settings
                (append (mapcan (lambda (s)
                                  (or (seq-filter (lambda (r) (eq (nth 2 r) (nth 2 s))) rules)
                                      (list s)))
                                treesit-font-lock-settings)
                        (seq-filter (lambda (r) (eq (nth 2 r) 'annotation)) rules)))
    ;; Copy: the mode sets a quoted literal shared by all buffers.
    (let ((levels (copy-tree treesit-font-lock-feature-list)))
      (setf (nth 2 levels) (append (nth 2 levels) '(annotation)))
      (setq-local treesit-font-lock-feature-list levels))
    (treesit-font-lock-recompute-features)))

(use-package kotlin-ts-mode
  :mode ("\\.kts?\\'" . kotlin-ts-mode)
  :init
  (add-to-list 'major-mode-remap-alist '(kotlin-mode . kotlin-ts-mode))
  :hook
  (kotlin-ts-mode . lt-android--kotlin-font-lock)
  (kotlin-ts-mode . lsp-deferred))

(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection '("kotlin-lsp" "--stdio"))
    :major-modes '(kotlin-mode kotlin-ts-mode)
    :priority 0
    :server-id 'kotlin-lsp)))

;;;; Java

(add-to-list 'major-mode-remap-alist '(java-mode . java-ts-mode))

;;;; Gradle

(use-package groovy-mode
  :mode "\\.gradle\\'")

(with-eval-after-load 'compile
  (add-to-list 'compilation-error-regexp-alist 'kotlin)
  (add-to-list 'compilation-error-regexp-alist-alist
               '(kotlin "^\\(?:e\\|\\(w\\)\\): file://\\([^:\n]+\\):\\([0-9]+\\):\\([0-9]+\\) "
                        2 3 4 (1))))

(defvar lt-android-gradle-tasks
  '("assembleDebug" "installDebug" "test" "lint" "connectedAndroidTest" "clean"))

(defvar lt-android--gradle-history nil)

(defun lt-android--gradle-root ()
  (or (locate-dominating-file default-directory "gradlew")
      (user-error "No gradlew above %s" default-directory)))

(defun lt-android-gradle (task)
  (interactive
   (list (completing-read "Gradle task: " lt-android-gradle-tasks
                          nil nil nil 'lt-android--gradle-history)))
  (let ((default-directory (lt-android--gradle-root)))
    (inheritenv
     (compile (concat "./gradlew --console=plain " task)))))

;;;; adb

(defun lt-android-logcat (&optional package)
  (interactive (list (when current-prefix-arg (read-string "Package: "))))
  (let* ((adb (or (executable-find "adb") (user-error "No adb on exec-path")))
         (pid (when package
                (string-trim
                 (shell-command-to-string (concat "adb shell pidof -s " package)))))
         (args (append '("logcat" "-v" "color")
                       (when pid (list (concat "--pid=" pid))))))
    (when (and pid (string-empty-p pid))
      (user-error "%s is not running" package))
    (pop-to-buffer
     (inheritenv
      (apply #'make-comint (if package (concat "logcat-" package) "logcat")
             adb nil args)))))

(defvar-keymap lt-android-map
  "g" #'lt-android-gradle
  "l" #'lt-android-logcat)

(with-eval-after-load 'project
  (which-key-add-key-based-replacements "C-x p A" "android")
  (keymap-set project-prefix-map "A" lt-android-map))

(provide 'lt-lang-android)
;;; lt-lang-android.el ends here
