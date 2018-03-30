(common-lisp:in-package :cl-user)
(defpackage make-plato-font (:use :cl))
(in-package :make-plato-font)

(defvar *source*)
(defvar *binary*)
(defvar *map*)
(defvar *map-offset*)

(defun change-mapping-line (line)
  (setf *map-offset*
        (parse-integer (subseq line (+ (search "plato_m" line) 7))
                       :junk-allowed t)))

(defun rotate-bitmap-for-vdc (figures)
  "Twist the bits: the C file gives 16-bit columns, left-to-right.
  The VDC wants 8-bit rows, top-to-bottom."
  (let ((vdc-bytes (make-array 16
                               :element-type '(unsigned-byte 8)
                               :initial-element 0)))
    (dotimes (x 8)
      (let ((column (parse-integer (subseq (elt figures x) 2 4) :radix 16)))
        (dotimes (y 16)
          (setf (ldb (byte 1 x) (elt vdc-bytes y))
                (ldb (byte 1 y) column)))))
    vdc-bytes))

(defun emptyp (sequence)
  (or (null sequence)
      (zerop (length sequence))))

(defvar *char-code-values* (make-hash-table :test 'equal))

(map nil (lambda (ch) (setf (gethash (string ch) *char-code-values*) ch))
     ":abcdefghijklmnopqrstuvwyz0123456789+-*/()$= ,.'\"!;<>_ABCDEFGHIJKLMNOPQRSTUVWXYZ#~{}&|@\\")

(map nil (lambda (pair)
           (destructuring-bind (name char) pair
             (setf (gethash (etypecase name
                              (symbol (string-downcase name))
                              (string name))
                            *char-code-values*) char)))
     '((space #\space)
       (divide #\÷)
       (multiply #\×)
       (assign #\⇐)
       (arrow #\⇒)
       (cedilla #\¸)
       (diaresis #\¨)
       (circumflex #\^)
       (acute #\´)
       (grave #\grave_accent)
       (uparrow #\↑)
       (rtarrow #\→)
       (downarrow #\↓)
       (leftarrow #\←)
       (|low tilde| #\˷)
       ("Sigma" #\Σ)
       ("Delta" #\Δ)
       (union #\∪)
       (intersect #\∩)
       (|not equal| #\≠)
       (degree #\°)
       (equiv #\≍)
       (alpha #\α)
       (beta #\β)
       (delta #\δ)
       (lambda #\λ)
       (mu #\μ)
       (pi #\π)
       (rho #\ρ)
       (sigma #\σ)
       (omega #\ω)
       (less/equal #\≤)
       (greater/equal #\≥)
       (theta #\θ)
       (oe #\œ)))

(defun interpret-char-comment (s)
  (when (string-equal s "/* \ */")
    (return #\\))
  (assert (char-equal #\/ (char s 0) (char s 1)) (s)
          "Expected // CHARNAME but got ~a" s)
  (let ((char-name (string-trim #(#\space #\tab #\newline) (subseq s 3))))
    (getf *char-code-values* char-name)))

(defun write-character-bitmap-line (line)
  (let ((parts (remove-if #'emptyp 
                          (uiop:split-string line
                                             :separator #(#\comma #\space)))))
    (assert (= 9 (length parts)) (line)
            "Expected 8 figures and a comment, got line ~a" line)
    (let ((figures (subseq parts 0 8))
          (char-comment (elt parts 8)))
      (assert (every (lambda (s)
                       (and (= 6 (length s))
                            (char-equal #\0 (char s 0))
                            (char-equal #\x (char s 1))))
                     (coerce figures 'list))
              (line)
              "Expected 8 16-bit hex integer figures but got line ~a" line)
      (write-sequence (rotate-bitmap-for-vdc figures) *binary*) 
      (file-position *map* (+ *map-offset* char-index))
      (write (coerce (char-code (interpret-char-comment char-comment))
                     (unsigned-byte 16))))))

(defun zerofill (file length)
  (setf (file-position file 0))
  (loop repeat length do (write (the (unsigned-byte 8) 0) file))
  (setf (file-position file 0)))

(defun handle-input-line (line)
  (cond
    ((or (< (length line) 3)
         (string-equal line "/*" :end1 2)
         (equal "};" line))
     (return))
    ((string-equal line "const " :end1 6)
     (change-mapping-offset-line line))
    ((search ", //" line)
     (write-character-bitmap-line line))
    (:else
     (warn "Unable to interpret line: ~a" line))))

(defun convert-c-to-binary (infile 
                            &optional
                              (binfile (generate-related-name infile ".o"))
                              (mapfile (generate-related-name infile ".map.o")))
  (with-open-file (*source* infile
                            :external-format :utf-8
                            :element-type 'character)
    (with-open-file (*binary* outfile
                              :direction :output
                              :if-exists :supersede
                              :element-type '(unsigned-byte 8))
      (with-open-file (*map* mapfile
                             :direction :output
                             :if-exists :supersede
                             :element-type '(unsigned-byte 16))
        (zerofill *bitmap* (* 8 1024))
        (zerofill *map* 512)
        (let ((*map-offset* 0))
          (loop for line = (read-line source nil nil)
             while line
               (handle-input-line (string-trim #(#\space #\tab #\newline) line))))))))
