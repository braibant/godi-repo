(global-font-lock-mode 1)
(autoload 'caml-mode "caml" "Major mode for editing OCaml code." t)
(autoload 'run-caml "inf-caml" "Run an inferior OCaml process." t)
(autoload 'camldebug "camldebug" "Run ocamldebug on program." t)
(add-to-list 'interpreter-mode-alist '("ocamlrun" . caml-mode))
(add-to-list 'interpreter-mode-alist '("ocaml" . caml-mode))
(if window-system (require 'caml-font))

;; if you prefer caml-mode you can put something like
;; this in your ~/.emacs file
;;(setq auto-mode-alist (remove (rassoc 'verilog-mode auto-mode-alist) auto-mode-alist))
;; (defun replace-alist-mode (alist oldmode newmode)
;;   (dolist (aitem alist)
;;     (if (eq (cdr aitem) oldmode)
;; 	(setcdr aitem newmode))))
;; (replace-alist-mode auto-mode-alist 'tuareg-mode 'caml-mode)

(autoload 'tuareg-mode "tuareg" "Major mode for editing Caml code" t)
(add-to-list 'auto-mode-alist '("\\.ml[iylp]?\\'" . tuareg-mode))

(setq completion-ignored-extensions
      (append '(".cmo" ".cmx" ".cma" ".cmxa" ".cmi" ".annot")
              completion-ignored-extensions))

;; disable annoying request
(add-hook 'caml-mode-hook
          (function (lambda ()
                      (setq abbrevs-changed nil))))

;;; Follow Cygwin symlinks.
;;; Handles old-style (text file) symlinks and new-style (.lnk file) symlinks.
;;; (Non-Cygwin-symlink .lnk files, such as desktop shortcuts, are still loaded as such.)
(add-hook 'find-file-hooks
          (function (lambda ()
                      (save-excursion
                        (goto-char 0)
                        (if (looking-at
                             "L\x000\x000\x000\x001\x014\x002\x000\x000\x000\x000\x000\x0C0\x000\x000\x000\x000\x000\x000\x046\x00C")
                            (progn
                              (re-search-forward
                               "\x000\\([-A-Za-z0-9_\\.\\\\\\$%@(){}~!#^'`][-A-Za-z0-9_\\.\\\\\\$%@(){}~!#^'`]+\\)")
                              (find-alternate-file (match-string 1)))
                          (if (looking-at "!<symlink>")
                              (progn
                                (re-search-forward "!<symlink>\\(.*\\)\0")
                                (find-alternate-file (match-string 1))))
                          )))))


;;; Use Unix-style line endings.
(setq-default buffer-file-coding-system 'undecided-unix)

(setenv "SHELL" "zsh")
(setq explicit-shell-file-name "zsh")


;; This removes unsightly ^M characters that would otherwise
;; appear in the output of java applications.
(add-hook 'comint-output-filter-functions 'comint-strip-ctrl-m)

;; (defun w32-maximize-frame ()
;;   "Maximize the current frame"
;;   (interactive)
;;   (w32-send-sys-command 61488))
(add-hook 'window-setup-hook
          (function (lambda ()
                      (interactive)
                      (w32-send-sys-command 61488))) )

(require 'cygwin-mount)
(cygwin-mount-activate)

(require 'color-theme)
