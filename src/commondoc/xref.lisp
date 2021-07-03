(uiop:define-package #:40ants-doc/commondoc/xref
  (:use #:cl)
  (:import-from #:40ants-doc/commondoc/bullet)
  (:import-from #:common-doc
                #:define-node)
  (:import-from #:40ants-doc/commondoc/html
                #:with-html)
  (:import-from #:common-html.emitter
                #:define-emitter)
  (:export
   #:make-xref
   #:xref
   #:xref-name
   #:xref-symbol
   #:xref-locative))
(in-package 40ants-doc/commondoc/xref)


(define-node xref (common-doc:document-node)
             ((name :accessor xref-name
                    :initarg :name
                    :type string
                    :documentation "Original text, found in a documentation string")
              (symbol :accessor xref-symbol
                      :initarg :symbol
                      :type (or null symbol)
                      :documentation "A symbol, matched to a XREF-NAME.

                                      I can be NIL if no symbol was found.
                                      In this case a warning will be shown.")
              (locative :accessor xref-locative
                        :initarg :locative
                        :type (or null symbol)
                        :documentation "Sometime xref might be followed by a locative name.
                                        In this case this slot will be filled with a corresponding
                                        locative symbol from 40ANTS-DOC/LOCATIVES package."))
             (:documentation "A link some entity, refered in markdown as a link like [Some text][the-id]
                              or just being UPPERCASED-SYMBOL mentioned."))


(defun make-xref (name &key symbol locative)
  (check-type name string)
  (check-type symbol (or null symbol))
  (check-type locative (or null symbol))
  
  (make-instance 'xref
                 :name name
                 :symbol symbol
                 :locative locative))



(defun replace-references (node known-references)
  "Replaces XREF with COMMON-DOC:WEB-LINK.

   Returns links which were not replaced because there wasn't
   a corresponding reference in the KNOWN-REFERENCES argument."
  
  (flet ((replacer (node)
           (typecase node
             (xref
              (let* ((text (xref-name node))
                     (symbol (xref-symbol node))
                     (locative (xref-locative node))
                     (found-references
                       (loop for reference in known-references
                             when (and (eql (40ants-doc/reference::reference-object reference)
                                            symbol)
                                       (or (null locative)
                                           (eql (40ants-doc/reference::reference-locative reference)
                                                locative)))
                             collect reference)))
                (cond
                  (found-references
                   (labels ((reference-to-uri (reference)
                              (40ants-doc/utils::html-safe-name
                               (40ants-doc/reference::reference-to-anchor reference)))
                            (make-link (reference text)
                              (common-doc:make-document-link nil
                                                        (reference-to-uri reference)
                                                        (common-doc:make-code
                                                         (common-doc:make-text text)))))
                     (if (= (length found-references) 1)
                         (make-link (first found-references)
                                    text)
                         (common-doc:make-content
                          (append (list (common-doc:make-code
                                         (common-doc:make-text text))
                                        (common-doc:make-text " ("))
                                  (loop for reference in found-references
                                        for index upfrom 1
                                        for text = (format nil "~A" index)
                                        collect (make-link reference text)
                                        unless (= index (length found-references))
                                        collect (common-doc:make-text " "))
                                  (list (common-doc:make-text ")")))))))
                  
                  (t node))))
             (t
              node))))
    (40ants-doc/commondoc/mapper:map-nodes node #'replacer)))


(defun collect-references (node &aux results)
  "Returns a list of 40ANTS-DOC/REFERENCE:REFERENCE objects"
  
  (flet ((collector (node)
           (when (typep node '40ants-doc/commondoc/bullet::bullet)
             (push (40ants-doc/commondoc/bullet::bullet-reference node)
                   results))
           node))
    (40ants-doc/commondoc/mapper:map-nodes node #'collector))

  results)



(define-emitter (obj xref)
                "Emit an reference which was not processed by REPLACE-REFERENCES."
                (with-html
                  (:code :class "unresolved-reference"
                         ;; Later we'll need to create a separate CSS with color theme
                         :style "color: magenta"
                         (xref-name obj))))
