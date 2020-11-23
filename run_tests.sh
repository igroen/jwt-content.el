#!/usr/bin/env bash

emacs --batch \
      --load jwt-content.el \
      --load test-jwt-content.el \
      --funcall ert-run-tests-batch-and-exit
