;;; mode-test.el --- Test helpers for major/minor modes  -*- lexical-binding: t; -*-

;; Copyright (C) 2017  USAMI Kenta

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 24 Oct 2017
;; Version: 0.0.1
;; Keywords: maint, lisp
;; Package-Requires: ((emacs "24") (cl-lib "0.5") (f "0.17"))
;; URL: https://github.com/emacs-php/mode-test-suite

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is test helper functions for major/minor modes.

;; ## Macro
;;
;; ### mode-test-with-buffer
;;
;;     (ert-deftest set-major-mode-by-shebang ()
;;       (dolist (shebang '("#!/usr/bin/php"
;;                          "#!/usr/bin/env php"))
;;         (should
;;          (eq
;;           'php-mode
;;           (mode-test-with-buffer "foo"
;;             (insert (mapconcat #'identity
;;                                (list shebang "<?php echo 'Hello!', PHP_EOL;" "")
;;                                "\n"))
;;             (set-auto-mode)
;;             major-mode)))))
;;

;;; Code:
(require 'cl-lib)
(require 'f)

;; Customize
(defgroup mode-test nil
  "Test helpers for major/minor modes"
  :group 'maint
  :group 'lisp
  :prefix "mode-test-")

(defcustom mode-test-benchmark-interactive-methods
  '(move-beggining-to-end insert-whole-contents move-beggining-to-end)
  "Symbol for functions of methods for when called `mode-test-benchmark-current-buffer' in interactively."
  :type '(repeat (choice (const 'move-beggining-to-end)
                         (const 'insert-whole-contents)
                         function))
  :group 'mode-test)

;; Macros
(defmacro mode-test-with-buffer (file &rest body)
  "Create `FILE' buffer and valute `BODY'."
  (declare (indent 1))
  `(with-temp-buffer
     (let ((buffer-file-name ,file))
       ,@body)))

;; (defmacro mode-test-with-buffer-file (file &rest body)
;;   (declare (indent 1))
;;   (let* ((temp-file (f-join temporary-file-directory file)))
;;     (f-touch temp-file)
;;     `(prog1 (with-temp-file ,temp-file
;;               (let ((buffer-file-name ,temp-file))
;;                 ,@body))
;;        (f-delete ,temp-file))))


;; Benchmark
(defun mode-test-benchmark--run (methods)
  "Run `METHODS' for benchmark."
  (unless (listp methods)
    (setq methods (list methods)))

  (cl-loop for m in methods
           do (cond
               ((eq m 'move-beggining-to-end) (mode-test-bm--method-move-beggining-to-end))
               ((eq m 'insert-whole-contents) (mode-test-bm--method-insert-whole-contents))
               (t (funcall m)))))

(defun mode-test-bm--method-move-beggining-to-end ()
  "Move to beginning of buffer, and move the cursor one by one."
  (save-excursion
    (goto-char (point-min))
    (while (< (point) (point-max))
      (goto-char (1+ (point))))
    (goto-char (1+ (point)))))

(defun mode-test-bm--method-insert-whole-contents ()
  "Backup contents in `current-buffer', and insert each characters."
  (let ((buffer-contents (buffer-substring-no-properties (point-min) (point-max))))
    (erase-buffer)
    (cl-loop for str across buffer-contents
             do (insert (char-to-string str)))))

(defun mode-test-benchmark-current-buffer (methods)
  "Run benchmark in `current-buffer' using `METHODS'."
  (interactive (list mode-test-benchmark-interactive-methods))
  (let (begin result)
    (setq begin (float-time))

    (mode-test-benchmark--run methods)

    (setq result (- (float-time) begin))
    (if (called-interactively-p 'interactive)
        (message "Benchmark %f" result)
      result)))

;; (mode-test-with-buffer-file "a.txt"
;;   (set-auto-mode)
;;   (list buffer-file-name major-mode))

;; (mode-test-with-buffer "a.txt"
;;   (set-auto-mode)
;;   (list buffer-file-name major-mode))

(provide 'mode-test)
;;; mode-test.el ends here
