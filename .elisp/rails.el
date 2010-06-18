;;; rails.el --- minor mode for editing RubyOnRails code

;; Copyright (C) 2006 Dmitry Galinsky <dima dot exe at gmail dot com>

;; Authors: Dmitry Galinsky <dima dot exe at gmail dot com>,
;;          Rezikov Peter <crazypit13 (at) gmail.com>
;;          Phil Hagelberg <technomancy@gmail.com>

;; Keywords: ruby rails languages oop
;; $URL: svn://rubyforge.org/var/svn/emacs-rails/branches/rinari-merge/rails.el $
;; $Id: rails.el 215 2007-10-29 23:13:21Z technomancy $

;;; License

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

;;; Code:

(unless (<= 22 emacs-major-version)
  (error
   (format "emacs-rails requires Emacs 22, and you are using Emacs %s.%s"
           emacs-major-version
           emacs-minor-version)))

(eval-when-compile
  (require 'speedbar)
  (require 'inf-ruby)
  (require 'ruby-mode)
  (require 'ruby-electric))

(require 'sql)
(require 'ansi-color)
(require 'etags)
(require 'find-recursive)

(require 'inflections)

(require 'rails-project)
(require 'rails-core)
(require 'rails-ruby)
(require 'rails-lib)

(require 'rails-cmd-proxy)
(require 'rails-navigation)
(require 'rails-find)
(require 'rails-scripts)
(require 'rails-rake)
(require 'rails-test)
(require 'rails-log)
(require 'rails-ui)
(require 'rails-model-layout)
(require 'rails-controller-layout)


;;;;;;;;;; Variable definition ;;;;;;;;;;

(defgroup rails nil
  "Edit Rails project with Emacs."
  :group 'programming
  :prefix "rails-")

(defcustom rails-use-alternative-browse-url nil
  "Indicates an alternative way of loading URLs on Windows.
Try using the normal method before. If URLs invoked by the
program don't end up in the right place, set this option to
true."
  :group 'rails
  :type 'boolean)

(defcustom rails-tags-command "ctags -e -a --Ruby-kinds=-f -o %s -R %s"
  "Command used to generate TAGS in Rails root"
  :group 'rails
  :type 'string)

(defcustom rails-always-use-text-menus nil
  "Force the use of text menus by default."
  :group 'rails
  :type 'boolean)

(defcustom rails-ask-when-reload-tags nil
  "Indicates whether the user should confirm reload a TAGS table or not."
  :group 'rails
  :type 'boolean)

(defcustom rails-chm-file nil
  "Path to CHM documentation file on Windows, or nil."
  :group 'rails
  :type 'string)

(defcustom rails-ruby-command "ruby"
  "Ruby preferred command line invocation."
  :group 'rails
  :type 'string)

(defcustom rails-layout-template
  "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.0 Strict//EN\"
          \"http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd\">
<html xmlns=\"http://www.w3.org/1999/xhtml\"
      xml:lang=\"en\" lang=\"en\">
  <head>
    <title></title>
    <meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />
    <%= stylesheet_link_tag \"default\" %>
  </head>

  <body>
    <%= yield %>
  </body>
</html>"
  "Default html template for new rails layout"
  :group 'rails
  :type 'string)

(defvar rails-version "0.6.0.0")
(defvar rails-templates-list '("erb" "rhtml" "rxml" "rjs" "haml" "liquid" "mab"))
(defvar rails-use-another-define-key nil)
(defvar rails-primary-switch-func nil)
(defvar rails-secondary-switch-func nil)

(defvar rails-directory<-->types
  '((:controller       "app/controllers/")
    (:layout           "app/layouts/")
    (:view             "app/views/")
    (:observer         "app/models/" (lambda (file) (rails-core:observer-p file)))
    (:mailer           "app/models/" (lambda (file) (rails-core:mailer-p file)))
    (:model            "app/models/" (lambda (file) (and (not (rails-core:mailer-p file))
                                                         (not (rails-core:observer-p file)))))
    (:helper           "app/helpers/")
    (:plugin           "vendor/plugins/")
    (:unit-test        "test/unit/")
    (:functional-test  "test/functional/")
    (:fixture          "test/fixtures/")
    (:migration        "db/migrate"))
  "Rails file types -- rails directories map")

(defvar rails-enviroments '("development" "production" "test"))
(defvar rails-default-environment (first rails-enviroments))

(defvar rails-adapters-alist
  '(("mysql"      . sql-mysql)
    ("postgresql" . sql-postgres)
    ("sqlite3"    . sql-sqlite))
  "Sets emacs sql function for rails adapter names.")

(defvar rails-tags-dirs '("app" "lib" "test" "db")
  "List of directories from RAILS_ROOT where ctags works.")

(defun rails-use-text-menu ()
  "If t use text menu, popup menu otherwise"
  (or (null window-system) rails-always-use-text-menus))

;;;;;;;; hack ;;;;
(defun rails-svn-status-into-root ()
  (interactive)
  (rails-project:with-root (root)
                           (svn-status root)))

(defun rails-create-tags()
  "Create tags file"
  (interactive)
  (rails-project:in-root
   (message "Creating TAGS, please wait...")
   (let ((tags-file-name (rails-core:file "TAGS")))
     (shell-command
      (format rails-tags-command tags-file-name
        (strings-join " " (mapcar #'rails-core:file rails-tags-dirs))))
     (flet ((yes-or-no-p (p) (if rails-ask-when-reload-tags
         (y-or-n-p p)
             t)))
       (visit-tags-table tags-file-name)))))

(defun rails-apply-for-buffer-type ()
 (let* ((type (rails-core:buffer-type))
        (name (substring (symbol-name type) 1))
        (minor-mode-name (format "rails-%s-minor-mode" name))
        (minor-mode-abbrev (concat minor-mode-name "-abbrev-table")))
   (when (require (intern minor-mode-name) nil t) ;; load new style minor mode rails-*-minor-mode
     (when (fboundp (intern minor-mode-name))
       (apply (intern minor-mode-name) (list t))
       (when (boundp (intern minor-mode-abbrev))
         (merge-abbrev-tables
          (symbol-value (intern minor-mode-abbrev))
          local-abbrev-table))))))

;;;;;;;;;; Database integration ;;;;;;;;;;

(defstruct rails-db-conf adapter host database username password)

(defun rails-db-parameters (env)
  "Return database parameters for enviroment ENV"
  (with-temp-buffer
    (shell-command
     (format "ruby -r yaml -r erb -e 'YAML.load(ERB.new(ARGF.read).result)[\"%s\"].to_yaml.display' %s"
             env
             (rails-core:file "config/database.yml"))
     (current-buffer))
    (let ((answer
           (make-rails-db-conf
            :adapter  (yml-value "adapter")
            :host     (yml-value "host")
            :database (yml-value "database")
            :username (yml-value "username")
            :password (yml-value "password"))))
      answer)))

(defun rails-database-emacs-func (adapter)
  "Return the Emacs function for ADAPTER that, when run, will
+invoke the appropriate database server console."
  (cdr (assoc adapter rails-adapters-alist)))

(defun rails-read-enviroment-name (&optional default)
  "Read Rails enviroment with auto-completion."
  (completing-read "Environment name: " (list->alist rails-enviroments) nil nil default))

(defun* rails-run-sql (&optional env)
  "Run a SQL process for the current Rails project."
  (interactive (list (rails-read-enviroment-name "development")))
  (rails-project:with-root (root)
    (cd root)
    (if (bufferp (sql-find-sqli-buffer))
        (switch-to-buffer-other-window (sql-find-sqli-buffer))
      (let ((conf (rails-db-parameters env)))
        (let ((sql-database (rails-db-conf-database conf))
              (default-process-coding-system '(utf-8 . utf-8))
              (sql-server (rails-db-conf-host conf))
              (sql-user (rails-db-conf-username conf))
              (sql-password (rails-db-conf-password conf)))
          ;; Reload localy sql-get-login to avoid asking of confirmation of DB login parameters
          (flet ((sql-get-login (&rest pars) () t))
            (funcall (rails-database-emacs-func (rails-db-conf-adapter conf)))))))))

;;; Rails minor mode

(define-minor-mode rails-minor-mode
  "A minor mode for programming in Ruby on Rails"
  nil
  " RoR"
  rails-minor-mode-map

  (make-local-variable 'tags-file-name))

;;; hooks

(add-hook 'ruby-mode-hook
	  (lambda ()
	    (if (rails-project:root)
		(rails-minor-mode t))))

;; TODO: does this make sense in a hook? (do we care about speedbar?)
(add-hook 'speedbar-mode-hook
          (lambda()
            (speedbar-add-supported-extension "\\.rb")))

;; Run rails-minor-mode in dired

(add-hook 'dired-mode-hook
          (lambda ()
            (if (rails-project:root)
                (rails-minor-mode t))))

(autoload 'haml-mode "haml-mode" "" t)

(dolist (mode-cons '(("\\.rb$"       . ruby-mode)
                     ("\\.rake$"     . ruby-mode)
                     ("Rakefile$"    . ruby-mode)
                     ("\\.haml$"     . haml-mode)
                     ("\\.rjs$"      . ruby-mode)
                     ("\\.rxml$"     . ruby-mode)
		     ("\\.mab$"      . ruby-mode)
		     ("\\.html.erb$" . rhtml-mode)
                     ("\\.rhtml$"    . rhtml-mode)))
  (add-to-list ' auto-mode-alist mode-cons))

(modify-coding-system-alist 'file "\\.rb$"     'utf-8)
(modify-coding-system-alist 'file "\\.rake$"   'utf-8)
(modify-coding-system-alist 'file "Rakefile$" 'utf-8)
(modify-coding-system-alist 'file (rails-core:regex-for-match-view) 'utf-8)

(provide 'rails)
