;;; test-jwt-content.el --- Tests for jwt-content.el  -*- lexical-binding: t; -*-

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

;; Tests for jwt-content.el

;;; Code:

(require 'ert)

(require 'jwt-content)

(ert-deftest test-jwt-content-get-jwt-parts ()
  (should (equal (jwt-content--get-jwt-parts "abc.def.ghi.jkl") '("abc" "def")))
  (should (equal (jwt-content--get-jwt-parts "abc.def.ghi") '("abc" "def")))
  (should (equal (jwt-content--get-jwt-parts "abc.def") '("abc" "def")))
  (should (equal (jwt-content--get-jwt-parts "abc") '("abc"))))

(ert-deftest test-jwt-content-add-padding ()
  (should (equal (jwt-content--add-padding "a") "a"))
  (should (equal (jwt-content--add-padding "aa") "aa=="))
  (should (equal (jwt-content--add-padding "aaa") "aaa="))
  (should (equal (jwt-content--add-padding "aaaa") "aaaa"))
  (should (equal (jwt-content--add-padding "aaaaa") "aaaaa")))

(ert-deftest test-jwt-content-decode-jwt-part ()
  (should (equal (jwt-content--decode-jwt-part "not-base64-encoded") nil))
  (should (equal (jwt-content--decode-jwt-part "eyJmb28iOiAiYmFyIn0") "{\"foo\": \"bar\"}"))
  (should (equal (jwt-content--decode-jwt-part "eyJmb28iOiAiYmFyIn0 ") "{\"foo\": \"bar\"}"))
  (should (equal (jwt-content--decode-jwt-part "eyJmb28iOiAiYmFyIn0\n") "{\"foo\": \"bar\"}")))

(ert-deftest test-jwt-content-decode-jwt ()
  (should (equal (jwt-content--decode-jwt
                  "eyJmb28iOiAiYmFyIn0")
                 '("{\"foo\": \"bar\"}")))
  (should (equal (jwt-content--decode-jwt
                  "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0")
                 '("{\"foo\": \"bar\"}"
                   "{\"baz\": \"qux\"}"))))

(ert-deftest test-jwt-content-decode-jwt-to-string ()
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJmb28iOiAiYmFyIn0")
                 "{\n  \"foo\": \"bar\"\n}\n"))
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJiYXoiOiAicXV4In0")
                 "{\n  \"baz\": \"qux\"\n}\n"))
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature")
                 "{\n  \"foo\": \"bar\"\n}\n{\n  \"baz\": \"qux\"\n}\n"))
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJmb28iOiAiYmFyIn0" t)
                 "{\"foo\": \"bar\"}\n"))
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJiYXoiOiAicXV4In0" t)
                 "{\"baz\": \"qux\"}\n"))
  (should (equal (jwt-content--decode-jwt-to-string
                  "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature" t)
                 "{\"foo\": \"bar\"}\n{\"baz\": \"qux\"}\n")))

(defmacro test-jwt-content--check-buffer (text expected &rest body)
  "Execute BODY on TEXT in temporary buffer and check if the result is equal to EXPECTED."
  `(equal
    (with-temp-buffer
      (insert ,text)
      ,@body
      (buffer-string))
    ,expected))

(ert-deftest test-jwt-content-replace-jwt ()
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0"
           "{\n  \"foo\": \"bar\"\n}\n"
           (jwt-content--replace-jwt)))
  (should (test-jwt-content--check-buffer
           "eyJiYXoiOiAicXV4In0"
           "{\n  \"baz\": \"qux\"\n}\n"
           (jwt-content--replace-jwt)))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature"
           "{\n  \"foo\": \"bar\"\n}\n{\n  \"baz\": \"qux\"\n}\n"
           (jwt-content--replace-jwt)))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0"
           "{\"foo\": \"bar\"}\n"
           (jwt-content--replace-jwt t)))
  (should (test-jwt-content--check-buffer
           "eyJiYXoiOiAicXV4In0"
           "{\"baz\": \"qux\"}\n"
           (jwt-content--replace-jwt t)))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature"
           "{\"foo\": \"bar\"}\n{\"baz\": \"qux\"}\n"
           (jwt-content--replace-jwt t))))

(ert-deftest test-jwt-content-jwt-content ()
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0"
           "{\n  \"foo\": \"bar\"\n}\n"
           (execute-extended-command nil "jwt-content")))
  (should (test-jwt-content--check-buffer
           "eyJiYXoiOiAicXV4In0"
           "{\n  \"baz\": \"qux\"\n}\n"
           (execute-extended-command nil "jwt-content")))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature"
           "{\n  \"foo\": \"bar\"\n}\n{\n  \"baz\": \"qux\"\n}\n"
           (execute-extended-command nil "jwt-content")))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0"
           "{\"foo\": \"bar\"}\n"
           (execute-extended-command t "jwt-content")))
  (should (test-jwt-content--check-buffer
           "eyJiYXoiOiAicXV4In0"
           "{\"baz\": \"qux\"}\n"
           (execute-extended-command t "jwt-content")))
  (should (test-jwt-content--check-buffer
           "eyJmb28iOiAiYmFyIn0.eyJiYXoiOiAicXV4In0.some-signature"
           "{\"foo\": \"bar\"}\n{\"baz\": \"qux\"}\n"
           (execute-extended-command t "jwt-content"))))

(provide 'test-jwt-content)
;;; test-jwt-content.el ends here
