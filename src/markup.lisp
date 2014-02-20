(in-package :cl-psara)

(defparameter *markup-regex* '(("(\\#)(\\w+)" . "<a href=#\\2>#\\2</a>")))

;(defun regex-replace-on (string)
;  (loop for i in *markup-regex*
;       (cl-ppcre:regex-replace-all (car i) string (cdr i))))

;(defun regex-replace-on (string &optional markup-regex)
;  (


(defun sloppy-regex-replace (string)
  (let ((string-new string))

    ;;replace all html open/close tags with ampersand codes / disable html
    (setf string-new (cl-ppcre:regex-replace-all "<" string-new "&lt;"))
    (setf string-new (cl-ppcre:regex-replace-all ">" string-new "&gt;")) ;;these two lines should disable html markup
 
    ;;create lists from lines beginning with a dash followed by a space
    (let ((myregex
	   (ppcre:create-scanner
	    '(:sequence
	      (:flags :multi-line-mode-p)
	      :start-anchor
	      (:register "-")
	      (:register (:regex "\\s+"))
	      (:register (:regex ".+"))
	      :end-anchor ))))
      (setf string-new (cl-ppcre:regex-replace myregex string-new "<ul class=\"logentrylist\"><li class=\"logentrylist\">\\3</li>"))
      (setf string-new (cl-ppcre:regex-replace-all myregex string-new "<li class=\"logentrylist\">\\3</li>")))

    ;;create hashtags as links to search for a tag
    (setf string-new (cl-ppcre:regex-replace-all "(\\#)(\\w+)" string-new "<a href=searchlogs?q=\\2>#\\2</a>"))

    ;;handle bold underline italic strikeout, and paragraphs
    (setf string-new (cl-ppcre:regex-replace-all "(\\[)([buisp])(\\])([^\\[]+)(\\[\\/[buisp]\\])" string-new "<\\2>\\4</\\2>"))

    ;;insert a line break after a double space
    (setf string-new (cl-ppcre:regex-replace-all (ppcre:create-scanner `(:sequence (:flags :multi-line-mode-p) :end-anchor (:regex "[^<]") (:register (:non-greedy-repetition 1 2 :whitespace-char-class)))) string-new "<br />\\1"))

    ;;allow for line breaks to be inserted at will
    (setf string-new (cl-ppcre:regex-replace-all "\\[br\\]" string-new "<br />"))

    ;;let five hyphens indicate a horizontal line
    (setf string-new (cl-ppcre:regex-replace-all "-{5}" string-new "<hr class=\"thinsoft\" />"))

    (setf string-new (cl-ppcre:regex-replace-all "(\\[now\\])" string-new (format nil "~a" (get-universal-time))))

    string-new))





;; this code can be cleaned later -- right now it's just about writing the regular expressions for cl-ppcre..
;; eventually we'll have a parameter that is a list of regex and their replacements and they'll be dealt with elegantly.
