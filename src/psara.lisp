(in-package :cl-psara)

(ql:quickload '(:cl-markup
		:cl-ppcre
		:css-lite
		:drakma
		:hunchentoot
		:ironclad
		:local-time))

(defvar *master-port* 9903)

(defvar *master-acceptor* 
  (make-instance 'hunchentoot:easy-acceptor :port *master-port*))

(defun +init+ ()
  (hunchentoot:start *master-acceptor*))

(defun +init-all+ ()
  (+init+)
  (+init-login+)
  (+init-weblog+)
  (+init-log-search+)
  (+init-comment+))

(defun +start+ ()
  (+init-all+))

(defun +stop+ ()
  (hunchentoot:stop *master-acceptor*))

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
