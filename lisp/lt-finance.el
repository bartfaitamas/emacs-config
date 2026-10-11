;;; lt-finance.el --- plain text accounting -*- lexical-binding: t; -*-
;;; Commentary:
;;; Code:

;;;; Finance
(use-package hledger-mode)
(use-package ledger-mode
  :mode ("\\.journal\\'" . ledger-mode)
  :custom
  (ledger-binary-path "hledger")
  (ledger-mode-should-check-version nil)
  (ledger-report-links-in-register nil)
  (ledger-report-auto-width nil)
  (ledger-reconcile-default-commodity "HUF")
  (ledger-report-use-native-highlighting nil)
  (ledger-report-native-highlighting-arguments '("--color=always"))

  (ledger-report-use-header-line t)
  (ledger-report-auto-refresh-sticky-cursor t)
  (ledger-report-use-strict t)
  (ledger-highlight-xact-under-point nil)
  (ledger-copy-transaction-insert-blank-line-after t))

(provide 'lt-finance)
;;; lt-finance.el ends here
