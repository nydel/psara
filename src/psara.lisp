(in-package :cl-psara)

(ql:quickload '(:cl-markup
		:cl-ppcre
		:css-lite
		:hunchentoot
		:ironclad
		:local-time))

(defvar *master-acceptor* 
  (make-instance 'hunchentoot:easy-acceptor :port 9903))

(defun +init+ ()
  (hunchentoot:start *master-acceptor*))

(defmacro page (name uri type args &body body)
  `(hunchentoot:define-easy-handler (,name :uri ,uri) ,args
     (setf (hunchentoot:content-type*) ,type)
     (format nil "~a"
	     ,@body)))

(defun test-page ()
  (ps:page next "/next" "text/html" (name)
    (cl-markup:html
     (:head
      (:title "hello again, " name))
     (:body
      (:p
       (local-time:format-timestring
	nil
	(local-time:now)
	:format
	'("this page was created at "
	  (:hour 2 #\0) ":"
	  (:min 2 #\0) "::"
	  (:sec 2 #\0))))))))
