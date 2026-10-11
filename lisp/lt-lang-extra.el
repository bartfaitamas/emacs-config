;;; lt-lang-extra.el --- languages with little to configure -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

(use-package js
  :config
  (setq js-indent-level 2))

;;;;; Elm
(use-package elm-mode)

;;;;; Dart / Flutter
(use-package dart-mode
  :hook (dart-mode . lsp-deferred))

(use-package lsp-dart
  :after lsp-mode)

;;;;; Rust
(use-package rust-mode
  :hook (rust-mode . (lambda () (setq indent-tabs-mode nil))))

(provide 'lt-lang-extra)
;;; lt-lang-extra.el ends here
