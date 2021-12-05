(defpackage #:40ants-doc-full
  (:use #:cl)
  (:nicknames #:40ants-doc/full)
  (:import-from #:40ants-doc/builder)
  
  ;; TODO: Все эти locatives надо сделать доступными в минимальном пакете
  ;; может быть не загружать сами модули, но сделать так, чтобы на них можно было ссылаться
  (:import-from #:40ants-doc/locatives/section)
  (:import-from #:40ants-doc/locatives/function)
  (:import-from #:40ants-doc/locatives/dislocated)
  (:import-from #:40ants-doc/locatives/class)
  (:import-from #:40ants-doc/locatives/asdf-system)
  (:import-from #:40ants-doc/locatives/argument)
  (:import-from #:40ants-doc/locatives/compiler-macro)
  (:import-from #:40ants-doc/locatives/constant)
  (:import-from #:40ants-doc/locatives/variable)
  (:import-from #:40ants-doc/locatives/glossary)
  (:import-from #:40ants-doc/locatives/locative)
  (:import-from #:40ants-doc/locatives/macro)
  (:import-from #:40ants-doc/locatives/generic-function)
  (:import-from #:40ants-doc/locatives/method)
  (:import-from #:40ants-doc/locatives/package)
  (:import-from #:40ants-doc/locatives/restart)
  (:import-from #:40ants-doc/locatives/slots)
  (:import-from #:40ants-doc/locatives/structure-accessor)
  (:import-from #:40ants-doc/locatives/symbol-macro)
  (:import-from #:40ants-doc/locatives/type)
  (:import-from #:40ants-doc/locatives/include)
  (:import-from #:40ants-doc/locatives/stdout-of)
  (:import-from #:40ants-doc/github)
  (:import-from #:40ants-doc/commondoc/section)
  (:import-from #:40ants-doc/commondoc/changelog)
  (:import-from #:40ants-doc/object-package-impl)
  (:import-from #:40ants-doc/themes/default)
  (:import-from #:40ants-doc/themes/light)
  (:import-from #:40ants-doc/themes/dark))
(in-package 40ants-doc/full)
