;;; counsel-tide-nav.el --- Ivy interface to tide-nav -*- lexical-binding: t -*-

(require 'ivy)
(require 'tide)

(defun counsel-tide-nav--make-data (name value)
  (let ((my-hash (make-hash-table :test 'equal)))
    (puthash "name" name my-hash)
    (puthash "value" value my-hash)
    my-hash))

(defun counsel-tide-nav--get-name (data)
  (gethash "name" data))

(defun counsel-tide-nav--get-value (data)
  (gethash "value" data))

(defun counsel-tide-nav--fn (str)
  ;; must set the buffer context to where we run ivy
  ;; very important otherwise tide functions will run on minibuffer context
  (with-ivy-window 
    (let ((response (tide-command:navto str)))
      (tide-on-response-success response
          (when-let ((navto-items (plist-get response :body))
                     (cutoff (length (tide-project-root))))
            (setq navto-items (funcall tide-navto-item-filter navto-items))
            (seq-map (lambda (navto-item)
                       (counsel-tide-nav--make-data
                        (format "%s: %s"
                                (substring (plist-get navto-item :file) cutoff)
                                (plist-get navto-item :name))
                        navto-item))
                     navto-items))))))

;;;###autoload
(defun counsel-tide-nav (&optional initial-input)
  (interactive)
  (ivy-read "Tide project symbol: "
            #'counsel-tide-nav--fn
            :initial-input initial-input
            :dynamic-collection t
            :history 'counsel-tide-nav-history
            :require-match t
            :action (lambda (x) (tide-jump-to-filespan (counsel-tide-nav--get-value x)))
            :caller 'counsel-tide-nav))

(ivy-configure 'counsel-tide-nav
  :display-transformer-fn
  #'counsel-tide-nav--get-name)

(provide 'counsel-tide-nav)
