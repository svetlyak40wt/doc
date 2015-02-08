<a name='x-28MGL-PAX-3A-40MGL-PAX-MANUAL-20MGL-PAX-3ASECTION-29'></a>

# PAX Manual

## Table of Contents

- [1 mgl-pax ASDF System Details][4918]
- [2 Background][84ee]
- [3 Tutorial][aa52]
- [4 Emacs Integration][eff4]
- [5 Basics][8059]
- [6 Markdown Support][d58f]
    - [6.1 Indentation][4336]
    - [6.2 Syntax highlighting][32ac]
- [7 Documentation Printer Variables][e2a1]
- [8 Locative Types][1fbb]
- [9 Extension API][8ed9]
    - [9.1 Locatives and References][d023]
    - [9.2 Adding New Object Types][5161]
    - [9.3 Reference Based Extensions][00f0]
    - [9.4 Sections][be22]
- [10 Transcripts][7a32]
    - [10.1 Transcribing with Emacs][c694]
    - [10.2 Transcript API][bf16]

###### \[in package MGL-PAX\]
<a name='x-28-22mgl-pax-22-20ASDF-2FSYSTEM-3ASYSTEM-29'></a>

## 1 mgl-pax ASDF System Details

- Version: 0.0.2
- Description: Exploratory programming tool and documentation
  generator.
