;;; jwt-content.el --- Get the decoded data of a JWT token  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Iwan in 't Groen

;; Author: Iwan in 't Groen <iwanintgroen@gmail.com>
;; URL: https://github.com/igroen/jwt-content.el
;; Keywords: lisp
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))

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

;; Get the base64 decoded header and payload of a JWT token.

;; Example usage:
;; (use-package jwt-content
;;   :straight
;;   (:host github :repo "igroen/jwt-content.el"))

;;; Code:

(require 'json)

(defun jwt-content--get-jwt-parts (jwt)
  "Get header and payload of a JWT token."
  (let ((jwt-parts (split-string jwt "\\.")))
    (butlast jwt-parts (- (length jwt-parts) 2))))

(defun jwt-content--add-padding (jwt-part)
  "Add padding to base64 encoded JWT-PART."
  (let ((mod (% (length jwt-part) 4)))
    (cond
     ((= mod 2) (concat jwt-part "=="))
     ((= mod 3) (concat jwt-part "="))
     (t jwt-part))))

(defun jwt-content--decode-jwt-part (jwt-part)
  "Decode base64 encoded JWT-PART."
  (ignore-errors
    (base64-decode-string
     (jwt-content--add-padding
      (car (split-string jwt-part))))))

(defun jwt-content--decode-jwt (jwt)
  "Decode base64 encoded JWT."
  (mapcar #'jwt-content--decode-jwt-part (jwt-content--get-jwt-parts jwt)))

(defun jwt-content--decode-jwt-to-string (jwt &optional no-pretty-print)
  "Get string containing the decoded header and payload from a JWT token.
An optional parameter NO-PRETTY-PRINT can be used to not pretty print
the decoded JWT token."
  (with-temp-buffer
    (dolist (part (jwt-content--decode-jwt jwt))
      (insert part)
      (unless no-pretty-print
        (json-pretty-print (line-beginning-position) (line-end-position)))
      (insert ?\n))
    (buffer-string)))

(defun jwt-content--replace-jwt (&optional no-pretty-print)
  "Replace JWT token on the current line with the decoded header and payload.
An optional parameter NO-PRETTY-PRINT can be used to not pretty print
the decoded JWT token."
  (save-excursion
    (let ((jwt (thing-at-point 'line)))
      (kill-whole-line)
      (condition-case nil
          (insert (jwt-content--decode-jwt-to-string jwt no-pretty-print))
        (error
         (yank)
         (message "Could not decode JWT token"))))))

;;;###autoload
(defun jwt-content (no-pretty-print)
  "Decode a JWT token.
A prefix argunent for NO-PRETTY-PRINT can be used to not pretty print
the decoded JWT token."
  (interactive "P")
  (jwt-content--replace-jwt no-pretty-print))

(provide 'jwt-content)
;;; jwt-content.el ends here
