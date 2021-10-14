(uiop:define-package #:40ants-doc/locatives/symbol-macro
  (:use #:cl)
  (:import-from #:40ants-doc/locatives/base
                #:locate-and-find-source
                #:locate-error
                #:locate-object
                #:define-locative-type)
  (:import-from #:40ants-doc/render/args)
  (:import-from #:40ants-doc/reference-api
                #:canonical-reference)
  (:import-from #:40ants-doc/args)
  (:import-from #:40ants-doc/reference)
  (:import-from #:40ants-doc/builder/vars)
  (:import-from #:40ants-doc/utils)
  (:import-from #:40ants-doc/page)
  (:import-from #:40ants-doc/builder/printer)
  (:import-from #:swank-backend)
  (:import-from #:40ants-doc/source-api)
  (:import-from #:40ants-doc/locatives
                #:symbol-macro)
  (:import-from #:40ants-doc/locatives/utils)
  (:import-from #:40ants-doc/commondoc/builder)
  (:import-from #:40ants-doc/commondoc/bullet)
  (:import-from #:40ants-doc/docstring))

(in-package 40ants-doc/locatives/symbol-macro)

(define-locative-type symbol-macro ()
  "")

(defmethod locate-object ((symbol symbol)
                          (locative-type (eql 'symbol-macro))
                          locative-args)
  (when (equalp (macroexpand-1 symbol)
		symbol)
    (locate-error))
  (40ants-doc/reference::make-reference symbol (cons locative-type locative-args)))

(defmethod 40ants-doc/commondoc/builder::reference-to-commondoc ((symbol symbol) (locative-type (eql 'symbol-macro)) locative-args)
  (let* ((reference (canonical-reference
                     (40ants-doc/reference::make-reference
                      symbol (cons locative-type locative-args))))
         (docstring (40ants-doc/docstring:get-docstring symbol :symbol-macro))
         (children (when docstring
                     (40ants-doc/commondoc/markdown:parse-markdown docstring))))

    (40ants-doc/commondoc/bullet::make-bullet reference
                                              :arglist locative-args
                                              :children children
                                              :ignore-words symbol)))

(defmethod locate-and-find-source (symbol
                                   (locative-type (eql 'symbol-macro))
                                   locative-args)
  (declare (ignore locative-args))
  ;; Some implementations can not find the source location of the
  ;; accessor function, so fall back on FIND-ONE-LOCATION.
  (let ((location (40ants-doc/source-api::find-source (symbol-function symbol))))
    (if (eq :error (first location))
        (40ants-doc/locatives/utils::find-one-location (swank-backend:find-definitions symbol)
                                                       '("function" "operator"))
        location)))