- Licence: MIT, see COPYING.
- Author: Gábor Melis
- Mailto: [mega@retes.hu](mailto:mega@retes.hu)
- Homepage: [http://quotenil.com](http://quotenil.com)

<a name='x-28MGL-PAX-3A-40MGL-PAX-BACKGROUND-20MGL-PAX-3ASECTION-29'></a>

## 2 Background

As a user, I frequently run into documentation that's incomplete
and out of date, so I tend to stay in the editor and explore the
code by jumping around with SLIME's [`M-.`][SLIME-M-.]. As a library
author, I spend a great deal of time polishing code, but precious
little writing documentation.

[SLIME-M-.]: http://common-lisp.net/project/slime/doc/html/Finding-definitions.html#Finding-definitions 

In fact, I rarely write anything more comprehensive than docstrings
for exported stuff. Writing docstrings feels easier than writing a
separate user manual and they are always close at hand during
development. The drawback of this style is that users of the library
have to piece the big picture together themselves.

That's easy to solve, I thought, let's just put all the narrative
that holds docstrings together in the code and be a bit like a
Literate Programming weenie turned inside out. The original
prototype which did almost everything I wanted was this:

    (defmacro defsection (name docstring)
      `(defun ,name () ,docstring))

Armed with [`DEFSECTION`][2863], I soon found myself organizing code following
the flow of user level documentation and relegated comments to
implementational details entirely. However, some portions of
[`DEFSECTION`][2863] docstrings were just listings of all the functions,
macros and variables related to the narrative, and this list was
effectively repeated in the `DEFPACKAGE` form complete with little
comments that were like section names. A clear violation of
[OAOO][oaoo], one of them had to go, so [`DEFSECTION`][2863] got a list of
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
(defsection @mgl-pax-introduction ()
  "A single line for one man ..."
  (foo class)
  (bar function))
```

After a bit of elisp hacking, `M-.` was smart enough to disambiguate
based on the locative found in the vicinity of the symbol and
everything was good for a while.

Then I realized that sections could refer to other sections if there
were a [`SECTION`][2cf1] locative. Going down that path, I soon began to feel
the urge to generate pretty documentation as all the necessary
information was manifest in the [`DEFSECTION`][2863] forms. The design
constraint imposed on documentation generation was that following
the typical style of upcasing symbols in docstrings there should be
no need to explicitly mark up links: if `M-.` works, then the
documentation generator shall also be able find out what's being
referred to.

I settled on [Markdown][markdown] as a reasonably non-intrusive
format, and a few thousand lines later PAX was born.

[markdown]: https://daringfireball.net/projects/markdown/ 


<a name='x-28MGL-PAX-3A-40MGL-PAX-TUTORIAL-20MGL-PAX-3ASECTION-29'></a>

## 3 Tutorial

PAX provides an extremely poor man's Explorable Programming
environment. Narrative primarily lives in so called sections that
mix markdown docstrings with references to functions, variables,
etc, all of which should probably have their own docstrings.

The primary focus is on making code easily explorable by using
SLIME's `M-.` (`slime-edit-definition`). See how to enable some
fanciness in [Emacs Integration][eff4]. Generating documentation
from sections and all the referenced items in Markdown or HTML
format is also implemented.

With the simplistic tools provided, one may accomplish similar
effects as with Literate Programming, but documentation is generated
from code, not vice versa and there is no support for chunking yet.
Code is first, code must look pretty, documentation is code.

In typical use, PAX packages have no `:EXPORT`'s defined. Instead the
[`DEFINE-PACKAGE`][c98c] form gets a docstring which may mention section
names (defined with [`DEFSECTION`][2863]). When the code is loaded into the
lisp, pressing `M-.` in SLIME on the name of the section will take
you there. Sections can also refer to other sections, packages,
functions, etc and you can keep exploring.

Here is an example of how it all works together:

```commonlisp
(mgl-pax:define-package :foo-random
  (:documentation "This package provides various utilities for
  random. See FOO-RANDOM:@FOO-RANDOM-MANUAL.")
  (:use #:common-lisp #:mgl-pax))

(in-package :foo-random)

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

More fancy markdown or html output with automatic markup and linking
of uppercase symbol names found in docstrings, section numbering,
table of contents, etc is possible by calling the [`DOCUMENT`][1eb8] function.

*One can even generate documentation for different, but related
libraries at the same time with the output going to different files,
but with cross-page links being automatically added for symbols
mentioned in docstrings.* For a complete example of how to generate
HTML with multiple pages, see `src/doc.lisp`.

Note how `(VARIABLE *FOO-STATE*)` in the [`DEFSECTION`][2863] form both
exports `*FOO-STATE*` and includes its documentation in
`@FOO-RANDOM-MANUAL`. The symbols [`VARIABLE`][474c] and [`FUNCTION`][3023] are just two
instances of 'locatives' which are used in [`DEFSECTION`][2863] to refer to
definitions tied to symbols. See [Locative Types][1fbb].

The transcript in the code block tagged with `cl-transcript` is
automatically checked for up-to-dateness. See
[Transcripts][7a32].

<a name='x-28MGL-PAX-3A-40MGL-PAX-EMACS-INTEGRATION-20MGL-PAX-3ASECTION-29'></a>

## 4 Emacs Integration

Integration into SLIME's `M-.` (`slime-edit-definition`) allows one
to visit the source location of the thing that's identified by a
symbol and the locative before or after the symbol in a buffer. With
this extension, if a locative is the previous or the next expression
around the symbol of interest, then `M-.` will go straight to the
definition which corresponds to the locative. If that fails, `M-.`
will try to find the definitions in the normal way which may involve
popping up an xref buffer and letting the user interactively select
one of possible definitions.

*Note that the this feature is implemented in terms of
`SWANK-BACKEND:FIND-SOURCE-LOCATION` and
`SWANK-BACKEND:FIND-DEFINITIONS` whose support varies across the Lisp
implementations.*

In the following examples, pressing `M-.` when the cursor is on one
of the characters of `FOO` or just after `FOO`, will visit the
definition of function `FOO`:

    function foo
    foo function
    (function foo)
    (foo function)

In particular, references in a [`DEFSECTION`][2863] form are in (`SYMBOL`
[`LOCATIVE`][76b5]) format so `M-.` will work just fine there.

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
initialization file (or loading `src/pax.el`):

<a name='x-28MGL-PAX-3APAX-2EEL-20-28MGL-PAX-3AINCLUDE-20-23P-22-2Fhome-2Fmega-2Fown-2Fmgl-pax-2Fsrc-2Fpax-2Eel-22-20-3AHEADER-NL-20-22-60-60-60elisp-22-20-3AFOOTER-NL-20-22-60-60-60-22-29-29'></a>

```elisp
;;; MGL-PAX M-. integration

(defun slime-edit-locative-definition (name &optional where)
  (or (slime-locate-definition name (slime-locative-before))
      (slime-locate-definition name (slime-locative-after))
      (slime-locate-definition name (slime-locative-after-in-brackets))
      ;; support "foo function" and "function foo" syntax in
      ;; interactive use
      (let ((pos (cl-position ?\s name)))
        (when pos
          (or (slime-locate-definition (cl-subseq name 0 pos)
                                       (cl-subseq name (1+ pos)))
              (slime-locate-definition (cl-subseq name (1+ pos))
                                       (cl-subseq name 0 pos)))))))

(defun slime-locative-before ()
  (ignore-errors (save-excursion
                   (slime-beginning-of-symbol)
                   (slime-last-expression))))

(defun slime-locative-after ()
  (ignore-errors (save-excursion
                   (slime-end-of-symbol)
                   (slime-forward-sexp)
                   (slime-last-expression))))

(defun slime-locative-after-in-brackets ()
  (ignore-errors (save-excursion
                   (slime-end-of-symbol)
                   (skip-chars-forward "`" (+ (point) 1))
                   (when (and (= 1 (skip-chars-forward "\\]" (+ (point) 1)))
                              (= 1 (skip-chars-forward "\\[" (+ (point) 1))))
                     (buffer-substring-no-properties
                      (point)
                      (progn (search-forward "]" nil (+ (point) 1000))
                             (1- (point))))))))

(defun slime-locate-definition (name locative)
  (when locative
    (let ((location
           (slime-eval
            ;; Silently fail if mgl-pax is not loaded.
            `(cl:when (cl:find-package :mgl-pax)
                      (cl:funcall
                       (cl:find-symbol
                        (cl:symbol-name :locate-definition-for-emacs) :mgl-pax)
                       ,name ,locative)))))
      (when (and (consp location)
                 (not (eq (car location) :error)))
        (slime-edit-definition-cont
         (list (make-slime-xref :dspec `(,name)
                                :location location))
         "dummy name"
         where)))))

(add-hook 'slime-edit-definition-hooks 'slime-edit-locative-definition)
```

<a name='x-28MGL-PAX-3A-40MGL-PAX-BASICS-20MGL-PAX-3ASECTION-29'></a>

## 5 Basics

Now let's examine the most important pieces in detail.

<a name='x-28MGL-PAX-3ADEFSECTION-20MGL-PAX-3AMACRO-29'></a>

- [macro] **DEFSECTION** *NAME (&KEY (PACKAGE '\*PACKAGE\*) (READTABLE '\*READTABLE\*) (EXPORT T) TITLE (DISCARD-DOCUMENTATION-P \*DISCARD-DOCUMENTATION-P\*)) &BODY ENTRIES*

    Define a documentation section and maybe export referenced symbols.
    A bit behind the scenes, a global variable with `NAME` is defined and
    is bound to a [`SECTION`][aee8] object. By convention, section names
    start with the character `@`. See [Tutorial][aa52] for an example.
    
    `ENTRIES` consists of docstrings and references. Docstrings are
    arbitrary strings in markdown format, references are defined in the
    form:
    
        (symbol locative)
    
    For example, `(FOO FUNCTION)` refers to the function `FOO`, `(@BAR
    SECTION)` says that `@BAR` is a subsection of this
    one. `(BAZ (METHOD () (T T T)))` refers to the default method of the
    three argument generic function `BAZ`. `(FOO FUNCTION)` is
    equivalent to `(FOO (FUNCTION))`.
    
    A locative in a reference can either be a symbol or it can be a list
    whose `CAR` is a symbol. In either case, the symbol is the called the
    type of the locative while the rest of the elements are the locative
    arguments. See [Locative Types][1fbb] for the list of locative
    types available out of the box.
    
    The same symbol can occur multiple times in a reference, typically
    with different locatives, but this is not required.
    
    The references are not looked up (see [`RESOLVE`][e0d7] in the
    [Extension API][8ed9]) until documentation is generated, so it is
    allowed to refer to things yet to be defined.
    
    If `EXPORT` is true (the default), the referenced symbols and `NAME` are
    candidates for exporting. A candidate symbol is exported if
    
    - it is accessible in `PACKAGE` (it's not `OTHER-PACKAGE:SOMETHING`)
      and
    
    - there is a reference to it in the section being defined with a
      locative whose type is approved by [`EXPORTABLE-LOCATIVE-TYPE-P`][96c5].
    
    See [`DEFINE-PACKAGE`][c98c] if you use the export feature. The idea with
    confounding documentation and exporting is to force documentation of
    all exported symbols.
    
    When `DISCARD-DOCUMENTATION-P` (defaults to [`*DISCARD-DOCUMENTATION-P*`][d259])
    is true, `ENTRIES` will not be recorded to save memory.

<a name='x-28MGL-PAX-3A-2ADISCARD-DOCUMENTATION-P-2A-20VARIABLE-29'></a>

- [variable] **\*DISCARD-DOCUMENTATION-P\*** *NIL*

    The default value of [`DEFSECTION`][2863]'s `DISCARD-DOCUMENTATION-P` argument.
    One may want to set `*DISCARD-DOCUMENTATION-P*` to true before
    building a binary application.

<a name='x-28MGL-PAX-3ADEFINE-PACKAGE-20MGL-PAX-3AMACRO-29'></a>

- [macro] **DEFINE-PACKAGE** *PACKAGE &REST OPTIONS*

    This is like `CL:DEFPACKAGE` but silences warnings and errors
    signaled when the redefined package is at variance with the current
    state of the package. Typically this situation occurs when symbols
    are exported by calling `EXPORT` (as is the case with [`DEFSECTION`][2863]) as
    opposed to adding `:EXPORT` forms to the `DEFPACKAGE` form and the
    package definition is reevaluated. See the section on [package
    variance](http://www.sbcl.org/manual/#Package-Variance) in the SBCL
    manual.
    
    The bottom line is that if you rely on [`DEFSECTION`][2863] to do the
    exporting, then you'd better use [`DEFINE-PACKAGE`][c98c].

<a name='x-28MGL-PAX-3ADOCUMENT-20FUNCTION-29'></a>

- [function] **DOCUMENT** *OBJECT &KEY STREAM PAGES (FORMAT :MARKDOWN)*

    Write `OBJECT` in `FORMAT` to `STREAM` diverting some output to `PAGES`.
    `FORMAT` can be anything [3BMD][3bmd] supports which is
    currently `:MARKDOWN`, `:HTML` and `:PLAIN`. `STREAM` may be a stream
    object, `T` or `NIL` as with `CL:FORMAT`.
    
    Most often, this function is called on section objects
    like `(DOCUMENT @MGL-PAX-MANUAL)`, but it supports all kinds of
    objects for which [`DOCUMENT-OBJECT`][a05e] is defined. To look up the
    documentation of function [`DOCUMENT`][1eb8]:
    
        (document #'document)
    
    To generate the documentation for separate libraries with automatic
    cross-links:
    
        (document (list @cube-manual @mat-manual))
    
    Note that not only first class objects can have documentation. For
    instance, variables and deftypes are not represented by objects.
    That's why `CL:DOCUMENTATION` has a `DOC-TYPE` argument. [`DOCUMENT`][1eb8] does
    not have anything like that, instead it relies on [`REFERENCE`][cc37] objects
    to carry the extra information. We are going to see later how
    references and locatives work. Until then, here is an example on how
    to look up the documentation of type `FOO`:
    
        (document (locate 'foo 'type))
    
    One can call `DESCRIBE` on [`SECTION`][aee8] objects to get
    documentation in markdown format with less markup than the default.
    See [`DESCRIBE-OBJECT`][df39] `(METHOD () (SECTION T))`.
    
    There are quite a few special variables that affect how output is
    generated, see [Documentation Printer Variables][e2a1].
    
    The rest of this description deals with how to generate multiple
    pages.
    
    The `PAGES` argument is to create multi-page documents by routing some
    of the generated output to files, strings or streams. `PAGES` is a
    list of page specification elements. A page spec is a plist with
    keys `:OBJECTS`, `:OUTPUT`, `:URI-FRAGMENT`, `:HEADER-FN` and `:FOOTER-FN`.
    `OBJECTS` is a list of objects (references are allowed but not
    required) whose documentation is to be sent to `OUTPUT`. `OUTPUT`
    can be a number things:
    
    - If it's a list whose first element is a string or a pathname, then
      output will be sent to the file denoted by that and the rest of
      the elements of the list are passed on as arguments to `CL:OPEN`.
      One extra keyword argument is `:ENSURE-DIRECTORIES-EXIST`. If it's
      true, `ENSURE-DIRECTORIES-EXIST` will be called on the pathname
      before it's opened.
    
    - If it's `NIL`, then output will be collected in a string.
    
    - If it's `T`, then output will be sent to `*STANDARD-OUTPUT*`.
    
    - If it's a stream, then output will be sent to that stream.
    
    If some pages are specified, [`DOCUMENT`][1eb8] returns a list of designators
    for generated output. If a page whose `OUTPUT` refers to a file that
    was created (which doesn't happen if nothing would be written to
    it), then the corresponding pathname is included in the list. For
    strings the string itself, while for streams the stream object is
    included in the list. This way it's possible to write some pages to
    files and some to strings and have the return value indicate what
    was created. The output designators in the returned list are ordered
    by creation time.
    
    If no `PAGES` are specified, [`DOCUMENT`][1eb8] returns a single pathname,
    string or stream object according to the value of the `STREAM`
    argument.
    
    Note that even if `PAGES` is specified, `STREAM` acts as a catch all
    taking the generated documentation for references not claimed by any
    pages. Also, the filename, string or stream corresponding to `STREAM`
    is always the first element in list of generated things that is the
    return value.
    
    `HEADER-FN`, if not `NIL`, is a function of a single stream argument
    which is called just before the first write to the page.
    Since `:FORMAT` `:HTML` only generates HTML fragments, this makes it
    possible to print arbitrary headers, typically setting the title,
    css stylesheet, or charset.
    
    `FOOTER-FN` is similar to `HEADER-FN`, but it's called after the last
    write to the page. For HTML, it typically just closes the body.
    
    Finally, `URI-FRAGMENT` is a string such as `"doc/manual.html"` that
    specifies where the page will be deployed on a webserver. It defines
    how links between pages will look. If it's not specified and `OUTPUT`
    refers to a file, then it defaults to the name of the file. If
    `URI-FRAGMENT` is `NIL`, then no links will be made to or from that
    page.
    
    It may look something like this:
    
    ```commonlisp
    `((;; The section about SECTIONs and everything below it ...
       :objects (,@mgl-pax-sections)
       ;; ... is so boring that it's not worth the disk space, so
       ;; send it to a string.
       :output (nil)
       ;; Explicitly tell other pages not to link to these guys.
       :uri-fragment nil)
      ;; Send the @MGL-PAX-EXTENSIONS section and everything reachable
      ;; from it ...
      (:objects (,@mgl-pax-extension-api)
       ;; ... to build/tmp/pax-extension-api.html.
       :output ("build/tmp/pax-extension-api.html")
       ;; However, on the web server html files will be at this
       ;; location relative to some common root, so override the
       ;; default:
       :uri-fragment "doc/dev/pax-extension-api.html"
       ;; Set html page title, stylesheet, charset.
       :header-fn 'write-html-header
       ;; Just close the body.
       :footer-fn 'write-html-footer)
      (:objects (,@mgl-pax-manual)
       :output ("build/tmp/manual.html")
       ;; Links from the extension api page to the manual page will
       ;; be to ../user/pax-manual#<anchor>, while links going to
       ;; the opposite direction will be to
       ;; ../dev/pax-extension-api.html#<anchor>.
       :uri-fragment "doc/user/pax-manual.html"
       :header-fn 'write-html-header
       :footer-fn 'write-html-footer))
    ```


<a name='x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-SUPPORT-20MGL-PAX-3ASECTION-29'></a>

## 6 Markdown Support

The [Markdown][markdown] in docstrings is processed with the
[3BMD][3bmd] library.

<a name='x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-INDENTATION-20MGL-PAX-3ASECTION-29'></a>

### 6.1 Indentation

Docstrings can be indented in any of the usual styles. PAX
normalizes indentation by converting:

    (defun foo ()
      "This is
      indented
      differently")

to

    (defun foo ()
      "This is
    indented
    differently")

See [`DOCUMENT-OBJECT`][d7eb] for the details.

<a name='x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-SYNTAX-HIGHLIGHTING-20MGL-PAX-3ASECTION-29'></a>

### 6.2 Syntax highlighting

For syntax highlighting, github's [fenced code
blocks][fenced-code-blocks] markdown extension to mark up code
blocks with triple backticks is enabled so all you need to do is
write:

    ```elisp
    (defun foo ())
    ```

to get syntactically marked up HTML output. Copy `doc/style.css`
from PAX and you are set. The language tag, `elisp` in this example,
is optional and defaults to `common-lisp`.

See the documentation of [3BMD][3bmd] and [colorize][colorize] for
the details.

[3bmd]: https://github.com/3b/3bmd 

[colorize]: https://github.com/redline6561/colorize/ 

[fenced-code-blocks]: https://help.github.com/articles/github-flavored-markdown#fenced-code-blocks 


<a name='x-28MGL-PAX-3A-40MGL-PAX-DOCUMENTATION-PRINTER-VARIABLES-20MGL-PAX-3ASECTION-29'></a>

## 7 Documentation Printer Variables

Docstrings are assumed to be in markdown format and they are pretty
much copied verbatim to the documentation subject to a few knobs
described below.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-UPPERCASE-IS-CODE-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-UPPERCASE-IS-CODE\*** *T*

    When true, words with at least three characters and no lowercase
    characters naming an interned symbol are assumed to be code as if
    they were marked up with backticks which is especially useful when
    combined with [`*DOCUMENT-LINK-CODE*`][8082]. For example, this docstring:
    
        "`FOO` and FOO."
    
    is equivalent to this:
    
        "`FOO` and `FOO`."
    
    iff `FOO` is an interned symbol. To suppress this behavior, add a
    backslash to the beginning of the symbol or right after the leading
    \* if it would otherwise be parsed as markdown emphasis:
    
        "\\MGL-PAX *\\DOCUMENT-NORMALIZE-PACKAGES*"
    
    The number of backslashes is doubled above because that's how the
    example looks in a docstring. Note that the backslash is discarded
    even if `*DOCUMENT-UPPERCASE-IS-CODE*` is false.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-LINK-CODE-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-LINK-CODE\*** *T*

    When true, during the process of generating documentation for a
    [`SECTION`][aee8], html anchors are added before the documentation of
    every reference that's not to a section. Also, markdown style
    reference links are added when a piece of inline code found in a
    docstring refers to a symbol that's referenced by one of the
    sections being documented. Assuming `BAR` is defined, the
    documentation for:
    
    ```commonlisp
    (defsection @foo
      (foo function)
      (bar function))
    
    (defun foo (x)
      "Calls `BAR` on `X`."
      (bar x))
    ```
    
    would look like this:
    
        - [function] FOO X
        
            Calls [`BAR`][1] on `X`.
    
    Instead of `BAR`, one can write `[bar][]` or ``[`bar`][]`` as well.
    Since symbol names are parsed according to `READTABLE-CASE`, character
    case rarely matters.
    
    Now, if `BAR` has references with different locatives:
    
    ```commonlisp
    (defsection @foo
      (foo function)
      (bar function)
      (bar type))
    
    (defun foo (x)
      "Calls `BAR` on `X`."
      (bar x))
    ```
    
    then documentation would link to all interpretations:
    
        - [function] FOO X
        
            Calls `BAR`([`1`][link-id-1] [`2`][link-id-2]) on `X`.
    
    This situation occurs in PAX with `SECTION`([`0`][aee8] [`1`][2cf1]) which is both a class (see
    [`SECTION`][aee8]) and a locative type denoted by a symbol (see
    [`SECTION`][2cf1]). Back in the example above, clearly,
    there is no reason to link to type `BAR`, so one may wish to select
    the function locative. There are two ways to do that. One is to
    specify the locative explicitly as the id of a reference link:
    
        "Calls [BAR][function] on X."
    
    However, if in the text there is a locative immediately before or
    after the symbol, then that locative is used to narrow down the
    range of possibilities. This is similar to what the `M-.` extension
    does. In a nutshell, if `M-.` works without questions then the
    documentation will contain a single link. So this also works without
    any markup:
    
        "Calls function `BAR` on X."
    
    This last option needs backticks around the locative if it's not a
    single symbol.
    
    Note that [`*DOCUMENT-LINK-CODE*`][8082] can be combined with
    [`*DOCUMENT-UPPERCASE-IS-CODE*`][8be2] to have links generated for
    uppercase names with no quoting required.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-LINK-SECTIONS-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-LINK-SECTIONS\*** *T*

    When true, html anchors are generated before the heading of
    sections which allows the table of contents to contain links and
    also code-like references to sections (like `@FOO-MANUAL`) to be
    translated to links with the section title being the name of the
    link.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-MIN-LINK-HASH-LENGTH-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-MIN-LINK-HASH-LENGTH\*** *4*

    Recall that markdown reference style links (like `[label][id]`) are
    used for linking to sections and code. It is desirable to have ids
    that are short to maintain legibility of the generated markdown, but
    also stable to reduce the spurious diffs in the generated
    documentation which can be a pain in a version control system.
    
    Clearly, there is a tradeoff here. This variable controls how many
    characters of the md5 sum of the full link id (the reference as a
    string) are retained. If collisions are found due to the low number
    of characters, then the length of the hash of the colliding
    reference is increased.
    
    This variable has no effect on the html generated from markdown, but
    it can make markdown output more readable.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-MARK-UP-SIGNATURES-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-MARK-UP-SIGNATURES\*** *T*

    When true, some things such as function names and arglists are
    rendered as bold and italic.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-MAX-NUMBERING-LEVEL-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-MAX-NUMBERING-LEVEL\*** *3*

    A non-negative integer. In their hierarchy, sections on levels less
    than this value get numbered in the format of `3.1.2`. Setting it to
    0 turns numbering off.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-MAX-TABLE-OF-CONTENTS-LEVEL-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-MAX-TABLE-OF-CONTENTS-LEVEL\*** *3*

    A non-negative integer. Top-level sections are given a table of
    contents which includes a nested tree of section titles whose depth
    is limited by this value. Setting it to 0 turns generation of the
    table of contents off. If [`*DOCUMENT-LINK-SECTIONS*`][3fef] is true, then the
    table of contents will link to the sections.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-TEXT-NAVIGATION-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-TEXT-NAVIGATION\*** *NIL*

    If true, then before each heading a line is printed with links to
    the previous, parent and next section. Needs
    [`*DOCUMENT-LINK-SECTIONS*`][3fef] to be on to work.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-FANCY-HTML-NAVIGATION-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-FANCY-HTML-NAVIGATION\*** *T*

    If true and the output format is HTML, then headings get a
    navigation component that consists of links to the previous, parent,
    next section and a permalink. This component is normally hidden, it
    is visible only when the mouse is over the heading. Needs
    [`*DOCUMENT-LINK-SECTIONS*`][3fef] to be on to work.

<a name='x-28MGL-PAX-3A-2ADOCUMENT-NORMALIZE-PACKAGES-2A-20VARIABLE-29'></a>

- [variable] **\*DOCUMENT-NORMALIZE-PACKAGES\*** *T*

    If true, symbols are printed relative to [`SECTION-PACKAGE`][87c7] of the
    innermost containing section or with full package names if there is
    no containing section. To eliminate ambiguity `[in package ...]`
    messages are printed right after the section heading if necessary.
    If false, symbols are always printed relative to the current
    package.

<a name='x-28MGL-PAX-3A-40MGL-PAX-LOCATIVE-TYPES-20MGL-PAX-3ASECTION-29'></a>

## 8 Locative Types

These are the locatives type supported out of the box. As all
locative types, they are symbols and their names should make it
obvious what kind of things they refer to. Unless otherwise noted,
locatives take no arguments.

<a name='x-28ASDF-2FSYSTEM-3ASYSTEM-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **ASDF/SYSTEM:SYSTEM**

    Refers to an asdf system. The generated documentation will include
    meta information extracted from the system definition. This also
    serves as an example of a symbol that's not accessible in the
    current package and consequently is not exported.

<a name='x-28MGL-PAX-3ASECTION-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **SECTION**

    Refers to a section defined by [`DEFSECTION`][2863].

<a name='x-28VARIABLE-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **VARIABLE** *&OPTIONAL INITFORM*

    Refers to a global special variable. `INITFORM`, or if not specified,
    the global value of the variable is included in the documentation.

<a name='x-28MGL-PAX-3ACONSTANT-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **CONSTANT** *&OPTIONAL INITFORM*

    Refers to a `DEFCONSTANT`. `INITFORM`, or if not specified,
    the value of the constant is included in the documentation.

<a name='x-28MGL-PAX-3AMACRO-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **MACRO**

<a name='x-28COMPILER-MACRO-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **COMPILER-MACRO**

<a name='x-28FUNCTION-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **FUNCTION**

    Note that the arglist in the generated documentation depends on
    the quality of `SWANK-BACKEND:ARGLIST`. It may be that default
    values of optional and keyword arguments are missing.

<a name='x-28GENERIC-FUNCTION-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **GENERIC-FUNCTION**

<a name='x-28METHOD-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **METHOD** *METHOD-QUALIFIERS METHOD-SPECIALIZERS*

    See `CL:FIND-METHOD` for the description of the arguments.
    To refer to the default method of the three argument generic
    function `FOO`:
    
        (foo (method () (t t t)))


<a name='x-28MGL-PAX-3AACCESSOR-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **ACCESSOR** *CLASS-NAME*

    To refer to an accessor named `FOO-SLOT` of class
    `FOO`:
    
        (foo-slot (accessor foo))


<a name='x-28MGL-PAX-3AREADER-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **READER** *CLASS-NAME*

    To refer to a reader named `FOO-SLOT` of class
    `FOO`:
    
        (foo-slot (reader foo))


<a name='x-28MGL-PAX-3AWRITER-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **WRITER** *CLASS-NAME*

    To refer to a writer named `FOO-SLOT` of class
    `FOO`:
    
        (foo-slot (writer foo))


<a name='x-28MGL-PAX-3ASTRUCTURE-ACCESSOR-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **STRUCTURE-ACCESSOR**

    This is a synonym of [`FUNCTION`][3023] with the difference that the often
    ugly and certainly uninformative lambda list will not be printed.

<a name='x-28CLASS-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **CLASS**

<a name='x-28CONDITION-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **CONDITION**

<a name='x-28TYPE-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **TYPE**

    `TYPE` can refer to classes as well, but it's better style to use the
    more specific [`CLASS`][6e37] locative type for that. Another difference to
    [`CLASS`][6e37] is that an attempt is made at printing the arguments of type
    specifiers.

<a name='x-28PACKAGE-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **PACKAGE**

<a name='x-28MGL-PAX-3ADISLOCATED-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **DISLOCATED**

    Refers to a symbol in a non-specific context. Useful for preventing
    autolinking. For example, if there is a function called `FOO` then
    
        `FOO`
    
    will be linked to (if [`*DOCUMENT-LINK-CODE*`][8082]) its definition. However,
    
        [`FOO`][dislocated]
    
    will not be. On a dislocated locative [`LOCATE`][b2be] always fails with a
    [`LOCATE-ERROR`][2285] condition.

<a name='x-28MGL-PAX-3ALOCATIVE-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **LOCATIVE** *LAMBDA-LIST*

    This is the locative for locatives. When `M-.` is pressed on
    [`VARIABLE`][474c] in `(VARIABLE LOCATIVE)`, this is what makes it possible
    to land at the `(DEFINE-LOCATIVE-TYPE VARIABLE ...)` form.
    Similarly, `(LOCATIVE LOCATIVE)` leads to this very definition.

<a name='x-28MGL-PAX-3AINCLUDE-20MGL-PAX-3ALOCATIVE-29'></a>

- [locative] **INCLUDE** *SOURCE &KEY LINE-PREFIX HEADER FOOTER HEADER-NL FOOTER-NL*

    Refers to a region of a file. `SOURCE` can be a string or a
    pathname in which case the whole file is being pointed to or it can
    explicitly supply `START`, `END` locatives. `INCLUDE` is typically used to
    include non-lisp files in the documentation (say markdown or elisp
    as in the next example) or regions of lisp source files. This can
    reduce clutter and duplication.
    
    ```commonlisp
    (defsection example-section ()
      (pax.el (include #.(asdf:system-relative-pathname :mgl-pax "src/pax.el")
                       :header-nl "```elisp" :footer-nl "```"))
      (foo-example (include (:start (foo function)
                             :end (end-of-foo-example variable))
                            :header-nl "```commonlisp"
                            :footer-nl "```"))
    
    (defun foo (x)
      (1+ x))
    
    ;;; Since file regions are copied verbatim, comments survive.
    (defmacro bar ())
    
    ;;; This comment is the last thing in FOO-EXAMPLE's
    ;;; documentation since we use the dummy END-OF-FOO-EXAMPLE
    ;;; variable to mark the end location.
    (defvar end-of-foo-example)
    
    ;;; More irrelevant code follows.
    ```
    
    In the above example, pressing `M-.` on [`PAX.EL`][ad5a] will open the
    `src/pax.el` file and put the cursor on its first character. `M-.`
    on `FOO-EXAMPLE` will go to the source location of the `(asdf:system
    locative)` locative.
    
    When documentation is generated, the entire [`pax.el`][ad5a] file is
    included in the markdown surrounded by the strings given as
    `HEADER-NL` and `FOOTER-NL` (if any). The trailing newline character is
    assumed implicitly. If that's undesirable, then use `HEADER` and
    `FOOTER` instead. The documentation of `FOO-EXAMPLE` will be the
    region of the file from the source location of the `START`
    locative (inclusive) to the source location of the `END`
    locative (exclusive). `START` and `END` default to the beginning and end
    of the file, respectively.
    
    Note that the file of the source location of `:START` and `:END` must be
    the same. If `SOURCE` is pathname designator, then it must be absolute
    so that the locative is context independent.
    
    Finally, if specified `LINE-PREFIX` is a string that's prepended to
    each line included in the documentation. For example, a string of
    four spaces makes markdown think it's a code block.

<a name='x-28MGL-PAX-3A-40MGL-PAX-EXTENSION-API-20MGL-PAX-3ASECTION-29'></a>

## 9 Extension API

<a name='x-28MGL-PAX-3A-40MGL-PAX-LOCATIVES-AND-REFERENCES-20MGL-PAX-3ASECTION-29'></a>

### 9.1 Locatives and References

While Common Lisp has rather good introspective abilities, not
everything is first class. For example, there is no object
representing the variable defined with `(DEFVAR
FOO)`. `(MAKE-REFERENCE 'FOO 'VARIABLE)` constructs a [`REFERENCE`][cc37] that
captures the path to take from an object (the symbol `FOO`) to an
entity of interest (for example, the documentation of the variable).
The path is called the locative. A locative can be applied to an
object like this:

    (locate 'foo 'variable)

which will return the same reference as `(MAKE-REFERENCE 'FOO
'VARIABLE)`. Operations need to know how to deal with references
which we will see in [`LOCATE-AND-COLLECT-REACHABLE-OBJECTS`][7a11],
[`LOCATE-AND-DOCUMENT`][6c17] and [`LOCATE-AND-FIND-SOURCE`][e9e9].

Naturally, `(LOCATE 'FOO 'FUNCTION)` will simply return `#'FOO`, no
need to muck with references when there is a perfectly good object.

<a name='x-28MGL-PAX-3ALOCATE-20FUNCTION-29'></a>

- [function] **LOCATE** *OBJECT LOCATIVE &KEY (ERRORP T)*

    Follow `LOCATIVE` from `OBJECT` and return the object it leads to or a
    [`REFERENCE`][cc37] if there is no first class object corresponding to the
    location. If `ERRORP`, then a [`LOCATE-ERROR`][2285] condition is signaled when
    lookup fails.

<a name='x-28MGL-PAX-3ALOCATE-ERROR-20CONDITION-29'></a>

- [condition] **LOCATE-ERROR** *ERROR*

    Signaled by [`LOCATE`][b2be] when lookup fails and `ERRORP` is
    true.

<a name='x-28MGL-PAX-3ALOCATE-ERROR-MESSAGE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ALOCATE-ERROR-29-29'></a>

- [reader] **LOCATE-ERROR-MESSAGE** *LOCATE-ERROR* *(:MESSAGE)*

<a name='x-28MGL-PAX-3ALOCATE-ERROR-OBJECT-20-28MGL-PAX-3AREADER-20MGL-PAX-3ALOCATE-ERROR-29-29'></a>

- [reader] **LOCATE-ERROR-OBJECT** *LOCATE-ERROR* *(:OBJECT)*

<a name='x-28MGL-PAX-3ALOCATE-ERROR-LOCATIVE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ALOCATE-ERROR-29-29'></a>

- [reader] **LOCATE-ERROR-LOCATIVE** *LOCATE-ERROR* *(:LOCATIVE)*

<a name='x-28MGL-PAX-3ARESOLVE-20FUNCTION-29'></a>

- [function] **RESOLVE** *REFERENCE &KEY (ERRORP T)*

    A convenience function to [`LOCATE`][b2be] `REFERENCE`'s object with its
    locative.

<a name='x-28MGL-PAX-3AREFERENCE-20CLASS-29'></a>

- [class] **REFERENCE**

    A `REFERENCE` represents a path ([`REFERENCE-LOCATIVE`][819a])
    to take from an object ([`REFERENCE-OBJECT`][0412]).

<a name='x-28MGL-PAX-3AREFERENCE-OBJECT-20-28MGL-PAX-3AREADER-20MGL-PAX-3AREFERENCE-29-29'></a>

- [reader] **REFERENCE-OBJECT** *REFERENCE* *(:OBJECT)*

<a name='x-28MGL-PAX-3AREFERENCE-LOCATIVE-20-28MGL-PAX-3AREADER-20MGL-PAX-3AREFERENCE-29-29'></a>

- [reader] **REFERENCE-LOCATIVE** *REFERENCE* *(:LOCATIVE)*

<a name='x-28MGL-PAX-3AMAKE-REFERENCE-20FUNCTION-29'></a>

- [function] **MAKE-REFERENCE** *OBJECT LOCATIVE*

<a name='x-28MGL-PAX-3ALOCATIVE-TYPE-20FUNCTION-29'></a>

- [function] **LOCATIVE-TYPE** *LOCATIVE*

    The first element of `LOCATIVE` if it's a list. If it's a symbol then
    it's that symbol itself. Typically, methods of generic functions
    working with locatives take locative type and locative args as
    separate arguments to allow methods have eql specializers on the
    type symbol.

<a name='x-28MGL-PAX-3ALOCATIVE-ARGS-20FUNCTION-29'></a>

- [function] **LOCATIVE-ARGS** *LOCATIVE*

    The `REST` of `LOCATIVE` if it's a list. If it's a symbol then
    it's ().

<a name='x-28MGL-PAX-3A-40MGL-PAX-NEW-OBJECT-TYPES-20MGL-PAX-3ASECTION-29'></a>

### 9.2 Adding New Object Types

One may wish to make the [`DOCUMENT`][1eb8] function and `M-.` navigation
work with new object types. Extending [`DOCUMENT`][1eb8] can be done by
defining a [`DOCUMENT-OBJECT`][a05e] method. To allow these objects to be
referenced from [`DEFSECTION`][2863] a [`LOCATE-OBJECT`][acc9] method is to be defined.
Finally, for `M-.` [`FIND-SOURCE`][b417] can be specialized. Finally,
[`EXPORTABLE-LOCATIVE-TYPE-P`][96c5] may be overridden if exporting does not
makes sense. Here is a stripped down example of how all this is done
for [`ASDF:SYSTEM:`][90f2]

<a name='x-28MGL-PAX-3AASDF-EXAMPLE-20-28MGL-PAX-3AINCLUDE-20-28-3ASTART-20-28ASDF-2FSYSTEM-3ASYSTEM-20MGL-PAX-3ALOCATIVE-29-20-3AEND-20-28MGL-PAX-3A-3AEND-OF-ASDF-EXAMPLE-20VARIABLE-29-29-20-3AHEADER-NL-20-22-60-60-60commonlisp-22-20-3AFOOTER-NL-20-22-60-60-60-22-29-29'></a>

```commonlisp
(define-locative-type asdf:system ()
  "Refers to an asdf system. The generated documentation will include
  meta information extracted from the system definition. This also
  serves as an example of a symbol that's not accessible in the
  current package and consequently is not exported.")

(defmethod locate-object (symbol (locative-type (eql 'asdf:system))
                          locative-args)
  (assert (endp locative-args))
  ;; FIXME: This is slow as hell.
  (or (asdf:find-system symbol nil)
      (locate-error)))

(defmethod canonical-reference ((system asdf:system))
  (make-reference (asdf/find-system:primary-system-name system) 'asdf:system))

(defmethod document-object ((system asdf:system) stream)
  (with-heading (stream system
                        (format nil "~A ASDF System Details"
                                (asdf/find-system:primary-system-name system)))
    (flet ((foo (name fn &key type)
             (let ((value (funcall fn system)))
               (when value
                 (case type
                   ((:link)
                    (format stream "- ~A: [~A](~A)~%" name value value))
                   ((:mailto)
                    (format stream "- ~A: [~A](mailto:~A)~%"
                            name value value))
                   ((nil)
                    (format stream "- ~A: ~A~%" name value)))))))
      (foo "Version" 'asdf/component:component-version)
      (foo "Description" 'asdf/system:system-description)
      (foo "Licence" 'asdf/system:system-licence)
      (foo "Author" 'asdf/system:system-author)
      (foo "Maintainer" 'asdf/system:system-maintainer)
      (foo "Mailto" 'asdf/system:system-mailto :type :mailto)
      (foo "Homepage" 'asdf/system:system-homepage :type :link)
      (foo "Bug tracker" 'asdf/system:system-bug-tracker)
      (foo "Long description" 'asdf/system:system-long-description))))

(defmethod find-source ((system asdf:system))
  `(:location
    (:file ,(namestring (asdf/system:system-source-file system)))
    (:position 1)
    (:snippet "")))

