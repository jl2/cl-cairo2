(in-package :cl-cairo2)

;;;; WARNING:
;;;;
;;;; Using this interface may prove problematic.  Once Cairo has a
;;;; FT-FACE, it may render it at any time.  Since Freetype2 in
;;;; general does no locking, this means you should essentially
;;;; never use the same FT-LIBRARY object associated with faces passed
;;;; to Cairo.
;;;;
;;;; You may use FT-SCALED-FONT-LOCK-FACE, but you still must ensure
;;;; no Cairo functions get called or the locking is rendered moot.
;;;; Unfortunately many UI wrappers in Common Lisp run their main
;;;; event loop in a background thread...
;;;;
;;;; One alternative is to use Cairo's USER-FONT interface and render
;;;; from Lisp.  This provides much better control over FT-FACE
;;;; resources.  While this requires Lisp-side glyph caching, doing
;;;; such is fairly trivial.

 ;; Types

(defclass freetype-font-face (font-face)
  ((face :initarg :face :initform nil)))

 ;; Interface

(defmethod create-font ((source-face ft2-types:ft-face) &key load-flags)
  "Create a Cairo FONT-FACE from a Freetype2 FT-FACE.  Note that, until
the FONT-FACE is destroyed, you should not use the FT-FACE in any way
without calling FT-SCALED-FONT-LOCK-FACE.  See the general Freetype2/Cairo
warning."
  (let* ((ptr (cairo_ft_font_face_create_for_ft_face
               (ft2-types:w* source-face)
               (convert-to-foreign load-flags 'ft2-types:ft-load-flags)))
         (font (make-instance 'freetype-font-face
                              :face source-face
                              :pointer ptr)))
    ;; Still technically incorrect I believe because something else
    ;; could reference this.  Solve by callback.
    (tg:finalize font (lambda () (cairo_font_face_destroy ptr)))
    font))
