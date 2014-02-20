(in-package :cl-user)

(defpackage cl-psara-asd
  (:use :cl :asdf))

(in-package :cl-psara-asd)

(defsystem cl-psara
  :version "0.1"
  :author "<nydel@psara.ps>"
  :license "LLGPL"
  :components ((:module "src"
		:serial t
		:components ((:file "package")
			     (:file "psara")
			     (:file "login")
			     (:file "toolbar")
			     (:file "weblog")
			     (:file "weblog-etc")
			     (:file "comments")
			     (:file "markup")
			     (:file "searchlogs")))))

(in-package :cl-psara)
