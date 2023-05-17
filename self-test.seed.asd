(asdf:defsystem :self-test.seed
  :description "Simple inline tests."
  :author "Peter von Etter"
  :license "LGPL-3.0"
  :version "0.0.1"
  :serial t
  :components ((:file "self-test.seed"))
  :depends-on (#:alexandria
               #:package.seed))
