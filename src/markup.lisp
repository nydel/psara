(in-package :cl-psara)

(defparameter *markup-regex* '(("(\\#)(\\w+)" . "<a href=#\\2>#\\2</a>")))

;(defun regex-replace-on (string)
;  (loop for i in *markup-regex*
;       (cl-ppcre:regex-replace-all (car i) string (cdr i))))

;(defun regex-replace-on (string &optional markup-regex)
;  (


(defun sloppy-regex-replace (string)
  (let ((string-new string))
    (setf string-new (cl-ppcre:regex-replace-all "(\\#)(\\w+)" string-new "<a href=searchlogs?q=\\2>#\\2</a>"))
    (setf string-new (cl-ppcre:regex-replace-all "(\\[)([buisp])(\\])([^\\[]+)(\\[\\/[buisp]\\])" string-new "<\\2>\\4</\\2>"))
    (setf string-new (cl-ppcre:regex-replace-all "\\s+\\s+" string-new "<br />"))
    string-new))


;; this code can be cleaned later -- right now it's just about writing the regular expressions for cl-ppcre..
;; eventually we'll have a parameter that is a list of regex and their replacements and they'll be dealt with elegantly.
