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

(defvar *log-entry-db-path* (pathname "data/.weblog.db"))

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
			   (markup:raw "&nbsp;")
			   (:a :href (concatenate 'string "/weblogpermalink?id=" (write-to-string (log-entry-timestamp entry)))
			       (log-entry-subject entry))
			   " by " (:a :href (concatenate 'string
							 "mailto:"
							 (log-entry-author entry)
							 ".at.psara.dot.ps?subject="
							 (log-entry-subject entry)) (log-entry-author entry)))
		      (:dd :class "logentrycontent" (markup:raw (sloppy-regex-replace (log-entry-content entry))))
		      (:dt :class "logentrytags" ;;list of items to strings that are links
			   (mapcar (lambda (y)
				     (markup:markup
				      (:a :class "logtag" :href (concatenate 'string "/searchlogs?q=" y) y)))
				   (log-entry-tags entry)))
		 (:div :class "thinlongbar"
		       (:p :class "simple" (markup:raw "&nbsp;")
			   (:a :href (concatenate 'string "/commentform?id="
						  (write-to-string (log-entry-timestamp entry)))
			       (let ((x (ps::how-many-comments (log-entry-timestamp entry))))
				 (if (eq x 0) "reply"
				     (concatenate 'string "reply(" (write-to-string x) ")"))))
			   (markup:raw "&nbsp;&nbsp;")
			   (:a :href (concatenate 'string "/logeditform?id="
						  (write-to-string (log-entry-timestamp entry))) "edit"))))))))


				      


(defun init-weblog-display ()
  (page weblog "/weblog" "text/html" ()
    (markup:html
     (:head
      (:title "psara home [psara/honeylog]")
      (:link :rel "stylesheet" :type "text/css" :href "/weblog.css"))
     (:body
      (:div :class "mainContainer"
	    (:div :class "topContainer"
;		  (:div :class "loginContainer"
;;
;; a remodel of the login form such that if logged-in-p it's a short wide mini control panel
;; and if you're not logged in it's a short wide mini login form with a link to registration
;;
;
		  (:a :href "/weblog"
		      (:img
		       :src "http://www.isismelting.com/psara001.png"
		       :id "psaralogo")))
	    (:div :class "topBar"
		  (:p :class "topBar"
		      "psara on github: "
		      (:a :href "https://github.com/miercoledi/psara.git"
			  "https://github.com/miercoledi/psara.git")))
	    (:hr :class "thinline")
	    
	    (mapcar (lambda (y)
		      (format-log-entry-for-display y))
		    (subseq *log-entry-db* 0 8)))))))

(defun init-weblog-as-index ()
  (hunchentoot:define-easy-handler (weblogasindex :uri "/") ()
    (setf (hunchentoot:content-type*) "text/plain")
    (hunchentoot:redirect "/weblog")))

(defun init-weblog-permalink ()
  "broken, displays the html not-raw...bleh"
  (hunchentoot:define-easy-handler (weblogpermalink :uri "/weblogpermalink") (id)
    (setf (hunchentoot:content-type*) "text/html")
    (let ((entry (car (remove-if-not #'(lambda (y)
					 (equal (read-from-string id)
						(log-entry-timestamp y)))
				     *log-entry-db*))))
      (format nil "~a"
	      (markup:html
	       (:head
		(:title (log-entry-subject entry))
		(:link :rel "stylesheet" :type "text/css" :href "/weblog.css"))
	       (:body
		(:div :class "mainContainer"
		      (:div :class "topContainer"
			    (:a :href "/weblog"
				(:img
				 :src "http://www.isismelting.com/psara001.png"
				 :id "psaralogo")))
		      (:div :class "topBar"
			    (:p :class "topBar"
				"psara on github: "
				(:a :href "https://github.com/miercoledi/psara.git"
				    "https://github.com/miercoledi/psara.git")))
		      (:hr :class "thinline")
		      (markup:raw
		      (format-log-entry-for-display entry))
		      (:div :class "commentdisplay"
			    (markup:raw
			     (drakma:http-request
			      (concatenate 'string "http://localhost:9903/comments?entryid="
					   (write-to-string
					    (log-entry-timestamp entry)))
			      :protocol :http/1.1
			      :method :post)))
		      (:div :class "commentform"
			    (markup:raw
			    (drakma:http-request
			     (concatenate 'string "http://localhost:9903/commentform?id="
					  (write-to-string
					   (log-entry-timestamp entry)))
			     :protocol :http/1.1
			     :method :post))))))))))

(defun init-weblog-style ()
  (hunchentoot:define-easy-handler (weblogcss :uri "/weblog.css") ()
    (setf (hunchentoot:content-type*) "text/css")
    (format nil "~a"
	    (css-lite:css (("a.logtag")
			   (:padding-left "05px"
			    :padding-right "05px"))
			  (("a:link")
			   (:color "#6600CC"
			    :text-decoration "none"))
			  (("a:hover")
			   (:text-decoration "underline"))
			  (("a:visited")
			   (:text-decoration "none"
			    :color "#229944"))
			  (("a:active")
			   (:text-decoration "none"))
			  (("a.logtag")
			   (:color "#6600CC"))
			  (("div.mainContainer")
			   (:width "600px"
			    :margin-left "auto"
			    :margin-right "auto"))
			  (("div.logentry")
			   (:border-bottom "solid #000000 1px"))
			  (("#psaralogo")
			   (:height "100px"
			    :width "100px"
			    :border "solid #DDDDDD 1px"
			    :border-radius "25px 50px 25px 50px"
			    :margin-left "auto"
			    :margin-right "auto"
			    :display "block"))
			  ((".topContainer")
			   (:width "100%"))
			  ((".logentrytitle")
			   (:background "#CCCCEE"
			    :border-radius "25px 25px 25px 25px"))
			  ((".logentrytags")
			   (:background "#EEEEEE"
			    :border-radius "25px 25px 25px 25px"
			    :text-align "right"))
			  ((".thinlongbar")
			   (:background "#DDDDDD"
			    :border-radius "25px 25px 25px 25px"
			    :border "0"
			    :margin "0"
			    :padding "0"))
			  ((".simple")
			   (:border "0"
			    :margin "0"
			    :padding "0"))
			  ((".floatleft")
			   (:text-align "left"
			    :float "left"))
			  (("hr.thinline")
			   (:border "solid 1px #000000"
			    :border-top "0"
			    :border-right "0"
			    :border-left "0"
			    :margin "0"
			    :padding "0"))
			  (("hr.thinsoft")
			   (:border "solid 1px #666666"
			    :border-top "0"
			    :border-right "0"
			    :border-left "0"
			    :margin "0"
			    :padding "0"))))))

(defun init-weblog-form-style ()
  (hunchentoot:define-easy-handler (weblogformcss :uri "/formstyle.css") ()
    (setf (hunchentoot:content-type*) "text/css")
    (format nil "~a"
	    (css-lite:css (("input[type=text]")
			   (:border "1px solid #000000"
			    :border-radius "25px 25px 25px 25px"))
			  (("textarea")
			   (:border "1px solid #000000"
			    :border-radius "25px 25px 25px 25px"
			    :height "200px"
			    :width "500px"))))))

(defun string-to-word-list (string)
  (cl-ppcre:split "\\s+" string))

(defun word-list-to-string (word-list)
  (let* ((word-list-with-spaces (mapcar #'(lambda (y)
					    (concatenate 'string y " ")) word-list))
	 (function-to-eval (append '(concatenate 'string) word-list-with-spaces))
	 (string1 (eval function-to-eval))
	 (string (subseq string1 0 (1- (length string1)))))
    string))

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
	      (:title "new entry [psara/honeylog]")
	      (:link :rel "stylesheet" :type "text/css" :href "/formstyle.css"))
	     (:body
	      (:p
	       (:form :action "/weblogform.go"
		      :method "post"
		      :enctype "application/x-www-form-urlencoded"
		      :name "logentryform"
		      (:p
		       (:p
			(:input :type "text"
			       :name "subject"
			       :placeholder "subject"
			       :id "subject"))
		       (:p
			(:textarea :name "content"
				   :placeholder "write entry here..."
				   :id "content" ""))
		       (:p
			(:input :type "text"
				:name "tags"
				:placeholder "separate tags by a space"
				:id "tags")
			(:input :type "submit"))))))))))

