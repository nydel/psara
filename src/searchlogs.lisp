(in-package :cl-psara)

(defun search-logs-for-string (string)
  (remove-if-not
   (lambda (y)
     (or
      (search string
	      (log-entry-content y))
      (find string
	    (log-entry-tags y)
	    :test #'string-equal)))
   *log-entry-db*))

(defun init-search-page ()
  (hunchentoot:define-easy-handler (searchlogs :uri "/searchlogs") (q)
    (setf (hunchentoot:content-type*) "text/html")
    (format nil "~a"
	    (markup:html
	     (:head
	      (:title "log-entry search [psara/honeylog]")
	      (:link :rel "stylesheet" :type "text/css" :href "/weblog.css")
	      (:link :rel "stylesheet" :type "text/css" :href "/formstyle.css"))
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
			      (:a :href "https://github.com/miercoledi/psara.git" "https://github.com/miercoledi/psara.git"))
			  (:hr :class "thinline")
			  (:p :class "topBar"
			      (:form :class "inline"
				     :action "/searchlogs"
				     (:label :for "q" "search results for query ")
				     (:input :type "text" :name "q" :placeholder q)
				     (:input :type "submit" :value "go")))
			  (:hr :class "thinline"))

		    (mapcar (lambda (y)
			      (format-log-entry-for-display y))
			    (search-logs-for-string q))))))))

(defun +init-log-search+ ()
  (init-search-page))
