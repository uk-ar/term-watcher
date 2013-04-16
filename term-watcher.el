
(defun flycheck-ruby-Test::Unit-parser (output checker buffer)
  (flycheck-parse-output-with-patterns
   (replace-regexp-in-string ".*/test/unit/.*\n" "" output) checker buffer))

(put 'ruby-Test::Unit :flycheck-error-patterns
     '(("^\\(?4:\\(Error\\|FAIL\\)\\(.*\\(.\\|\n\\)+?\\)\n\\s *\\(?1:.*\\):\\(?2:[0-9]+\\):\\(.*\\(.\\|\n\\)+?\\)\\)\n\n" error)))

(put 'ruby-Test::Unit :flycheck-error-parser
     'flycheck-ruby-Test::Unit-parser)

(defun flycheck-add-overlays-from-compilation-buffer (&optional checker)
  "Check syntax in the current buffer."
  (interactive)
  ;; (print compilation-locs)
  (let ((output (buffer-string))
        (buffers
         (delq
          nil
          (delete-dups
           (mapcar
            (lambda (file-name) (get-file-buffer file-name))
            (loop for k being the hash-keys in compilation-locs
                  collect (car k)))))))
    (print buffers)
    (mapcar
     (lambda (buffer)
       (with-current-buffer buffer
         (flycheck-clean-deferred-check)
         (when (not (flycheck-running-p))
           (flycheck-clear-errors)
           (flycheck-mark-all-overlays-for-deletion)
           (flycheck-finish-syntax-check
            (or checker (flycheck-get-checker-for-buffer))
            0 nil
            output))))
     buffers)))

(defun flycheck-compilation-finish (buffer string)
  (flycheck-add-overlays-from-compilation-buffer))

(defvar term-watcher-timer nil)
(defvar term-watcher-delay-timer nil)

(defun term-watcher-refresh ()
  (message "fuga done!")
  (flycheck-add-overlays-from-compilation-buffer 'ruby-Test::Unit)
  (setq term-watcher-delay-timer nil))

(defun term-watcher-check-modification (buffer)
  (with-current-buffer buffer
    (when (buffer-modified-p)
      (set-buffer-modified-p nil)
      (message "mod3")
      (if term-watcher-delay-timer (term-watcher-delay-timer))
      (setq term-watcher-delay-timer (run-at-time 3 nil 'term-watcher-refresh))
      )))

(defun term-watcher-teardown ()
  (if term-watcher-timer (cancel-timer term-watcher-timer))
  (setq term-watcher-timer nil)
  (if term-watcher-delay-timer (cancel-timer term-watcher-delay-timer))
  (setq term-watcher-delay-timer nil)
  )
;; (term-watcher-teardown)

(defun term-watcher (&optional new-buffer-name)
  "Start a terminal-emulator in a new buffer."
  (interactive)
  ;; program
  ;; path
  ;; (interactive (list (or explicit-shell-file-name
  ;;                        (getenv "ESHELL")
  ;;                        (getenv "SHELL")
  ;;                        "/bin/sh")))
  (ansi-term explicit-shell-file-name "term-watcher")
  (font-lock-mode -1)
  (compilation-minor-mode t)
  ;; (compilation-shell-minor-mode t)
  (term-line-mode)
  (term-send-raw-string "bundle exec guard -d -c\n")
  (term-watcher-teardown)
  (setq term-watcher-timer
        (run-at-time 2 2 'term-watcher-check-modification (current-buffer)))
  (add-hook 'kill-buffer-hook 'term-watcher-teardown nil t)
  )
;; (kill-buffer-hook cancel-timer)