```

<a name='x-28MGL-PAX-3ADEFINE-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29'></a>

- [macro] **DEFINE-LOCATIVE-TYPE** *LOCATIVE-TYPE LAMBDA-LIST &BODY DOCSTRING*

    Declare `LOCATIVE-TYPE` as a [`LOCATIVE`][76b5]. One gets two
    things in return: first, a place to document the format and
    semantics of `LOCATIVE-TYPE` (in `LAMBDA-LIST` and `DOCSTRING`); second,
    being able to reference `(LOCATIVE-TYPE LOCATIVE)`. For example, if
    you have:
    
    ```common-lisp
    (define-locative-type variable (&optional initform)
      "Dummy docstring.")
    ```
    
    then `(VARIABLE LOCATIVE)` refers to this form.

<a name='x-28MGL-PAX-3AEXPORTABLE-LOCATIVE-TYPE-P-20GENERIC-FUNCTION-29'></a>

- [generic-function] **EXPORTABLE-LOCATIVE-TYPE-P** *LOCATIVE-TYPE*

    Return true iff symbols in references with
    `LOCATIVE-TYPE` are to be exported by default when they occur in a
    [`DEFSECTION`][2863]. The default method returns `T`, while the methods for
    [`PACKAGE`][16ad], [`ASDF:SYSTEM`][90f2] and [`METHOD`][d71c] return `NIL`.
    
    [`DEFSECTION`][2863] calls this function to decide what symbols to export when
    its `EXPORT` argument is true.

<a name='x-28MGL-PAX-3ALOCATE-OBJECT-20GENERIC-FUNCTION-29'></a>

- [generic-function] **LOCATE-OBJECT** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS*

    Return the object `OBJECT` + locative refers to. For
    example, if `LOCATIVE-TYPE` is the symbol [`PACKAGE`][16ad], this
    returns `(FIND-PACKAGE SYMBOL)`. Signal a [`LOCATE-ERROR`][2285] condition by
    calling the [`LOCATE-ERROR`][f3b7] function if lookup fails. Signal other
    errors if the types of the argument are bad, for instance
    `LOCATIVE-ARGS` is not the empty list in the package example. If a
    [`REFERENCE`][cc37] is returned then it must be canonical in the sense that
    calling [`CANONICAL-REFERENCE`][24fc] on it will return the same reference.
    For extension only, don't call this directly.

<a name='x-28MGL-PAX-3ALOCATE-ERROR-20FUNCTION-29'></a>

- [function] **LOCATE-ERROR** *&REST FORMAT-AND-ARGS*

    Call this function to signal a [`LOCATE-ERROR`][2285] condition from a
    [`LOCATE-OBJECT`][acc9] method. `FORMAT-AND-ARGS` contains a format string and
    args suitable for `FORMAT` from which the [`LOCATE-ERROR-MESSAGE`][81be] is
    constructed. If `FORMAT-AND-ARGS` is `NIL`, then the message will be `NIL`
    too.
    
    The object and the locative are not specified, they are added by
    [`LOCATE`][b2be] when it resignals the condition.

<a name='x-28MGL-PAX-3ACANONICAL-REFERENCE-20GENERIC-FUNCTION-29'></a>

- [generic-function] **CANONICAL-REFERENCE** *OBJECT*

    Return a [`REFERENCE`][cc37] that resolves to `OBJECT`.

<a name='x-28MGL-PAX-3ACOLLECT-REACHABLE-OBJECTS-20GENERIC-FUNCTION-29'></a>

- [generic-function] **COLLECT-REACHABLE-OBJECTS** *OBJECT*

    Return a list of objects representing all things
    that would be documented in a ([`DOCUMENT`][1eb8] `OBJECT`) call. For sections
    this is simply the union of references reachable from references in
    [`SECTION-ENTRIES`][1f66]. The returned objects can be anything provided that
    [`CANONICAL-REFERENCE`][24fc] works on them. The list need not include `OBJECT`
    itself.
    
    One only has to specialize this for new container-like objects.

<a name='x-28MGL-PAX-3ACOLLECT-REACHABLE-OBJECTS-20-28METHOD-20NIL-20-28T-29-29-29'></a>

- [method] **COLLECT-REACHABLE-OBJECTS** *OBJECT*

    This default implementation returns the empty list. This means that
    nothing is reachable from `OBJECT`.

<a name='x-28MGL-PAX-3ADOCUMENT-OBJECT-20GENERIC-FUNCTION-29'></a>

- [generic-function] **DOCUMENT-OBJECT** *OBJECT STREAM*

    Write `OBJECT` (and its references recursively) in
    `FORMAT` to `STREAM`.
    
    The [`DOCUMENT`][1eb8] function calls this generic function with `LEVEL` 0,
    passing `FORMAT` on. Add methods specializing on `OBJECT` to customize
    how objects of that type are presented in the documentation.

<a name='x-28MGL-PAX-3ADOCUMENT-OBJECT-20-28METHOD-20NIL-20-28STRING-20T-29-29-29'></a>

- [method] **DOCUMENT-OBJECT** *(STRING STRING) STREAM*

    Print `STRING` verbatim to `STREAM` after cleaning up indentation.
    
    Docstrings in sources are indented in various ways which can easily
    mess up markdown. To handle the most common cases leave the first
    line alone, but from the rest of the lines strip the longest run of
    leading spaces that is common to all non-blank lines.

<a name='x-28MGL-PAX-3AFIND-SOURCE-20GENERIC-FUNCTION-29'></a>

- [generic-function] **FIND-SOURCE** *OBJECT*

    Like `SWANK:FIND-DEFINITION-FOR-THING`, but this
    one is a generic function to be extensible. In fact, the default
    implementation simply defers to `SWANK:FIND-DEFINITION-FOR-THING`.
    This function is called by `LOCATE-DEFINITION-FOR-EMACS` which lies
    behind the `M-.` extension (see [Emacs Integration][eff4]).
    
    If successful, the return value looks like this:
    
    ```commonlisp
    (:location (:file "/home/mega/own/mgl/pax/test/test.lisp")
               (:position 24) nil)
    ```
    
    The `NIL` is the source snippet which is optional. Note that position
    1 is the first character. If unsuccessful, the return values is
    like:
    
    ```commonlisp
    (:error "Unknown source location for SOMETHING")
    ```


<a name='x-28MGL-PAX-3A-40MGL-PAX-REFERENCE-BASED-EXTENSIONS-20MGL-PAX-3ASECTION-29'></a>

### 9.3 Reference Based Extensions

Let's see how to extend [`DOCUMENT`][1eb8] and `M-.` navigation if there is
no first class object to represent the thing of interest. Recall
that [`LOCATE`][b2be] returns a [`REFERENCE`][cc37] object in this case. [`DOCUMENT-OBJECT`][a05e]
and [`FIND-SOURCE`][b417] defer to [`LOCATE-AND-DOCUMENT`][6c17] and
[`LOCATE-AND-FIND-SOURCE`][e9e9] which have [`LOCATIVE-TYPE`][966a] in their argument
list for `EQL` specializing pleasure. Here is a stripped down example
of how the [`VARIABLE`][474c] locative is defined:

<a name='x-28MGL-PAX-3AVARIABLE-EXAMPLE-20-28MGL-PAX-3AINCLUDE-20-28-3ASTART-20-28VARIABLE-20MGL-PAX-3ALOCATIVE-29-20-3AEND-20-28MGL-PAX-3A-3AEND-OF-VARIABLE-EXAMPLE-20VARIABLE-29-29-20-3AHEADER-NL-20-22-60-60-60commonlisp-22-20-3AFOOTER-NL-20-22-60-60-60-22-29-29'></a>

```commonlisp
(define-locative-type variable (&optional initform)
  "Refers to a global special variable. INITFORM, or if not specified,
  the global value of the variable is included in the documentation.")

(defmethod locate-object (symbol (locative-type (eql 'variable)) locative-args)
  (assert (<= (length locative-args) 1))
  (make-reference symbol (cons locative-type locative-args)))

(defmethod locate-and-document (symbol (locative-type (eql 'variable))
                                locative-args stream)
  (destructuring-bind (&optional (initform nil initformp)) locative-args
    (format stream "- [~A] " (string-downcase locative-type))
    (print-name (prin1-to-string symbol) stream)
    (write-char #\Space stream)
    (multiple-value-bind (value unboundp) (symbol-global-value symbol)
      (print-arglist (prin1-to-string (cond (initformp initform)
                                            (unboundp "-unbound-")
                                            (t value)))
                     stream))
    (terpri stream)
    (with-dislocated-symbols ((list symbol))
      (maybe-print-docstring symbol locative-type stream))))

(defmethod locate-and-find-source (symbol (locative-type (eql 'variable))
                                   locative-args)
  (declare (ignore locative-args))
  (find-one-location (swank-backend:find-definitions symbol)
                     '("variable" "defvar" "defparameter"
                       "special-declaration")))

```

<a name='x-28MGL-PAX-3ACOLLECT-REACHABLE-OBJECTS-20-28METHOD-20NIL-20-28MGL-PAX-3AREFERENCE-29-29-29'></a>

- [method] **COLLECT-REACHABLE-OBJECTS** *(REFERENCE REFERENCE)*

    If `REFERENCE` can be resolved to a non-reference, call
    [`COLLECT-REACHABLE-OBJECTS`][1920] with it, else call
    [`LOCATE-AND-COLLECT-REACHABLE-OBJECTS`][7a11] on the object, locative-type,
    locative-args of `REFERENCE`

<a name='x-28MGL-PAX-3ALOCATE-AND-COLLECT-REACHABLE-OBJECTS-20GENERIC-FUNCTION-29'></a>

- [generic-function] **LOCATE-AND-COLLECT-REACHABLE-OBJECTS** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS*

    Called by [`COLLECT-REACHABLE-OBJECTS`][1920] on [`REFERENCE`][cc37]
    objects, this function has essentially the same purpose as its
    caller but it has different arguments to allow specializing on
    `LOCATIVE-TYPE`.

<a name='x-28MGL-PAX-3ALOCATE-AND-COLLECT-REACHABLE-OBJECTS-20-28METHOD-20NIL-20-28T-20T-20T-29-29-29'></a>

- [method] **LOCATE-AND-COLLECT-REACHABLE-OBJECTS** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS*

    This default implementation returns the empty list. This means that
    nothing is reachable from the reference.

<a name='x-28MGL-PAX-3ADOCUMENT-OBJECT-20-28METHOD-20NIL-20-28MGL-PAX-3AREFERENCE-20T-29-29-29'></a>

- [method] **DOCUMENT-OBJECT** *(REFERENCE REFERENCE) STREAM*

    If `REFERENCE` can be resolved to a non-reference, call
    [`DOCUMENT-OBJECT`][a05e] with it, else call LOCATE-AND-DOCUMENT-OBJECT on the
    object, locative-type, locative-args of `REFERENCE`

<a name='x-28MGL-PAX-3ALOCATE-AND-DOCUMENT-20GENERIC-FUNCTION-29'></a>

- [generic-function] **LOCATE-AND-DOCUMENT** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS STREAM*

    Called by [`DOCUMENT-OBJECT`][a05e] on [`REFERENCE`][cc37] objects,
    this function has essentially the same purpose as [`DOCUMENT-OBJECT`][a05e]
    but it has different arguments to allow specializing on
    `LOCATIVE-TYPE`.

<a name='x-28MGL-PAX-3AFIND-SOURCE-20-28METHOD-20NIL-20-28MGL-PAX-3AREFERENCE-29-29-29'></a>

- [method] **FIND-SOURCE** *(REFERENCE REFERENCE)*

    If `REFERENCE` can be resolved to a non-reference, call [`FIND-SOURCE`][b417]
    with it, else call [`LOCATE-AND-FIND-SOURCE`][e9e9] on the object,
    locative-type, locative-args of `REFERENCE`

<a name='x-28MGL-PAX-3ALOCATE-AND-FIND-SOURCE-20GENERIC-FUNCTION-29'></a>

- [generic-function] **LOCATE-AND-FIND-SOURCE** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS*

    Called by [`FIND-SOURCE`][b417] on [`REFERENCE`][cc37] objects, this
    function has essentially the same purpose as [`FIND-SOURCE`][b417] but it has
    different arguments to allow specializing on `LOCATIVE-TYPE`.

<a name='x-28MGL-PAX-3ALOCATE-AND-FIND-SOURCE-20-28METHOD-20NIL-20-28T-20T-20T-29-29-29'></a>

- [method] **LOCATE-AND-FIND-SOURCE** *OBJECT LOCATIVE-TYPE LOCATIVE-ARGS*

    This default implementation simply calls [`FIND-SOURCE`][b417] with `OBJECT`
    which should cover the common case of a macro expanding to, for
    instance, a defun but having its own locative type.

We have covered the basic building blocks of reference based
extensions. Now let's see how the obscure
[`DEFINE-SYMBOL-LOCATIVE-TYPE`][57cb] and
[`DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE`][68e7] macros work together to
simplify the common task of associating definition and documentation
with symbols in a certain context.

<a name='x-28MGL-PAX-3ADEFINE-SYMBOL-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29'></a>

- [macro] **DEFINE-SYMBOL-LOCATIVE-TYPE** *LOCATIVE-TYPE LAMBDA-LIST &BODY DOCSTRING*

    Similar to [`DEFINE-LOCATIVE-TYPE`][62d4] but it assumes that all things
    locatable with `LOCATIVE-TYPE` are going to be just symbols defined
    with a definer defined with [`DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE`][68e7].
    It is useful to attach documentation and source location to symbols
    in a particular context. An example will make everything clear:
    
    ```commonlisp
    (define-symbol-locative-type direction ()
      "A direction is a symbol. (After this `M-.` on `DIRECTION LOCATIVE`
      works and it can also be included in DEFSECTION forms.)")
    
    (define-definer-for-symbol-locative-type define-direction direction ()
      "With DEFINE-DIRECTION one can document how what a symbol means
      when interpreted as a direction.")
    
    (define-direction up ()
      "UP is equivalent to a coordinate delta of (0, -1).")
    ```
    
    After all this, `(UP DIRECTION)` refers to the `DEFINE-DIRECTION`
    form above.

<a name='x-28MGL-PAX-3ADEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29'></a>

- [macro] **DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE** *NAME LOCATIVE-TYPE &BODY DOCSTRING*

    Define a macro with `NAME` which can be used to attach documentation,
    a lambda-list and source location to a symbol in the context of
    `LOCATIVE-TYPE`. The defined macro's arglist is (`SYMBOL` `LAMBDA-LIST`
    `&OPTIONAL` `DOCSTRING`). `LOCATIVE-TYPE` is assumed to have been defined
    with [`DEFINE-SYMBOL-LOCATIVE-TYPE`][57cb].

<a name='x-28MGL-PAX-3A-40MGL-PAX-SECTIONS-20MGL-PAX-3ASECTION-29'></a>

### 9.4 Sections

[`Section`][aee8] objects rarely need to be dissected since
[`DEFSECTION`][2863] and [`DOCUMENT`][1eb8] cover most needs. However, it is plausible
that one wants to subclass them and maybe redefine how they are
presented.

<a name='x-28MGL-PAX-3ASECTION-20CLASS-29'></a>

- [class] **SECTION**

    [`DEFSECTION`][2863] stores its `NAME`, `TITLE` and `ENTRIES` in
    [`SECTION`][aee8] objects.

<a name='x-28MGL-PAX-3ASECTION-NAME-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29'></a>

- [reader] **SECTION-NAME** *SECTION* *(:NAME)*

    The name of the global variable whose value is
    this section object.

<a name='x-28MGL-PAX-3ASECTION-PACKAGE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29'></a>

- [reader] **SECTION-PACKAGE** *SECTION* *(:PACKAGE)*

    `*PACKAGE*` will be bound to this package when
    generating documentation for this section.

<a name='x-28MGL-PAX-3ASECTION-READTABLE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29'></a>

- [reader] **SECTION-READTABLE** *SECTION* *(:READTABLE)*

    `*READTABLE*` will be bound to this when generating
    documentation for this section.

<a name='x-28MGL-PAX-3ASECTION-TITLE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29'></a>

- [reader] **SECTION-TITLE** *SECTION* *(:TITLE)*

    Used in generated documentation.

<a name='x-28MGL-PAX-3ASECTION-ENTRIES-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29'></a>

- [reader] **SECTION-ENTRIES** *SECTION* *(:ENTRIES)*

    A list of strings and [`REFERENCE`][cc37] objects in the
    order they occurred in [`DEFSECTION`][2863].

<a name='x-28DESCRIBE-OBJECT-20-28METHOD-20NIL-20-28MGL-PAX-3ASECTION-20T-29-29-29'></a>

- [method] **DESCRIBE-OBJECT** *(SECTION SECTION) STREAM*

    [`SECTION`][aee8] objects are printed by calling [`DOCUMENT`][1eb8] on them
    with all [Documentation Printer Variables][e2a1], except for
    [`*DOCUMENT-NORMALIZE-PACKAGES*`][353f], turned off to reduce clutter.

<a name='x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-20MGL-PAX-3ASECTION-29'></a>

## 10 Transcripts

What are transcripts for? When writing a tutorial, one often wants
to include a REPL session with maybe a few defuns and a couple of
forms whose output or return values are shown. Also, in a function's
docstring an example call with concrete arguments and return values
speaks volumes. A transcript is a text that looks like a repl
session, but which has a light markup for printed output and return
values, while no markup (i.e. prompt) for lisp forms. The PAX
transcripts may include output and return values of all forms, or
only selected ones. In either case the transcript itself can be
easily generated from the source code.

The main worry associated with including examples in the
documentation is that they tend to get out-of-sync with the code.
This is solved by being able to parse back and update transcripts.
In fact, this is exactly what happens during documentation
generation with PAX. Code sections tagged `"cl-transcript"` are
retranscribed and checked for inconsistency (that is, any difference
in output or return values). If the consistency check fails, an
error is signalled that includes a reference to the object being
documented.

Going beyond documentation, transcript consistency checks can be
used for writing simple tests in a very readable form. For example:

```cl-transcript
(+ 1 2)
=> 3

(values (princ :hello) (list 1 2))
.. HELLO
=> :HELLO
=> (1 2)

```

All in all, transcripts are a handy tool especially when combined
with the Emacs support to regenerate them and with
`PYTHONIC-STRING-READER` and its triple-quoted strings that allow one
to work with nested strings with less noise. The triple-quote syntax
can be enabled with:

    (in-readtable pythonic-string-syntax)


<a name='x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-EMACS-INTEGRATION-20MGL-PAX-3ASECTION-29'></a>

### 10.1 Transcribing with Emacs

Typical transcript usage from within Emacs is simple: add a lisp
form to a docstring at any indentation level. Move the cursor right
after the end of the form as if you were to evaluate it with `C-x
C-e`. The cursor is marked by `#\^`:

    This is part of a docstring.
    
    ```cl-transcript
    (values (princ :hello) (list 1 2))^
    ```

Note that the use of fenced code blocks with the language tag
`cl-transcript` is only to tell PAX to perform consistency checks at
documentation generation time.

Now invoke the elisp function `mgl-pax-transcribe` where the cursor
is and the fenced code block from the docstring becomes:

    (values (princ :hello) (list 1 2))
    .. HELLO
    => :HELLO
    => (1 2)
    ^

Then you change the printed message and add a comment to the second
return value:

    (values (princ :hello-world) (list 1 2))
    .. HELLO
    => :HELLO
    => (1
        ;; This value is arbitrary.
        2)

When generating the documentation you get a
[`TRANSCRIPTION-CONSISTENCY-ERROR`][5a2c] because the printed output and the
first return value changed so you regenerate the documentation by
marking the region of bounded by `#\|` and the cursor at `#\^` in
the example:

    |(values (princ :hello-world) (list 1 2))
    .. HELLO
    => :HELLO
    => (1
        ;; This value is arbitrary.
        2)
    ^

then invoke the elisp function `mgl-pax-retranscribe-region` to get:

    (values (princ :hello-world) (list 1 2))
    .. HELLO-WORLD
    => :HELLO-WORLD
    => (1
        ;; This value is arbitrary.
        2)
    ^

Note how the indentation and the comment of `(1 2)` was left alone
but the output and the first return value got updated.

Transcription support in emacs can be enabled by adding this to your
Emacs initialization file (or loading `src/transcribe.el`):

<a name='x-28MGL-PAX-3A-3ATRANSCRIBE-2EEL-20-28MGL-PAX-3AINCLUDE-20-23P-22-2Fhome-2Fmega-2Fown-2Fmgl-pax-2Fsrc-2Ftranscribe-2Eel-22-20-3AHEADER-NL-20-22-60-60-60elisp-22-20-3AFOOTER-NL-20-22-60-60-60-22-29-29'></a>

```elisp
;;; MGL-PAX transcription

(defun mgl-pax-transcribe-last-expression ()
  "A bit like C-u C-x C-e (slime-eval-last-expression) that
inserts the output and values of the sexp before the point,
this does the same but with MGL-PAX:TRANSCRIBE."
  (interactive)
  (insert
   (save-excursion
     (let* ((end (point))
            (start (progn (backward-sexp)
                          (move-beginning-of-line nil)
                          (point))))
       (mgl-pax-transcribe start end nil nil nil)))))

(defun mgl-pax-retranscribe-region (start end)
  "Updates the transcription in the current region (as in calling
MGL-PAX:TRANSCRIBE with :UPDATE-ONLY T.)"
  (interactive "r")
  (let* ((point-at-start-p (= (point) start))
         (point-at-end-p (= (point) end))
         (transcript (mgl-pax-transcribe start end t t t)))
    (if point-at-start-p
        (save-excursion
          (goto-char start)
          (delete-region start end)
          (insert transcript))
      (save-excursion
          (goto-char start)
          (delete-region start end))
      (insert transcript))))

(defun mgl-pax-transcribe (start end update-only echo first-line-special-p)
  (let ((transcription
         (slime-eval
          `(cl:if (cl:find-package :mgl-pax)
                  (cl:funcall
                   (cl:find-symbol
                    (cl:symbol-name :transcribe-for-emacs) :mgl-pax)
                   ,(buffer-substring-no-properties start end)
                   ,update-only ,echo ,first-line-special-p)
                  t))))
    (if (eq transcription t)
        (error "MGL-PAX is not loaded.")
      transcription)))
```

<a name='x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-API-20MGL-PAX-3ASECTION-29'></a>

### 10.2 Transcript API

<a name='x-28MGL-PAX-3ATRANSCRIBE-20FUNCTION-29'></a>

- [function] **TRANSCRIBE** *SOURCE TRANSCRIPT &KEY UPDATE-ONLY CHECK-CONSISTENCY (INCLUDE-NO-OUTPUT UPDATE-ONLY) (INCLUDE-NO-VALUE UPDATE-ONLY) (ECHO T) DEBUG (PREFIX-PREFIX "") (OUTPUT-PREFIX ".. ") (VALUE-PREFIX "=\> ") (UNREADABLE-VALUE-PREFIX "==\> ") (UNREADABLE-VALUE-CONTINUATION-PREFIX "--\> ") (TRANSCRIBED-PREFIX-PREFIX PREFIX-PREFIX) (TRANSCRIBED-OUTPUT-PREFIX OUTPUT-PREFIX) (TRANSCRIBED-VALUE-PREFIX VALUE-PREFIX) (TRANSCRIBED-UNREADABLE-VALUE-PREFIX UNREADABLE-VALUE-PREFIX) (TRANSCRIBED-UNREADABLE-VALUE-CONTINUATION-PREFIX UNREADABLE-VALUE-CONTINUATION-PREFIX) (NO-VALUE-MARKER "; No value")*

    Read forms from `SOURCE` and write them (iff `ECHO`) to `TRANSCRIPT`
    followed by any output and return values produced by calling `EVAL` on
    the form. `SOURCE` can be a stream or a string, while `TRANSCRIPT` can
    be a stream or `NIL` in which case transcription goes into a string.
    The return value is the `TRANSCRIPT` stream or the string that was
    constructed.
    
    A simple example is this:
    
    ```cl-transcript
    (transcribe "(princ 42) " nil)
    => "(princ 42)
    .. 42
    => 42
    "
    
    ```
    
    However, it may be a bit confusing since this documentation uses
    [`TRANSCRIBE`][0382] markup syntax in this very example, so let's do it
    differently. If we have a file with these contents:
    
        (values (princ 42) (list 1 2))
    
    they are transcribed to:
    
        (values (princ 42) (list 1 2))
        .. 42
        => 42
        => (1 2)
    
    Output to all standard streams is captured and printed with
    `OUTPUT-PREFIX` (`".. "` above). Return values are printed with
    `VALUE-PREFIX` (`"=> "`). Note how these prefixes are always printed
    on a new line to facilitate parsing.
    
    [`TRANSCRIBE`][0382] is able to parse its own output. If we transcribe the
    previous output above, we get it back exactly. However, if we remove
    all output markers, leave only a placeholder value marker and
    pass `:UPDATE-ONLY` `T` with source:
    
        (values (princ 42) (list 1 2))
        =>
    
    we get this:
    
        (values (princ 42) (list 1 2))
        => 42
        => (1 2)
    
    With `UPDATE-ONLY`, printed output of a form is only transcribed if
    there were output markers in the source. Similarly, with
    `UPDATE-ONLY`, return values are only transcribed if there were value
    markers in the source.
    
    If the form produces no output or returns no values then whether
    output and values are transcribed is controlled by `INCLUDE-NO-OUTPUT`
    and `INCLUDE-NO-VALUE`, respectively. By default, neither is on so:
    
        (values)
        ..
        =>
    
    is transcribed to
    
        (values)
    
    With `UPDATE-ONLY` true, we probably wouldn't like to lose those
    markers since they were put there for a reason. Hence, with
    `UPDATE-ONLY`, `INCLUDE-NO-OUTPUT` and `INCLUDE-NO-VALUE` default to true.
    So with `UPDATE-ONLY` the above example is transcribed to:
    
        (values)
        ..
        => ; No value
    
    where `"; No value"` is the default `NO-VALUE-MARKER`.
    
    If `CHECK-CONSISTENCY` is true, then [`TRANSCRIBE`][0382] signals a continuable
    [`TRANSCRIPTION-CONSISTENCY-ERROR`][5a2c] whenever a form's output is
    different between the source and the evaluation. Similary, for
    values, a consistency error is signalled if a value read from the
    source does not print as the same string as the value returned by
    `EVAL`. This allows readable values to be hand-indented without
    failing consistency checks:
    
        (list 1 2)
        => (1
              2)
    
    The above scheme involves `READ`, so unreadable values cannot be
    treated the same. In fact, unreadable values must even be printed
    differently for transcribe to be able to read them back:
    
        (defclass some-class () ())
        
        (defmethod print-object ((obj some-class) stream)
          (print-unreadable-object (obj stream :type t)
            (format stream "~%~%end")))
        
        (make-instance 'some-class)
        ==> #<SOME-CLASS 
        -->
        --> end>
    
    `"==> "` is `UNREADABLE-VALUE-PREFIX` and `"--> "` is
    `UNREADABLE-VALUE-CONTINUATION-PREFIX`. As with outputs, a consistency
    check between a unreadable value from the source and the value from
    `EVAL` is performed with `STRING=`. That is, the value from `EVAL` is
    printed to a string and compared to the source value. Hence, any
    change to unreadable values will break consistency checks. This is
    most troublesome with instances of classes with the default
    `PRINT-OBJECT` method printing the memory address. There is currently
    no remedy for that, except for customizing `PRINT-OBJECT` or not
    transcribing that kind of stuff.
    
    Trailing whitespaces are never printed unless the output or the
    values have trailing spaces themselves. This means that all prefix
    strings are right trimmed if the rest of the line is empty.
    
    Finally, one may want to produce a transcript that's valid Common
    Lisp. This can be achieved by adding a semicolon character to all
    prefixes used for markup like this which can be done with
    `:PREFIX-PREFIX` `";"`. One can even translate a transcription from
    the default markup to the one with semicolons
    with `:TRANSCRIBED-PREFIX-PREFIX` `";"`. In general, there is a set
    of prefix arguments used when writing the transcript that mirror
    those for parsing `SOURCE`.

<a name='x-28MGL-PAX-3ATRANSCRIPTION-ERROR-20CONDITION-29'></a>

- [condition] **TRANSCRIPTION-ERROR** *ERROR*

    Represents syntactic errors in the `SOURCE` argument
    of [`TRANSCRIBE`][0382] and also serves as the superclass of
    [`TRANSCRIPTION-CONSISTENCY-ERROR`][5a2c].

<a name='x-28MGL-PAX-3ATRANSCRIPTION-CONSISTENCY-ERROR-20CONDITION-29'></a>

- [condition] **TRANSCRIPTION-CONSISTENCY-ERROR** *TRANSCRIPTION-ERROR*

    Signaled by [`TRANSCRIBE`][0382] (with `CERROR`) when a
    consistency check fails.

  [00f0]: #x-28MGL-PAX-3A-40MGL-PAX-REFERENCE-BASED-EXTENSIONS-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-REFERENCE-BASED-EXTENSIONS MGL-PAX:SECTION)"
  [0382]: #x-28MGL-PAX-3ATRANSCRIBE-20FUNCTION-29 "(MGL-PAX:TRANSCRIBE FUNCTION)"
  [0412]: #x-28MGL-PAX-3AREFERENCE-OBJECT-20-28MGL-PAX-3AREADER-20MGL-PAX-3AREFERENCE-29-29 "(MGL-PAX:REFERENCE-OBJECT (MGL-PAX:READER MGL-PAX:REFERENCE))"
  [16ad]: #x-28PACKAGE-20MGL-PAX-3ALOCATIVE-29 "(PACKAGE MGL-PAX:LOCATIVE)"
  [1920]: #x-28MGL-PAX-3ACOLLECT-REACHABLE-OBJECTS-20GENERIC-FUNCTION-29 "(MGL-PAX:COLLECT-REACHABLE-OBJECTS GENERIC-FUNCTION)"
  [1eb8]: #x-28MGL-PAX-3ADOCUMENT-20FUNCTION-29 "(MGL-PAX:DOCUMENT FUNCTION)"
  [1f66]: #x-28MGL-PAX-3ASECTION-ENTRIES-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29 "(MGL-PAX:SECTION-ENTRIES (MGL-PAX:READER MGL-PAX:SECTION))"
  [1fbb]: #x-28MGL-PAX-3A-40MGL-PAX-LOCATIVE-TYPES-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-LOCATIVE-TYPES MGL-PAX:SECTION)"
  [2285]: #x-28MGL-PAX-3ALOCATE-ERROR-20CONDITION-29 "(MGL-PAX:LOCATE-ERROR CONDITION)"
  [24fc]: #x-28MGL-PAX-3ACANONICAL-REFERENCE-20GENERIC-FUNCTION-29 "(MGL-PAX:CANONICAL-REFERENCE GENERIC-FUNCTION)"
  [2863]: #x-28MGL-PAX-3ADEFSECTION-20MGL-PAX-3AMACRO-29 "(MGL-PAX:DEFSECTION MGL-PAX:MACRO)"
  [2cf1]: #x-28MGL-PAX-3ASECTION-20MGL-PAX-3ALOCATIVE-29 "(MGL-PAX:SECTION MGL-PAX:LOCATIVE)"
  [3023]: #x-28FUNCTION-20MGL-PAX-3ALOCATIVE-29 "(FUNCTION MGL-PAX:LOCATIVE)"
  [32ac]: #x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-SYNTAX-HIGHLIGHTING-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-MARKDOWN-SYNTAX-HIGHLIGHTING MGL-PAX:SECTION)"
  [353f]: #x-28MGL-PAX-3A-2ADOCUMENT-NORMALIZE-PACKAGES-2A-20VARIABLE-29 "(MGL-PAX:*DOCUMENT-NORMALIZE-PACKAGES* VARIABLE)"
  [3fef]: #x-28MGL-PAX-3A-2ADOCUMENT-LINK-SECTIONS-2A-20VARIABLE-29 "(MGL-PAX:*DOCUMENT-LINK-SECTIONS* VARIABLE)"
  [4336]: #x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-INDENTATION-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-MARKDOWN-INDENTATION MGL-PAX:SECTION)"
  [474c]: #x-28VARIABLE-20MGL-PAX-3ALOCATIVE-29 "(VARIABLE MGL-PAX:LOCATIVE)"
  [4918]: #x-28-22mgl-pax-22-20ASDF-2FSYSTEM-3ASYSTEM-29 "(\"mgl-pax\" ASDF/SYSTEM:SYSTEM)"
  [5161]: #x-28MGL-PAX-3A-40MGL-PAX-NEW-OBJECT-TYPES-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-NEW-OBJECT-TYPES MGL-PAX:SECTION)"
  [57cb]: #x-28MGL-PAX-3ADEFINE-SYMBOL-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29 "(MGL-PAX:DEFINE-SYMBOL-LOCATIVE-TYPE MGL-PAX:MACRO)"
  [5a2c]: #x-28MGL-PAX-3ATRANSCRIPTION-CONSISTENCY-ERROR-20CONDITION-29 "(MGL-PAX:TRANSCRIPTION-CONSISTENCY-ERROR CONDITION)"
  [62d4]: #x-28MGL-PAX-3ADEFINE-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29 "(MGL-PAX:DEFINE-LOCATIVE-TYPE MGL-PAX:MACRO)"
  [68e7]: #x-28MGL-PAX-3ADEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE-20MGL-PAX-3AMACRO-29 "(MGL-PAX:DEFINE-DEFINER-FOR-SYMBOL-LOCATIVE-TYPE MGL-PAX:MACRO)"
  [6c17]: #x-28MGL-PAX-3ALOCATE-AND-DOCUMENT-20GENERIC-FUNCTION-29 "(MGL-PAX:LOCATE-AND-DOCUMENT GENERIC-FUNCTION)"
  [6e37]: #x-28CLASS-20MGL-PAX-3ALOCATIVE-29 "(CLASS MGL-PAX:LOCATIVE)"
  [76b5]: #x-28MGL-PAX-3ALOCATIVE-20MGL-PAX-3ALOCATIVE-29 "(MGL-PAX:LOCATIVE MGL-PAX:LOCATIVE)"
  [7a11]: #x-28MGL-PAX-3ALOCATE-AND-COLLECT-REACHABLE-OBJECTS-20GENERIC-FUNCTION-29 "(MGL-PAX:LOCATE-AND-COLLECT-REACHABLE-OBJECTS GENERIC-FUNCTION)"
  [7a32]: #x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-TRANSCRIPT MGL-PAX:SECTION)"
  [8059]: #x-28MGL-PAX-3A-40MGL-PAX-BASICS-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-BASICS MGL-PAX:SECTION)"
  [8082]: #x-28MGL-PAX-3A-2ADOCUMENT-LINK-CODE-2A-20VARIABLE-29 "(MGL-PAX:*DOCUMENT-LINK-CODE* VARIABLE)"
  [819a]: #x-28MGL-PAX-3AREFERENCE-LOCATIVE-20-28MGL-PAX-3AREADER-20MGL-PAX-3AREFERENCE-29-29 "(MGL-PAX:REFERENCE-LOCATIVE (MGL-PAX:READER MGL-PAX:REFERENCE))"
  [81be]: #x-28MGL-PAX-3ALOCATE-ERROR-MESSAGE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ALOCATE-ERROR-29-29 "(MGL-PAX:LOCATE-ERROR-MESSAGE (MGL-PAX:READER MGL-PAX:LOCATE-ERROR))"
  [84ee]: #x-28MGL-PAX-3A-40MGL-PAX-BACKGROUND-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-BACKGROUND MGL-PAX:SECTION)"
  [87c7]: #x-28MGL-PAX-3ASECTION-PACKAGE-20-28MGL-PAX-3AREADER-20MGL-PAX-3ASECTION-29-29 "(MGL-PAX:SECTION-PACKAGE (MGL-PAX:READER MGL-PAX:SECTION))"
  [8be2]: #x-28MGL-PAX-3A-2ADOCUMENT-UPPERCASE-IS-CODE-2A-20VARIABLE-29 "(MGL-PAX:*DOCUMENT-UPPERCASE-IS-CODE* VARIABLE)"
  [8ed9]: #x-28MGL-PAX-3A-40MGL-PAX-EXTENSION-API-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-EXTENSION-API MGL-PAX:SECTION)"
  [90f2]: #x-28ASDF-2FSYSTEM-3ASYSTEM-20MGL-PAX-3ALOCATIVE-29 "(ASDF/SYSTEM:SYSTEM MGL-PAX:LOCATIVE)"
  [966a]: #x-28MGL-PAX-3ALOCATIVE-TYPE-20FUNCTION-29 "(MGL-PAX:LOCATIVE-TYPE FUNCTION)"
  [96c5]: #x-28MGL-PAX-3AEXPORTABLE-LOCATIVE-TYPE-P-20GENERIC-FUNCTION-29 "(MGL-PAX:EXPORTABLE-LOCATIVE-TYPE-P GENERIC-FUNCTION)"
  [a05e]: #x-28MGL-PAX-3ADOCUMENT-OBJECT-20GENERIC-FUNCTION-29 "(MGL-PAX:DOCUMENT-OBJECT GENERIC-FUNCTION)"
  [aa52]: #x-28MGL-PAX-3A-40MGL-PAX-TUTORIAL-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-TUTORIAL MGL-PAX:SECTION)"
  [acc9]: #x-28MGL-PAX-3ALOCATE-OBJECT-20GENERIC-FUNCTION-29 "(MGL-PAX:LOCATE-OBJECT GENERIC-FUNCTION)"
  [ad5a]: #x-28MGL-PAX-3APAX-2EEL-20-28MGL-PAX-3AINCLUDE-20-23P-22-2Fhome-2Fmega-2Fown-2Fmgl-pax-2Fsrc-2Fpax-2Eel-22-20-3AHEADER-NL-20-22-60-60-60elisp-22-20-3AFOOTER-NL-20-22-60-60-60-22-29-29 "(MGL-PAX:PAX.EL (MGL-PAX:INCLUDE #P\"/home/mega/own/mgl-pax/src/pax.el\" :HEADER-NL \"```elisp\" :FOOTER-NL \"```\"))"
  [aee8]: #x-28MGL-PAX-3ASECTION-20CLASS-29 "(MGL-PAX:SECTION CLASS)"
  [b2be]: #x-28MGL-PAX-3ALOCATE-20FUNCTION-29 "(MGL-PAX:LOCATE FUNCTION)"
  [b417]: #x-28MGL-PAX-3AFIND-SOURCE-20GENERIC-FUNCTION-29 "(MGL-PAX:FIND-SOURCE GENERIC-FUNCTION)"
  [be22]: #x-28MGL-PAX-3A-40MGL-PAX-SECTIONS-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-SECTIONS MGL-PAX:SECTION)"
  [bf16]: #x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-API-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-TRANSCRIPT-API MGL-PAX:SECTION)"
  [c694]: #x-28MGL-PAX-3A-40MGL-PAX-TRANSCRIPT-EMACS-INTEGRATION-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-TRANSCRIPT-EMACS-INTEGRATION MGL-PAX:SECTION)"
  [c98c]: #x-28MGL-PAX-3ADEFINE-PACKAGE-20MGL-PAX-3AMACRO-29 "(MGL-PAX:DEFINE-PACKAGE MGL-PAX:MACRO)"
  [cc37]: #x-28MGL-PAX-3AREFERENCE-20CLASS-29 "(MGL-PAX:REFERENCE CLASS)"
  [d023]: #x-28MGL-PAX-3A-40MGL-PAX-LOCATIVES-AND-REFERENCES-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-LOCATIVES-AND-REFERENCES MGL-PAX:SECTION)"
  [d259]: #x-28MGL-PAX-3A-2ADISCARD-DOCUMENTATION-P-2A-20VARIABLE-29 "(MGL-PAX:*DISCARD-DOCUMENTATION-P* VARIABLE)"
  [d58f]: #x-28MGL-PAX-3A-40MGL-PAX-MARKDOWN-SUPPORT-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-MARKDOWN-SUPPORT MGL-PAX:SECTION)"
  [d71c]: #x-28METHOD-20MGL-PAX-3ALOCATIVE-29 "(METHOD MGL-PAX:LOCATIVE)"
  [d7eb]: #x-28MGL-PAX-3ADOCUMENT-OBJECT-20-28METHOD-20NIL-20-28STRING-20T-29-29-29 "(MGL-PAX:DOCUMENT-OBJECT (METHOD NIL (STRING T)))"
  [df39]: #x-28DESCRIBE-OBJECT-20-28METHOD-20NIL-20-28MGL-PAX-3ASECTION-20T-29-29-29 "(DESCRIBE-OBJECT (METHOD NIL (MGL-PAX:SECTION T)))"
  [e0d7]: #x-28MGL-PAX-3ARESOLVE-20FUNCTION-29 "(MGL-PAX:RESOLVE FUNCTION)"
  [e2a1]: #x-28MGL-PAX-3A-40MGL-PAX-DOCUMENTATION-PRINTER-VARIABLES-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-DOCUMENTATION-PRINTER-VARIABLES MGL-PAX:SECTION)"
  [e9e9]: #x-28MGL-PAX-3ALOCATE-AND-FIND-SOURCE-20GENERIC-FUNCTION-29 "(MGL-PAX:LOCATE-AND-FIND-SOURCE GENERIC-FUNCTION)"
  [eff4]: #x-28MGL-PAX-3A-40MGL-PAX-EMACS-INTEGRATION-20MGL-PAX-3ASECTION-29 "(MGL-PAX:@MGL-PAX-EMACS-INTEGRATION MGL-PAX:SECTION)"
  [f3b7]: #x-28MGL-PAX-3ALOCATE-ERROR-20FUNCTION-29 "(MGL-PAX:LOCATE-ERROR FUNCTION)"

* * *
###### \[generated by [MGL-PAX](https://github.com/melisgl/mgl-pax)\]
