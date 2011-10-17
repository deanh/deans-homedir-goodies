(add-to-list 'load-path "~/.elisp")
;; Remove splash screen
(setq inhibit-splash-screen t)

;; Don't open new frames all the time
(setq ns-pop-up-frames 'nil)

;; Don't litter auto-save turds all over the file system
(setq backup-directory-alist
     `((".*" . ,temporary-file-directory)))
(setq auto-save-file-name-transforms
     `((".*" ,temporary-file-directory t)))

;; Allow mouse wheel scrolling
(mouse-wheel-mode t) 

;; Prevent Emacs from making backup files
(setq make-backup-files nil) 

;; Indent but without tabs
(setq standard-indent 2)
(setq-default indent-tabs-mode nil) 

;; Show line-number in the mode line
(line-number-mode 1)

;; Show column-number in the mode line
(column-number-mode 1)

;; In every buffer, the line which contains the cursor will be fully
;; highlighted

(global-hl-line-mode 1)

;; Ido mode
(require 'ido)
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)

;; Color themes
(require 'color-theme)
(color-theme-high-contrast)

;; We sure want to use bash.
(setq explicit-shell-file-name "/bin/bash")

;; If you can't stop ANSI escape sequences, use them.
(autoload 'ansi-color-for-comint-mode-on "ansi-color" nil t)
(add-hook 'shell-mode-hook 'ansi-color-for-comint-mode-on)

;; I'm using Obj-C more often than C
(add-to-list 'auto-mode-alist '("\\.h$" . objc-mode))

;; Based on http://infolab.stanford.edu/~manku/dotemacs.html
(autoload 'ruby-mode "ruby-mode"
    "Mode for editing ruby source files")
(add-to-list 'auto-mode-alist '("\\.rb$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rxml$" . ruby-mode))
(add-to-list 'auto-mode-alist '("\\.rhtml$" . ruby-mode))
(add-to-list 'interpreter-mode-alist '("ruby" . ruby-mode))
(autoload 'run-ruby "inf-ruby"
    "Run an inferior Ruby process")
(autoload 'inf-ruby-keys "inf-ruby"
    "Set local key defs for inf-ruby in ruby-mode")
(add-hook 'ruby-mode-hook
    '(lambda ()
        (inf-ruby-keys)))
;; If you have Emacs 19.2x or older, use rubydb2x

;;(require 'snippet)
;;(require 'rails)
;;(require 'dired-view)

(autoload 'rubydb "rubydb3x" "Ruby debugger" t)
;; uncomment the next line if you want syntax highlighting
(add-hook 'ruby-mode-hook 'turn-on-font-lock)

;; javascript mode
(add-to-list 'auto-mode-alist '("\\.js\\'" . javascript-mode))
(autoload 'javascript-mode "javascript" nil t)

;; mutt mode
(load "~/.elisp/mutt.el") 
(server-start)
(add-to-list 'auto-mode-alist '("/mutt" . mutt-mode))

(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)
(global-set-key [M-return] 'next-buffer)
(global-set-key [C-return] 'previous-buffer)
(defalias 'qrr 'query-replace-regexp)

(setq-default ispell-program-name "aspell")
(ns-toggle-fullscreen)