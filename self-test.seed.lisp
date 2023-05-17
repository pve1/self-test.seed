(package.seed:define-seed-package :self-test.seed :export-capitalized t)

(in-package :self-test.seed)

;;;; Self test

(defun all-tees (list)
  (and list (every (lambda (x) (eq t x)) list)))

(defvar *Crash-on-self-test-failure* nil)
(defvar *Report-self-test-success* nil)
(defvar *self-test-table* (make-hash-table :test 'eq))

(defun format-result (result)
  (coerce (mapcar (lambda (x)
                            (if (eq t x)
                                #\.
                                #\f))
                          result)
          'string))

(defun self-test-report (name result &optional condition)
  (cond ((all-tees result)
         (when *report-self-test-success*
           (format t "~&; Self test passed: ~S ~A~%" name (format-result result)))
         t)
        (*crash-on-self-test-failure*
         (error "; Self test FAILED: ~S ~A" name
                (format-result result)))
        (t
         (format *error-output* "~&; Self test FAILED: ~S ~A ~A~%"
                 name
                 (format-result result)
                 (if condition
                     (format nil "~%;; (~A)" condition)
                     ""))
         nil)))

(defun %run-self-test (name &optional form)
  (let* ((form (or form (gethash name *self-test-table*)))
         (condition)
         (f (handler-case (compile nil form)
              (error (x) (progn (setf condition x)
                                nil))))
         (res (if f
                  (handler-case (funcall f)
                    (error (x)
                      (progn (setf condition x)
                             (list nil))))
                  (list nil))))
    (self-test-report name res condition)))

(defun %define-self-test (name body)
  (let* ((*report-self-test-success*
           (if (or *load-truename*
                   *compile-file-truename*)
               nil
               t))
         (lambda-form
           `(lambda ()
              (let* ((*package* (find-package
                                 ,(package-name *package*))))
                (list ,@body)))))
    (setf (gethash name *self-test-table*) lambda-form)
    (%run-self-test name lambda-form)))

(defmacro Define-self-test (name &body body)
  `(%define-self-test ',name ',body))

(defun Run-self-tests (&key (package *package*) (report-success t))
  (let ((*report-self-test-success* report-success))
    (let ((p (when package
               (unless (eq :all package)
                 (find-package package)))))
      (maphash (lambda (name form)
                 (cond (p (when (eq p (symbol-package name))
                            (%run-self-test name form)))
                       (t (%run-self-test name form))))
               *self-test-table*))))

(defmacro warn-on-nil (form)
  (alexandria:with-gensyms (val)
    `(let* ((,val ,form))
       (unless ,val (warn "Null form ~A." ',form))
       ,val)))

(pushnew :self-test.seed *features*)
