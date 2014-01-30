(in-package :cl-psara)

(defstruct log-entry
  timestamp
  subject
  author
  content
  tags)

(defun &new-log-entry (&key timestamp subject author content tags)
  (make-log-entry :timestamp (if timestamp timestamp (get-universal-time))
		  :subject subject
		  :author author
		  :content content
		  :tags tags))

(defvar *log-entry-db* '())

(defvar *log-entry-db-path* (pathname ".weblog.db"))

(defun write-entries ()
  (with-open-file (@db *log-entry-db-path*
		       :direction :output
		       :if-exists :rename
		       :if-does-not-exist :create)
    (when *log-entry-db*
      (format @db "~{~a~&~}"
	      (mapcar (lambda (y)
			(write-to-string y)) *log-entry-db*)))))

(defun add-log-entry (&key timestamp subject author content tags)
  (push
   (&new-log-entry :timestamp timestamp
		   :subject subject
		   :author author
		   :content content
		   :tags tags)
   *log-entry-db*)
  (write-entries))

(defun &load-log-entries ()
  (with-open-file (@db *log-entry-db-path*
		       :direction :input
		       :if-does-not-exist :create)
    (loop for entry = (read @db nil 'eof)
	 until (equal entry 'eof)
	 collect entry)))

(defun load-log-entries ()
  (setf *log-entry-db* (&load-log-entries)))

(defun format-log-entry-for-display (entry)
  (format nil "~a"
	  (markup:markup
	   (:div :id (write-to-string (log-entry-timestamp entry)) :class "logentry"
		 (:dl :class "psaraweblog"
		      (:dl
		       (:dt (local-time:format-timestring
			     nil
			     (local-time:universal-to-timestamp
			      (log-entry-timestamp entry))
			     :format
			     '("["
			       (:year 4 #\0) "."
			       (:month 2 #\0) "."
			       (:day 2 #\0) "] ["
			       (:hour 2 #\0) ":"
			       (:min 2 #\0) ":"
			       (:sec 2 #\0) "]"))))
		      (:dt :class "logentrytitle"
			   (:a :href "#" (log-entry-subject entry))
			   " by " (:a :href "#" (log-entry-author entry)))
		      (:dd :class "logentrycontent" (log-entry-content entry))
		      (:dt :class "logentrytags" ;;list of items to strings that are links
			   (mapcar (lambda (y)
				     (markup:markup
				      (:a :class "logtag" :href "#" y)))
				   (log-entry-tags entry))))))))

(defun init-weblog-display ()
  (page weblog "/weblog" "text/html" ()
    (markup:html
     (:head
      (:title "psara home [psara/honeylog]")
      (:link :rel "stylesheet" :type "text/css" :href "/weblog.css"))
     (:body
      (:div :class "mainContainer"
	    (:div :class "topContainer"
		  (:img
		   :src "http://www.isismelting.com/psara001.png"
		   :id "psaralogo"))
	    (:div :class "topBar"
		  (:p :class "topBar"
		      "psara on github: "
		      (:a :href "#" "http://whatever.github.com/psara/etc")))
	    (:hr :class "thinline")
	    (mapcar (lambda (y)
		      (format-log-entry-for-display y))
		    *log-entry-db*))))))

(defun init-weblog-style ()
  (hunchentoot:define-easy-handler (weblogcss :uri "/weblog.css") ()
    (setf (hunchentoot:content-type*) "text/css")
    (format nil "~a"
	    (css-lite:css (("a.logtag")
			   (:padding-left "05px"
			    :padding-right "05px"))
			  (("a:link")
			   (:color "#229944"
			    :text-decoration "none"))
			  (("a:hover")
			   (:text-decoration "underline"))
			  (("a:visited")
			   (:text-decoration "none"))
			  (("a:active")
			   (:text-decoration "none"))
			  (("div.mainContainer")
			   (:width "600px"
			    :margin-left "auto"
			    :margin-right "auto"))
			  (("div.logentry")
			   (:border-bottom "solid #000000 1px"))
			  (("#psaralogo")
			   (:height "100px"
			    :width "100px"
			    :margin-left "250px"))
			  ((".topContainer")
			   (:width "100%"))
			  (("hr.thinline")
			   (:border "solid 1px #000000"
			    :border-top "0"
			    :border-right "0"
			    :border-left "0"
			    :margin "0"
			    :padding "0"))))))

(defun string-to-word-list (string)
  (cl-ppcre:split "\\s+" string))

(defun init-weblog-form-go ()
  (hunchentoot:define-easy-handler (weblogformgo :uri "/weblogform.go") (subject content tags)
    (setf (hunchentoot:content-type*) "text/plain")
    (format nil "~a"
	    (let ((uname (logged-in-p)))
	      (if uname
		  (add-log-entry :timestamp (get-universal-time)
				 :subject subject
				 :author uname
				 :content content
				 :tags (string-to-word-list tags))
		  (hunchentoot:redirect "/login"))))))

(defun init-weblog-form ()
  (hunchentoot:define-easy-handler (weblogform :uri "/weblogform") ()
      (setf (hunchentoot:content-type*) "text/html")
    (unless (logged-in-p)
      (hunchentoot:redirect "/login"))
    (format nil "~a"
	    (cl-markup:html
	     (:head
	      (:title "new entry [psara/honeylog]"))
	     (:body
	      (:p
	       (:form :action "/weblogform.go"
		      :method "post"
		      :enctype "application/x-www-form-urlencoded"
		      :name "logentryform"
		      (:p
		       (:input :type "text"
			       :name "subject"
			       :placeholder "subject"
			       :id "subject")
		       (:textarea :name "content"
				  :placeholder "write entry here..."
				  :id "content" "")
		       (:input :type "text"
			       :name "tags"
			       :placeholder "separate tags by a space"
			       :id "tags")
		       (:input :type "submit")))))))))

(defun +init-weblog+ ()
  (load-log-entries)
  (init-weblog-style)
  (init-weblog-display)
  (init-weblog-form)
  (init-weblog-form-go))
