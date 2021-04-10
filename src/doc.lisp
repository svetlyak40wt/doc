(uiop:define-package #:40ants-doc/doc
  (:use #:cl
        #:40ants-doc/locatives)
  (:import-from #:40ants-doc
                #:defsection)
  (:import-from #:40ants-doc/restart)
  (:import-from #:40ants-doc/glossary)

  (:import-from #:40ants-doc/full)
  (:import-from #:named-readtables)
  (:import-from #:pythonic-string-reader)
  (:import-from #:40ants-doc/builder)
  (:import-from #:40ants-doc/markdown)
  (:import-from #:40ants-doc/builder/printer)
  (:import-from #:40ants-doc/link)
  (:import-from #:40ants-doc/builder/vars)
  (:import-from #:40ants-doc/locatives/base)
  (:import-from #:40ants-doc/reference-api)
  (:import-from #:40ants-doc/reference)
  (:import-from #:40ants-doc/source-api)
  (:import-from #:40ants-doc/document))
(in-package 40ants-doc/doc)

(named-readtables:in-readtable pythonic-string-reader:pythonic-string-syntax)


(defsection @index (:title "40Ants Doc Manual"
                    :ignore-words ("HTML"
                                   "HTMLs"
                                   "README"
                                   "JSON"
                                   "MGL-PAX"
                                   "SLIME"
                                   "SWANK"
                                   "SLY"
                                   "URI"
                                   "URL"
                                   "URLs"
                                   "LISP"
                                   "SBCL"))
  "
[![](http://github-actions.40ants.com/40ants/doc/matrix.svg)](https://github.com/40ants/doc)

[![Coverage Status](https://coveralls.io/repos/github/40ants/doc/badge.svg?branch=master)](https://coveralls.io/github/40ants/doc?branch=master)

"
  (@about section)
  (40ants-doc system)
  (@links section)
  (@background section)
  (@tutorial section)
  (@emacs-integration section)
  (@basics section)
  (40ants-doc/builder::@generating-documentation section)
  (40ants-doc/markdown::@markdown-support section)
  (@documentation-printer-variables section)
  (@locative-types section)
  (@extension-api section)
  (40ants-doc/transcribe::@transcript section)
  (@todo section))


(defsection @about (:title "About this fork")
  "
This system is a fork of [MGL-PAX](https://github.com/melisgl/mgl-pax).

There are a few reasons, why I've created the fork.

The main goal is to extract a core features into the system 40ANTS-DOC
with as little dependencies as possible. This is important, because with MGL-PAX's
style, you define documentation sections in your library's code, which makes
it dependent on the documentation system. However, heavy weight dependencies
like IRONCLAD, 3BMD or SWANK should not be required.

The seconds goal was to refactor a 3.5k lines of `pax.lisp` file into
a smaller modules to make navigation easier. This will help any person
who will decide to learn how the documentation builder works. Also,
granular design will make it possible loading subsystems like SLIME or SLY
integration.

In future I'm planning to extend this fork. Learn more in the @TODO section.")


(defsection @links (:title "Links")
  "
  Here is the [official repository](https://github.com/40ants/doc) and
  the [HTML documentation](https://40ants.com/doc) for the latest version.

  This system is a fork of the [MGL-PAX](https://github.com/melisgl/mgl-pax).
  Because of massive refactoring, it is incompatible with original repository.
")


(defsection @background (:export nil :title "Background")
  "As a user, I frequently run into documentation that's incomplete
  and out of date, so I tend to stay in the editor and explore the
  code by jumping around with SLIME's [`M-.`][slime-M-.]. As a library
  author, I spend a great deal of time polishing code, but precious
  little writing documentation.

  [slime-M-.]: http://common-lisp.net/project/slime/doc/html/Finding-definitions.html#Finding-definitions

  In fact, I rarely write anything more comprehensive than docstrings
  for exported stuff. Writing docstrings feels easier than writing a
  separate user manual and they are always close at hand during
  development. The drawback of this style is that users of the library
  have to piece the big picture together themselves.

  That's easy to solve, I thought, let's just put all the narrative
  that holds docstrings together in the code and be a bit like a
  Literate Programming weenie turned inside out. The original
  prototype which did almost everything I wanted was this:

  ```
  (defmacro defsection (name docstring)
    `(defun ,name () ,docstring))
  ```

  Armed with DEFSECTION, I soon found myself organizing code following
  the flow of user level documentation and relegated comments to
  implementational details entirely. However, some portions of
  DEFSECTION docstrings were just listings of all the functions,
  macros and variables related to the narrative, and this list was
  effectively repeated in the DEFPACKAGE form complete with little
  comments that were like section names. A clear violation of
  [OAOO][oaoo], one of them had to go, so DEFSECTION got a list of
  symbols to export.

  [oaoo]: http://c2.com/cgi/wiki?OnceAndOnlyOnce

  That was great, but soon I found that the listing of symbols is
  ambiguous if, for example, a function, a compiler macro and a class
  are named by the same symbol. This did not concern exporting, of
  course, but it didn't help readability. Distractingly, on such
  symbols, `M-.` was popping up selection dialogs. There were two
  birds to kill, and the symbol got accompanied by a type which was
  later generalized into the concept of locatives:

  ```commonlisp
  (defsection @introduction ()
    \"A single line for one man ...\"
    (foo class)
    (bar function))
  ```

  After a bit of elisp hacking, `M-.` was smart enough to disambiguate
  based on the locative found in the vicinity of the symbol and
  everything was good for a while.

  Then I realized that sections could refer to other sections if there
  were a SECTION locative. Going down that path, I soon began to feel
  the urge to generate pretty documentation as all the necessary
  information was manifest in the DEFSECTION forms. The design
  constraint imposed on documentation generation was that following
  the typical style of upcasing symbols in docstrings there should be
  no need to explicitly mark up links: if `M-.` works, then the
  documentation generator shall also be able find out what's being
  referred to.

  I settled on [Markdown][markdown] as a reasonably non-intrusive
  format, and a few thousand lines later MGL-PAX was born.

  [markdown]: https://daringfireball.net/projects/markdown/")

(defsection @tutorial (:title "Tutorial")
  """40ANTS-DOC provides an extremely poor man's Explorable Programming
  environment. Narrative primarily lives in so called sections that
  mix markdown docstrings with references to functions, variables,
  etc, all of which should probably have their own docstrings.

  The primary focus is on making code easily explorable by using
  SLIME's `M-.` (`slime-edit-definition`). See how to enable some
  fanciness in @EMACS-INTEGRATION. Generating documentation
  from sections and all the referenced items in Markdown or HTML
  format is also implemented.

  With the simplistic tools provided, one may accomplish similar
  effects as with Literate Programming, but documentation is generated
  from code, not vice versa and there is no support for chunking yet.
  Code is first, code must look pretty, documentation is code.

  In typical use, using 40ANTS-DOC, packages have no :EXPORT's defined.
  Instead the UIOP:DEFINE-PACKAGE form gets a docstring which may mention section
  names (defined with DEFSECTION). When the code is loaded into the
  lisp, pressing `M-.` in SLIME on the name of the section will take
  you there. Sections can also refer to other sections, packages,
  functions, etc and you can keep exploring.

  Here is an example of how it all works together:

  ```commonlisp
  (uiop:define-package #:foo-random
    (:documentation "This package provides various utilities for
  random. See @FOO-RANDOM-MANUAL.")
    (:use #:common-lisp #:40ants-doc))

  (in-package foo-random)

  (defsection @foo-random-manual (:title "Foo Random manual")
    "Here you describe what's common to all the referenced (and
                                                            exported) functions that follow. They work with *FOO-STATE*,
  and have a :RANDOM-STATE keyword arg. Also explain when to
  choose which."
    (foo-random-state class)
    (state (reader foo-random-state))
    "Hey we can also print states!"
    (print-object (method () (foo-random-state t)))
    (*foo-state* variable)
    (gaussian-random function)
    (uniform-random function)
    ;; this is a subsection
    (@foo-random-examples section))

  (defclass foo-random-state ()
    ((state :reader state)))

  (defmethod print-object ((object foo-random-state) stream)
    (print-unreadable-object (object stream :type t)))

  (defvar *foo-state* (make-instance 'foo-random-state)
    "Much like *RANDOM-STATE* but uses the FOO algorithm.")

  (defun uniform-random (limit &key (random-state *foo-state*))
    "Return a random number from the between 0 and LIMIT (exclusive)
  uniform distribution."
    nil)

  (defun gaussian-random (stddev &key (random-state *foo-state*))
    "Return a random number from a zero mean normal distribution with
  STDDEV."
    nil)

  (defsection @foo-random-examples (:title "Examples")
    "Let's see the transcript of a real session of someone working
  with FOO:

  ```cl-transcript
  (values (princ :hello) (list 1 2))
  .. HELLO
  => :HELLO
  => (1 2)

  (make-instance 'foo-random-state)
  ==> #<FOO-RANDOM-STATE >
  ```")
  ```

  Generating documentation in a very stripped down markdown format is
  easy:

  ```commonlisp
  (describe @foo-random-manual)
  ```

  For this example, the generated markdown would look like this:

      # Foo Random manual

      ###### \[in package FOO-RANDOM\]
      Here you describe what's common to all the referenced (and
      exported) functions that follow. They work with *FOO-STATE*,
      and have a :RANDOM-STATE keyword arg. Also explain when to
      choose which.

      - [class] FOO-RANDOM-STATE

      - [reader] STATE FOO-RANDOM-STATE

      Hey we can also print states!

      - [method] PRINT-OBJECT (OBJECT FOO-RANDOM-STATE) STREAM

      - [variable] *FOO-STATE* #<FOO-RANDOM-STATE >

          Much like *RANDOM-STATE* but uses the FOO algorithm.

      - [function] GAUSSIAN-RANDOM STDDEV &KEY (RANDOM-STATE *FOO-STATE*)

          Return a random number from a zero mean normal distribution with
          STDDEV.

      - [function] UNIFORM-RANDOM LIMIT &KEY (RANDOM-STATE *FOO-STATE*)

          Return a random number from the between 0 and LIMIT (exclusive)
          uniform distribution.

      ## Examples

      Let's see the transcript of a real session of someone working
      with FOO:

      ```cl-transcript
      (values (princ :hello) (list 1 2))
      .. HELLO
      => :HELLO
      => (1 2)

      (make-instance 'foo-random-state)
      ==> #<FOO-RANDOM-STATE >

      ```

  More fancy markdown or HTML output with automatic markup and linking
  of uppercase symbol names found in docstrings, section numbering,
  table of contents, etc is possible by calling the `40ANTS-DOCUMENT::DOCUMENT`
  function.

  One can even generate documentation for different, but related
  libraries at the same time with the output going to different files,
  but with cross-page links being automatically added for symbols
  mentioned in docstrings. See `40ANTS-DOC/BUILDER::@GENERATING-DOCUMENTATION` for
  some convenience functions to cover the most common cases.

  Note how `(VARIABLE *FOO-STATE*)` in the DEFSECTION form both
  exports `*FOO-STATE*` and includes its documentation in
  `@FOO-RANDOM-MANUAL`. The symbols VARIABLE and FUNCTION are just two
  instances of 'locatives' which are used in DEFSECTION to refer to
  definitions tied to symbols. See @LOCATIVE-TYPES.

  The transcript in the code block tagged with `cl-transcript` is
  automatically checked for up-to-dateness. See
  `40ANTS-DOC/TRANSCRIBE::@TRANSCRIPT`.""")

(defsection @emacs-integration (:title "Emacs Integration")
  "Integration into SLIME's `M-.` (`slime-edit-definition`) allows one
  to visit the source location of the thing that's identified by a
  symbol and the locative before or after the symbol in a buffer. With
  this extension, if a locative is the previous or the next expression
  around the symbol of interest, then `M-.` will go straight to the
  definition which corresponds to the locative. If that fails, `M-.`
  will try to find the definitions in the normal way which may involve
  popping up an xref buffer and letting the user interactively select
  one of possible definitions.

  *Note that the this feature is implemented in terms of
  SWANK-BACKEND:FIND-SOURCE-LOCATION and
  SWANK-BACKEND:FIND-DEFINITIONS whose support varies across the Lisp
  implementations.*

  In the following examples, pressing `M-.` when the cursor is on one
  of the characters of `FOO` or just after `FOO`, will visit the
  definition of function `FOO`:

      function foo
      foo function
      (function foo)
      (foo function)

  In particular, references in a DEFSECTION form are in (SYMBOL
  LOCATIVE) format so `M-.` will work just fine there.

  Just like vanilla `M-.`, this works in comments and docstrings. In
  this example pressing `M-.` on `FOO` will visit `FOO`'s default
  method:

  ```commonlisp
  ;;;; See FOO `(method () (t t t))` for how this all works.
  ;;;; But if the locative has semicolons inside: FOO `(method
  ;;;; () (t t t))`, then it won't, so be wary of line breaks
  ;;;; in comments.
  ```

  With a prefix argument (`C-u M-.`), one can enter a symbol plus a
  locative separated by whitespace to preselect one of the
  possibilities.

  The `M-.` extensions can be enabled by adding this to your Emacs
  initialization file (or loading `src/pax.el`):"
  (pax.el (include #.(asdf:system-relative-pathname :40ants-doc "elisp/pax.el")
                   :header-nl "```elisp" :footer-nl "```")))


(defsection @basics (:title "Basics")
  "Now let's examine the most important pieces in detail."
  (40ants-doc::defsection macro)
  (40ants-doc::*discard-documentation-p* variable)
  (40ants-doc/document::document generic-function))


(defsection @locatives-and-references
    (:title "Locatives and References"
     :ignore-words ("FOO"))
  "While Common Lisp has rather good introspective abilities, not
  everything is first class. For example, there is no object
  representing the variable defined with `(DEFVAR
  FOO)`. `(MAKE-REFERENCE 'FOO 'VARIABLE)` constructs a 40ANTS-DOC/REFERENCE::REFERENCE that
  captures the path to take from an object (the symbol FOO) to an
  entity of interest (for example, the documentation of the variable).
  The path is called the locative. A locative can be applied to an
  object like this:

  ```
  (locate 'foo 'variable)
  ```

  which will return the same reference as `(MAKE-REFERENCE 'FOO
  'VARIABLE)`. Operations need to know how to deal with references
  which we will see in 40ANTS-DOC/LOCATIVES/BASE::LOCATE-AND-COLLECT-REACHABLE-OBJECTS,
  40ANTS-DOC/LOCATIVES/BASE::LOCATE-AND-DOCUMENT and 40ANTS-DOC/LOCATIVES/BASE::LOCATE-AND-FIND-SOURCE.

  Naturally, `(LOCATE 'FOO 'FUNCTION)` will simply return `#'FOO`, no
  need to muck with references when there is a perfectly good object."
  (40ants-doc/locatives/base::locate function)
  (40ants-doc/locatives/base::locate-error condition)
  (40ants-doc/locatives/base::locate-error-message (reader 40ants-doc/locatives/base::locate-error))
  (40ants-doc/locatives/base::locate-error-object (reader 40ants-doc/locatives/base::locate-error))
  (40ants-doc/locatives/base::locate-error-locative (reader 40ants-doc/locatives/base::locate-error))
  (40ants-doc/reference::resolve function)
  (40ants-doc/reference::reference class)
  (40ants-doc/reference::reference-object (reader 40ants-doc/reference::reference))
  (40ants-doc/reference::reference-locative (reader 40ants-doc/reference::reference))
  (40ants-doc/reference::make-reference function)
  (40ants-doc/locatives/base::locative-type function)
  (40ants-doc/locatives/base::locative-args function))


(defsection @documentation-printer-variables
    (:title "Documentation Printer Variables")
  "Docstrings are assumed to be in markdown format and they are pretty
  much copied verbatim to the documentation subject to a few knobs
  described below."
  (40ants-doc/builder/printer::*document-uppercase-is-code* variable)
  (40ants-doc/builder/printer::*document-downcase-uppercase-code* variable)
  (40ants-doc/builder/printer::*document-normalize-packages* variable)
  (40ants-doc/link::*document-link-code* variable)
  (40ants-doc/link::*document-link-sections* variable)
  (40ants-doc/link::*document-min-link-hash-length* variable)
  (40ants-doc/builder/vars::*document-mark-up-signatures* variable)
  (40ants-doc/builder/vars::*document-max-numbering-level* variable)
  (40ants-doc/builder/vars::*document-max-table-of-contents-level* variable)
  (40ants-doc/builder/vars::*document-text-navigation* variable)
  (40ants-doc/builder/vars::*document-fancy-html-navigation* variable))


(defsection @locative-types (:title "Locative Types")
  "These are the locatives type supported out of the box. As all
  locative types, they are symbols and their names should make it
  obvious what kind of things they refer to. Unless otherwise noted,
  locatives take no arguments."
  (system locative)
  (section locative)
  (variable locative)
  (constant locative)
  (macro locative)
  (compiler-macro locative)
  (function locative)
  (generic-function locative)
  (method locative)
  (accessor locative)
  (reader locative)
  (writer locative)
  (structure-accessor locative)
  (class locative)
  (condition locative)
  (type locative)
  (package locative)
  (dislocated locative)
  (argument locative)
  (locative locative)
  (include locative)
  (40ants-doc/restart::define-restart macro)
  (restart locative)
  (40ants-doc/glossary::define-glossary-term macro)
  (glossary-term locative))


(defsection @extension-api (:title "Extension API")
  (@locatives-and-references section)
  (@new-object-types section)
  (@reference-based-extensions section)
  (@sections section))


(defsection @new-object-types (:title "Adding New Object Types")
  "One may wish to make the 40ANTS-DOC/DOCUMENT::DOCUMENT function and `M-.` navigation
  work with new object types. Extending 40ANTS-DOC/DOCUMENT::DOCUMENT can be done by
  defining a 40ANTS-DOC/DOCUMENT::DOCUMENT-OBJECT method. To allow these objects to be
  referenced from DEFSECTION, a 40ANTS-DOC/LOCATIVES/BASE::LOCATE-OBJECT method is to be defined.
  Finally, for `M-.` 40ANTS-DOC/SOURCE-API::FIND-SOURCE can be specialized. Finally,
  40ANTS-DOC::EXPORTABLE-LOCATIVE-TYPE-P may be overridden if exporting does not
  makes sense. Here is a stripped down example of how all this is done
  for ASDF:SYSTEM:"
  (asdf-example (include (:start (asdf:system locative)
                          :end (40ants-doc/locatives/asdf-system::end-of-asdf-example variable))
                         :header-nl "```commonlisp"
                         :footer-nl "```"))
  (40ants-doc/locatives/base::define-locative-type macro)
  (40ants-doc::exportable-locative-type-p generic-function)
  (40ants-doc/locatives/base::locate-object generic-function)
  (40ants-doc/locatives/base::locate-error function)
  (40ants-doc/reference-api::canonical-reference generic-function)
  (40ants-doc/reference-api::collect-reachable-objects generic-function)
  (40ants-doc/reference-api::collect-reachable-objects (method () (t)))
  (40ants-doc/document::document-object generic-function)
  (40ants-doc/document::document-object (method () (string t)))
  (40ants-doc/source-api::find-source generic-function))


(defsection @reference-based-extensions
    (:title "Reference Based Extensions")
  "Let's see how to extend 40ANTS-DOC/DOCUMENT::DOCUMENT and `M-.` navigation if there is
  no first class object to represent the thing of interest. Recall
  that 40ANTS-DOC/LOCATIVES/BASE::LOCATE returns a 40ANTS-DOC/REFERENCE::REFERENCE object in this case. 40ANTS-DOC/DOCUMENT::DOCUMENT-OBJECT
  and 40ANTS-DOC/SOURCE-API::FIND-SOURCE defer to 40ANTS-DOC/LOCATIVES/BASE::LOCATE-AND-DOCUMENT and
  40ANTS-DOC/LOCATIVES/BASE::LOCATE-AND-FIND-SOURCE, which have 40ANTS-DOC/LOCATIVES/BASE::LOCATIVE-TYPE in their argument
  list for EQL specializing pleasure. Here is a stripped down example
  of how the VARIABLE locative is defined:"
  (variable-example (include (:start (variable locative)
                              :end (40ants-doc/locatives/variable::end-of-variable-example variable))
                             :header-nl "```commonlisp"
                             :footer-nl "```"))
  (40ants-doc/reference-api::collect-reachable-objects (method () (40ants-doc/reference::reference)))
  (40ants-doc/locatives/base::locate-and-collect-reachable-objects generic-function)
  (40ants-doc/locatives/base::locate-and-collect-reachable-objects (method () (t t t)))
  (40ants-doc/document::document-object (method () (40ants-doc/reference::reference t)))
  (40ants-doc/locatives/base::locate-and-document generic-function)
  (40ants-doc/source-api::find-source (method () (40ants-doc/reference::reference)))
  (40ants-doc/locatives/base::locate-and-find-source generic-function)
  (40ants-doc/locatives/base::locate-and-find-source (method () (t t t)))
  "We have covered the basic building blocks of reference based
  extensions. Now let's see how the obscure
  40ANTS-DOC/LOCATIVES/DEFINERS::DEFINE-SYMBOL-LOCATIVE-TYPE and
  40ANTS-DOC/LOCATIVES/DEFINE-DEFINERS::DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE macros work together to
  simplify the common task of associating definition and documentation
  with symbols in a certain context."
  (40ants-doc/locatives/definers::define-symbol-locative-type macro)
  (40ants-doc/locatives/define-definer::define-definer-for-symbol-locative-type macro))


(defsection @sections (:title "Sections")
  "[Section][class] objects rarely need to be dissected since
  40ANTS-DOC::DEFSECTION and `40ANTS-DOC/DOCUMENT::DOCUMENT` cover most needs. However, it is plausible
  that one wants to subclass them and maybe redefine how they are
  presented."
  (40ants-doc::section class)
  (40ants-doc::section-name (reader 40ants-doc::section))
  (40ants-doc::section-package (reader 40ants-doc::section))
  (40ants-doc::section-readtable (reader 40ants-doc::section))
  (40ants-doc::section-title (reader 40ants-doc::section))
  (40ants-doc::section-link-title-to (reader 40ants-doc::section))
  (40ants-doc::section-entries (reader 40ants-doc::section))
  (describe-object (method () (40ants-doc::section t))))


(defsection @todo (:title "TODO"
                   :ignore-words ("SLIME"
                                  "SLY"
                                  "UPPERCASED"
                                  "HTML"))
  "
- Add warnings on UPPERCASED symbols in docstrings which aren't found in the package and can't be cross referenced.
- Support custom HTML themes.
- Support SLY and make both SLIME and SLY integrations optional.
- Add a search facility which will build an index for static file like Sphinx does.
- Separate markup parsing and result rendering code to support markups other than Markdown and HTML.
")


(defun render ()
  (40ants-doc/builder::update-asdf-system-html-docs
   @index :40ants-doc
   :pages
   (list (list :objects
               (list @index)
               :source-uri-fn
               (40ants-doc/github::make-github-source-uri-fn
                :40ants-doc "https://github.com/40ants/doc")))))
