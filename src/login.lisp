(in-package :cl-psara)

(defun md5-hash (string)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :md5
    (ironclad:ascii-string-to-byte-array string))))

(defstruct user
  id
  username
  realname
  email
  password-hash)

(defun &new-user (&key id username realname email password)
  (make-user :id (if id id (get-universal-time))
	     :username username
	     :realname realname
	     :email email
	     :password-hash (md5-hash password)))

(defvar *users-db* '())

(defvar *users-db-path* (pathname "data/.login.db"))

(defun write-users ()
  (with-open-file (@db *users-db-path*
		       :direction :output
		       :if-exists :rename
		       :if-does-not-exist :create)
    (when *users-db*
      (format @db "~{~a~&~}"
	      (mapcar (lambda (y)
			(write-to-string y)) *users-db*)))))

(defun add-user (&key id username realname email password)
  (push
   (&new-user :id id
	      :username username
	      :realname realname
	      :email email
	      :password password)
   *users-db*)
  (write-users))

(defun &load-users ()
  (with-open-file (@db *users-db-path*
		       :direction :input
		       :if-does-not-exist :create)
    (loop for entry = (read @db nil 'eof)
       until (equal entry 'eof)
       collect entry)))

(defun load-users ()
  (setf *users-db* (&load-users)))

(defun valid-p (uname pass)
  (let ((entry
	 (remove-if-not
	  (lambda (y)
	    (equal (user-username y) uname))
	  *users-db*)))
    (when entry
      (when (string-equal (user-password-hash (car entry)) (md5-hash pass))
	(return-from valid-p t)))))

(defun logged-in-p ()
  (let ((session (hunchentoot:start-session))
	(cookie (hunchentoot:cookie-out "hunchentoot-session")))
    (format t "~a" cookie)
    (hunchentoot:session-value 'uname session)))

(defun init-login-go ()
  (hunchentoot:define-easy-handler (logingo :uri "/login.go") (uname passwd)
    (setf (hunchentoot:content-type*) "text/plain")
    (format nil "~a"
	    (if (valid-p uname passwd)
		(let ((session (hunchentoot:start-session))
		      (cookie (hunchentoot:cookie-out "hunchentoot-session")))
		  (setf (hunchentoot:session-max-time session)
			(+ (get-universal-time) 172800))
		  (setf (hunchentoot:session-value 'uname session) uname)
		  (setf (hunchentoot:session-value 'passwd session)
			(md5-hash passwd))
		  (format nil "cookie: ~a" cookie)
		  (when cookie
		    (setf (hunchentoot:cookie-expires
			   (hunchentoot:cookie-out "hunchentoot-session"))
			  (+ (get-universal-time) 172800)))
		  (hunchentoot:redirect "/"))
		(markup:markup
		 (:p "there was a problem logging in!"))))))


(defun init-login-form ()
  (page login "/login" "text/html" ()
    (cl-markup:html
     (:head
      (:title "login"))
     (:body
      (:p "the result of (logged-in-p) is currently:" (logged-in-p))
      (:form :action "/login.go"
	     :method "post"
	     :enctype "application/x-www-form-urlencoded"
	     :name "loginform"
	     (:p
	      (:input :type "text"
		      :id "uname"
		      :name "uname"
		      :placeholder "user & pass...")
	      (:input :type "password"
		      :id "passwd"
		      :name "passwd")
	      (:input :type "submit")))))))

(defun +init-login+ ()
  (load-users)
  (init-login-form)
  (init-login-go))


;;; do registration in another file

(defun init-registration-form ()
  (page register "/register" "text/html" ()
    (cl-markup:html
     (:head
      (:title "register"))
     (:body
      (:p
       (:form :action "/register.go"
	      :method "post"
	      :enctype "application/x-www-form-urlencoded"
	      :name "registerform"
	      (:p
	       (:input :type "text"
		       :id "uname"
		       :name "uname"
		       :placeholder "user & pass...")
	       (:input :type "password"
		       :id "passwd"
		       :name "passwd")
	       (:input :type "submit"))))))))
