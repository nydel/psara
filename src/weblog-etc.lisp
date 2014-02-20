#|

this file is not only a rewrite of weblog.lisp, it makes use of a new tool,
a macro called "(&do-etc)" which allows the user to attach functions that format
output to one another and contatenate the results of them all. example:

* (&do-etc (format nil "~a" (get-universal-time)) :etc
      (&do-etc (format nil " is the current timestamp!") :etc nil))

=> "3601920151 is the current timestamp!"

we will use this method in order to stack widgets and functions for output as
hyptertext & markup throughout psara, giving a consitent feel to the program.

right away i need to remember how to do macro characters and assign one to this idea.

|#

(in-package :cl-psara)

(defmacro &do-etc (function &key etc)
  `(format nil "~a~a" ,function (if ,etc (eval ,etc) "")))
		

(defun simple-datetime-string (timestamp)
  (local-time:format-timestring
   nil
   (local-time:universal-to-timestamp timestamp)
   :format
   '((:year 4 #\0) "-"
     (:month 2 #\0) "-"
     (:day 2 #\0) " | "
     (:hour 2 #\0) ":"
     (:min 2 #\0) ":"
     (:sec 2 #\0))))

(defun &format-log-entry-timestring (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry-timestring
	   (&do-etc (&format-log-entry-timestring entry :etc nil) :etc etc)))
	(t
	 (markup:markup
	  (:dl
	   (:dt
	    (simple-datetime-string (log-entry-timestamp entry))))))))
	
(defun &format-log-entry-subject (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry-subject
	   (&do-etc (&format-log-entry-subject entry :etc nil) :etc etc)))
	(t
	 (markup:markup
	  (:dt :class "logentrytitle"
	       (markup:raw "&nbsp;")
	       (:a
		:href
		(concatenate 'string
			     "/weblogpermalink?id=" (write-to-string (log-entry-timestamp entry))))
	       " by "
	       (:a
		(:href
		 (concatenate 'string
			      "mailto:"
			      (log-entry-author entry)
			      ".at.psara.dot.ps?subject="
			      (log-entry-subject entry))
		 (log-entry-author entry))))))))

(defun &format-log-entry-content (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry-content
	   (&do-etc (&format-log-entry-content entry :etc nil) :etc etc)))
	(t
	 (markup:markup
	  (:dd
	   :class "logentrycontent"
	   (markup:raw
	    (sloppy-regex-replace
	     (log-entry-content entry))))))))

(defun &format-log-entry-tags (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry-tags
	   (&do-etc (&format-log-entry-tags entry :etc nil) :etc etc)))
	(t
	 (markup:markup
	  (:dt
	   :class "logentrytags"
	   (mapcar (lambda (y)
		     (markup:markup
		      (:a
		       :class
		       "logtag"
		       :href
		       (concatenate 'string "/searchlogs?q=" y)
		       y)))
		   (log-entry-tags entry)))))))

(defun &format-log-entry-bottom-bar (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry-bottom-bar
	   (&do-etc (&format-log-entry-bottom-bar entry :etc nil) :etc etc)))
	(t
	 (markup:markup
	  (:div
	   :class "thinlongbar"
	   (:p
	    :class "simple"
	    (markup:raw "&nbsp;")
	    (:a
	     :href
	     (concatenate 'string "/weblogpermalink?id="
			  (write-to-string
			   (log-entry-timestamp entry)))
	     (let ((x (ps::how-many-comments (log-entry-timestamp entry))))
	       (if (eq x 0)
		   "reply"
		   (concatenate 'string
				"reply("
				(write-to-string x)
				")"))))
	    (markup:raw "&nbsp;&nbsp;")
	    (:a
	     :href
	     (concatenate 'string
			  "/loggeditform?id="
			  (write-to-string
			   (log-entry-timestamp entry)))
	     "edit")))))))

(defun &format-log-entry (entry &key etc)
  (cond (etc
	 (return-from &format-log-entry
	   (&do-etc (&format-log-entry entry :etc nil) :etc etc)))
	 (t
	  (markup:markup
	   (:div :id (write-to-string (log-entry-timestamp entry)) :class "logentry"
		 (:dl :class "psaraweblog"
		      (&format-log-entry-timestring entry :etc etc))
		 (markup:raw
		  (&format-log-entry-subject entry :etc etc)
		  (&format-log-entry-content entry :etc etc)
		  (&format-log-entry-tags entry :etc etc)
		  (&format-log-entry-bottom-bar entry :etc etc)))))))

(defun format-log-entry (entry &key etc)
  (markup:markup
   (:div :id (write-to-string (log-entry-timestamp entry)) :class "logentry"
	 (:dl :class "psaraweblog"
	      (markup:raw
	       (&format-log-entry-timestring
		entry
		:etc (&format-log-entry-subject
		      entry
		      :etc (&format-log-entry-content
			    entry
			    :etc (&format-log-entry-tags
				  entry
				  :etc
				  (&format-log-entry-bottom-bar
				   entry
				   :etc nil))))))))))
