(in-package :cl-psara)

(defun init-logged-in-toolbar-style ()
  (hunchentoot:define-easy-handler (toolbarstyle :uri "/toolbar.css") ()
    (setf (hunchentoot:content-type*) "text/css")
    (format nil "~a"
	    (css-lite:css (("ul.toolbar, li.toolbaritem")
			   (:display "inline"
			    :padding "0"
			    :margin "0"))
			  (("li.toolbaritem")
			   (:padding-left "5px"
			    :padding-right "5px"))
			  (("div#usertoolbar")
			   (:border "1px solid #AAAACC"
			    :border-radius "25px 25px 25px 25px"
			    :background "#BBBBDD"
			    :margin-bottom "5px"))))))

(defun init-logged-in-toolbar ()
  (hunchentoot:define-easy-handler (toolbar :uri "/toolbar") (uname)
    (setf (hunchentoot:content-type*) "text/html")
;    (let* ((session (hunchentoot:start-session))
;	   (cookie (hunchentoot:cookie-out "hunchentoot-session"))
;	   (uname (hunchentoot:session-value 'uname session)))
      (format nil "~a"
	      (markup:markup
	       (:head
		(:link :rel "stylesheet" :type "text/css" :href "/toolbar.css"))
	       (:body
		(:div :id "usertoolbar"
		      (:ul :class "toolbar"
		       (:li :class "toolbaritem"
			    "psara" (markup:raw "&nbsp;&rarr;&nbsp") "logged in as " uname (markup:raw "&nbsp;&nbsp;"))
		       (:li :class "toolbaritem"
			    (:a :href "/weblogform" "new-entry"))
		       (:li :class "toolbaritem"
			    (:a :href "/searchlogs?q=psara" "search"))
		       (:li :class "toolbaritem"
			    (:a :href "/adminpanel" "admin-panel"))
		       (:li :class "toolbaritem"
			    (:a :href "/logout" "logout")))))))))

(defun init-not-logged-in-toolbar ()
  (hunchentoot:define-easy-handler (toolbarnotloggedin :uri "/toolbarnotloggedin") ()
    (setf (hunchentoot:content-type*) "text/html")
    (format nil "~a"
	    (markup:markup
	     (:head
	      (:link :rel "stylesheet" :type "text/css" :href "/toolbar.css"))
	     (:body
	      (:div :id "usertoolbar"
		    (:ul :class "toolbar"
		     (:li :class "toolbaritem"
			  "psara [not logged in]" (markup:raw "&nbsp;&nbsp;"))
		     (:li :class "toolbaritem"
			  (:a :href "/login" "login"))
		     (:li :class "toolbaritem"
			  (:a :href "/register" "register"))
		     (:li :class "toolbaritem"
			  (:a :href "/logout" "logout")))))))))

(defun +init-toolbar+ ()
  (init-logged-in-toolbar-style)
  (init-not-logged-in-toolbar)
  (init-logged-in-toolbar))
