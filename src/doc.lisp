(in-package :mgl-pax)

;;;; Generating docs for PAX. Not included in the ASDF system.

(defun update-readmes ()
  ;; README.md has anchors, links, inline code, and other markup
  ;; added. Not necessarily the easiest on the eye in text, but looks
  ;; good on github.
  (with-open-file (stream (asdf:system-relative-pathname :mgl-pax "README.md")
                          :direction :output
                          :if-does-not-exist :create
                          :if-exists :supersede)
    (document @pax-manual :stream stream))
  ;; README is optimized for reading in text format. Has no links and
  ;; cluttery markup.
  (with-open-file (stream (asdf:system-relative-pathname :mgl-pax "README")
                          :direction :output
                          :if-does-not-exist :create
                          :if-exists :supersede)
    (describe @pax-manual stream)))

(defun update-html ()
  (document
   ;; This could be a list of objects (typically sections), if you
   ;; want to generate documentation for related libraries with
   ;; cross-links.
   @pax-manual
   :pages (loop for section in
                            (list
                             ;; Comment this in, if you want
                             ;; the 'Extension API' section
                             ;; to go to a separate file.
                             #+nil
                             @pax-extension-api
                             @pax-manual)
                collect (section-to-page-spec section))
   :format :html))

(defun section-to-filename (section)
  (asdf:system-relative-pathname
   :mgl-pax
   (format nil "doc/~a.html"
           (string-downcase (subseq (symbol-name (section-name section)) 1)))))

(defun section-to-page-spec (section &key
                             (open-args '(:if-does-not-exist :create
                                          :if-exists :supersede
                                          :ensure-directories-exist t)))
  (flet ((header (title stream)
           (html-header stream :title title
                        :stylesheet "style.css" :charset "UTF-8"))
         (footer (stream)
           (html-footer stream)))
    `(:objects
      (,section)
      :output (,(section-to-filename section) ,@open-args)
      :header-fn ,(lambda (stream)
                    (header (section-title section) stream))
      :footer-fn ,#'footer)))

(defun html-header (stream &key title stylesheet (charset "UTF-8"))
  (format stream
          "<!DOCTYPE html>~%~
          <html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'>~%~
          <head>~%~
          ~@[<title>~A</title>~]~%~
          ~@[<link type='text/css' href='~A' rel='stylesheet'/>~]~%~
          ~@[<meta http-equiv=\"Content-Type\" ~
                   content=\"text/html; ~
                   charset=~A\"/>~]~%~
          </head>~%~
          <body>"
          title stylesheet charset))

(defun html-footer (stream)
  (format stream "</body>~%</html>~%"))

#|

(update-readmes)

(update-html)

|#