(defun edit-entry (id subject content tags)
  (let ((entry (find-if #'(lambda (y)
			    (equal (log-entry-timestamp y) (read-from-string id))) *log-entry-db*)))
    (setf (log-entry-subject entry) subject)
    (setf (log-entry-content entry) content)
    (setf (log-entry-tags entry) (string-to-word-list tags))
    (write-entries)))

(defun init-edit-form-go ()
  (hunchentoot:define-easy-handler (editformgo :uri "/logeditform.go") (stamp subject content tags)
    (setf (hunchentoot:content-type*) "text/plain")
      (edit-entry stamp subject content tags)
      (hunchentoot:redirect "/weblog")))


(defun init-edit-form ()
  (hunchentoot:define-easy-handler (logeditform :uri "/logeditform") (id)
    (setf (hunchentoot:content-type*) "text/html")
    (unless (logged-in-p)
      (hunchentoot:redirect "/login"))
    (format nil "~a"
	    (let ((entry (car (remove-if-not #'(lambda (y)
						 (equal (read-from-string id)
							(log-entry-timestamp y)))
					     *log-entry-db*))))
	      (cl-markup:html
	       (:head
		(:title (concatenate 'string (log-entry-subject entry) " [psara/edit]"))
		(:link :rel "stylesheet" :type "text/css" :href "/formstyle.css"))
	       (:body
		(:p
		 (:form :action "/logeditform.go"
			:method "post"
			:enctype "application/x-www-form-urlencoded"
			:name "logeditform"
			(:p
			 (:p
			  (:input :type "text"
				  :name "subject"
				  :value (log-entry-subject entry)
				  :id "subject"))
			 (:p
			  (:textarea :name "content"
				     :id "content" (log-entry-content entry)))
			 (:p
			  (:input :type "text"
				  :name "tags"
				  :value (word-list-to-string (log-entry-tags entry)))
			  (:input :type "hidden"
				  :name "stamp"
				  :id "stamp"
				  :value (write-to-string (log-entry-timestamp entry)))
			  (:input :type "submit")))))))))))

(defun +init-weblog+ ()
  (load-log-entries)
  (init-weblog-style)
  (init-weblog-form-style)
  (init-weblog-display)
  (init-weblog-form)
  (init-weblog-form-go)
  (init-weblog-permalink)
  (init-weblog-as-index)
  (init-edit-form)
  (init-edit-form-go))
