;;; grid.el --- Simple grid layout -*- lexical-binding: t; -*-

;; Copyright (C) 2024  Ilya Chernyshov

;; Author: Ilya Chernyshov <ichernyshovvv@gmail.com>
;; Version: 0.1
;; Package-Requires: ((emacs "29.1"))
;; Keywords: tools, docs, layout
;; URL: https://github.com/ichernyshovvv/grid

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; USAGE:
;; (grid-insert-content '(ROW ROW ...))
;; ROW: '(BOX BOX ...)
;; BOX: plist.  Acceptable properties:

;;   :border
;;   nil or t

;;   :width
;;   "50%"
;;   integer (number of characters)

;;   :padding - horizontal padding
;;   integer (number of characters)

;;   :content - string to be inserted in the box

;;; Code:

(defvar grid-margin 1)

(defun grid-row-empty-p (row)
  "Check whether ROW is empty."
  (seq-every-p
   (lambda (x) (string-empty-p (plist-get x :content)))
   row))

(defun grid--apply-vertical-borders (string)
  "Apply horizontal `line-width' face property to STRING."
  (add-face-text-property
   0 (length string)
   '((t (:box (:line-width (1 . 0)))))
   t string))

(defun grid--apply-overline (string)
  "Apply `overline' face property to STRING."
  (add-face-text-property 0 (length string) '((t (:overline t))) t string))

(defun grid--apply-underline (string)
  "Apply `underline' face property to STRING."
  (add-face-text-property
   0 (length string)
   '((t (:underline ( :color foreground-color :style line :position -3))))
   t string))

(defun grid--apply-invisible-hbox (string)
  "Apply invisible horizontal space to STRING."
  (add-face-text-property
   0 (length string)
   `((t (:box (:line-width (1 . 0) :color ,(face-background 'default)))))
   t string))

(defun grid--normalize-width (width)
  "Normalize WIDTH."
  (if (stringp width)
      (floor
       (* (window-width)
	  (/ (string-to-number width) 100.0)))
    width))

(defun grid--reformat-content (content width)
  "Reformat CONTENT for a box with width WIDTH."
  (let (indent-tabs-mode)
    (with-temp-buffer
      (insert content)
      (goto-char (point-min))
      (while (re-search-forward "\n" nil t)
	(replace-match " ")
	(insert-char ?  (- width (% (match-beginning 0)
				    width))))
      (buffer-string))))

(defun grid--normalize-box (box)
  "Normalize BOX."
  (let* ((content (plist-get box :content))
	 (padding (* (or (plist-get box :padding) 0) 2))
	 (width (- (grid--normalize-width
		    (plist-get box :width))
		   padding)))
    (when (< width 0)
      (user-error "Horizonal padding must be less than width"))
    (setq box (plist-put box :content (grid--reformat-content content width)))
    (setq box (plist-put box :length (length (plist-get box :content))))))

(defun grid--normalize-row (row)
  "Normalize ROW."
  (mapc #'grid--normalize-box row))

(defun grid--insert-row (row)
  "Insert ROW in the current buffer."
  (while (not (grid-row-empty-p row))
    (mapc #'grid--insert-box row)
    (insert "\n"))
  (insert "\n"))

(defun grid--insert-box (box)
  "Insert BOX in the current buffer."
  (let* ((content (plist-get box :content))
	 (content-len (length content))
	 (padding-len (or (plist-get box :padding) 0))
	 (padding (make-string padding-len ? ))
	 (width (- (grid--normalize-width
		    (plist-get box :width))
		   (* padding-len 2)))
	 (line-len (min content-len width))
	 (line (concat padding
		       (format (format "%% -%ds" width)
			       (substring content 0 line-len))
		       padding))
	 (first-line-p
	  (= (plist-get box :length)
	     content-len))
	 (in-body-p (/= content-len 0))
	 (donep (string-empty-p content))
	 (new-content (substring content line-len))
	 (last-line-p (and (not donep) (string-empty-p new-content))))
    (when (plist-get box :border)
      (and first-line-p (grid--apply-overline line))
      (and in-body-p (grid--apply-vertical-borders line))
      (and last-line-p (grid--apply-underline line))
      (and donep (grid--apply-invisible-hbox line)))
    (insert line)
    (insert-char ?  grid-margin)
    (setq box (plist-put box :content new-content))))

;;; API

(defun grid-insert-row (row)
  "Insert ROW in the current buffer."
  (grid--normalize-row row)
  (grid--insert-row row))

(defun grid-insert-content (rows)
  "Insert ROWS in the current buffer."
  (mapc #'grid-insert-row rows))

(provide 'grid)

;;; grid.el ends here
