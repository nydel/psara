(in-package :cl-psara)

(defstruct comment
  entry-timestamp
  timestamp
  author
  content)

(defun &new-comment (&key entry-timestamp timestamp author content)
  (make-comment :entry-timestamp entry-timestamp
		:timestamp (if timestamp timestamp (get-universal-time))
		:author author
		:content content))

(defvar *comment-db* '())

(defvar *comment-db-path* (pathname "data/.comment.db"))

(defun write-comments ()
  (with-open-file (@db *comment-db-path*
		       :direction :output
		       :if-exists :rename
		       :if-does-not-exist :create)
    (when *comment-db*
      (format @db "~{~a~&~}"
	      (mapcar (lambda (y)
			(write-to-string y)) *comment-db*)))))

(defun add-comment (&key entry-timestamp timestamp author content)
  (push
   (&new-comment :entry-timestamp entry-timestamp
		 :timestamp timestamp
		 :author author
		 :content content)
   *comment-db*)
  (write-comments))

(defun &load-comments ()
  (with-open-file (@db *comment-db-path*
		       :direction :input
		       :if-does-not-exist :create)
    (loop for comment = (read @db nil 'eof)
	 until (equal comment 'eof)
	 collect comment)))

(defun load-comments ()
  (setf *comment-db* (&load-comments)))


(defun format-comment-for-display (comment)
  (format nil "~a"
	  (markup:markup
	   (:div :id (write-to-string (comment-timestamp comment)) :class "comment"
		 (:dl :class "psaraweblogcomment"
		      (:dl
		       (:dt (local-time:format-timestring
			     nil
			     (local-time:universal-to-timestamp
			      (comment-timestamp comment))
			     :format
			     '("["
			       (:year 4 #\0) "."
			       (:month 2 #\0) "."
			       (:day 2 #\0) "] ["
			       (:hour 2 #\0) ":"
			       (:min 2 #\0) ":"
			       (:sec 2 #\0) "]"))))
		      (:dt :class "commentauthor"
			   (markup:raw "&nbsp; by ")
			   (:a :href (concatenate 'string
						  "mailto:"
						  (comment-author comment)
						  ".at.psara.dot.ps")
			       (comment-author comment)))
		      (:dd :class "commentcontent" (markup:raw (sloppy-regex-replace (comment-content comment))))
		      (:hr :class "thinline"))))))

(defun comments-for-entry (entry-id)
  (remove-if-not #'(lambda (y)
		     (equal (comment-entry-timestamp y) entry-id))
		 *comment-db*))

(defun how-many-comments (entry-id)
  (length (comments-for-entry entry-id)))

(defun comments-for-entry-markup (entry-id)
  (mapcar #'(lambda (y)
	      (format-comment-for-display y))
	  (comments-for-entry entry-id)))

(defun init-comment-form-style ()
  (hunchentoot:define-easy-handler (commentformstyle :uri "/commentform.css") ()
    (setf (hunchentoot:content-type*) "text/css")
    (format nil "~a"
	    (css-lite:css (("textarea")
			   (:width "100%"
			    :height "40px"
			    :border "1px solid #000000"
			    :border-radius "10px 10px 10px 10px"))))))

(defun init-comment-form-go ()
  (hunchentoot:define-easy-handler (commentformgo :uri "/commentform.go") (entryid timestamp author content)
    (setf (hunchentoot:content-type*) "text/html")
    (format nil "~a"
	    (let ((uname (logged-in-p)))
	      (if uname
		  (add-comment :entry-timestamp (parse-integer entryid :junk-allowed t)
			       :timestamp (if timestamp (parse-integer timestamp :junk-allowed t) (get-universal-time))
			       :author uname
			       :content content))
	      (hunchentoot:redirect "/weblog")))))
    

(defun init-comment-form ()
  (hunchentoot:define-easy-handler (commentform :uri "/commentform") (id)
    (setf (hunchentoot:content-type*) "text/html")
;    (unless (logged-in-p)
;      (hunchentoot:redirect "/login"))
    (format nil "~a"
	    (markup:html
	     (:head
	      (:title "comment form [psara]")
	      (:link :rel "stylesheet" :type "text/css" :href "/commentform.css"))
	     (:body
	      (:p
	       (:form :action "/commentform.go"
		      :method "post"
		      :enctype "application/x-www-form-urlencoded"
		      :name "commentform"
		      (:p
		       (:p
			(:textarea :name "content"
				   :placeholder "reply with comment..."
				   :id "content" ""))
		       (:p
			(:input :type "hidden"
				:name "entryid"
				:value  id)
			(:input :type "submit"))))))))))

(defun init-comment-display ()
  (hunchentoot:define-easy-handler (commentdisplay :uri "/comments") (entryid)
    (setf (hunchentoot:content-type*) "text/html")
    (format nil "~a"
	    (markup:markup
	     (:div :id "commentContainer"
		   (comments-for-entry-markup (parse-integer entryid :junk-allowed t)))))))

(defun +init-comment+ ()
  (load-comments)
  (init-comment-form-style)
  (init-comment-form-go)
  (init-comment-form)
  (init-comment-display))
