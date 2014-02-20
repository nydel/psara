;;; all of this is garbage so far
;;; it's kind of scratch paper



(in-package :cl-psara)


(defstruct widget
 name
 id
 uri
 content-type
 sessionp
 cookiep
 title
 favicon
 content)

(defun new-widget (&key name id uri content-type sessionp cookiep title favicon content)
  (make-widget :name name
	       :id (if id id (concatenate 'string "pswidget-" (write-to-string (get-universal-time))))
	       :uri (if uri uri (concatenate 'string "pswidget-" (write-to-string (get-universal-time))))
	       :content-type (if content-type content-type "text/plain")
	       :sessionp sessionp
	       :cookiep cookiep
	       :title (if title title (concatenate 'string "pswidget-" (write-to-string (get-universal-time))))
	       :favicon favicon
	       :content content))
 



;; (defmacro new-psara-page (name content-type uri sessionp cookiep &body body)
