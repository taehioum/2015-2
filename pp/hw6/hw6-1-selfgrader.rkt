#lang racket

(require racket/match)
(require "common-grade.rkt")
(require "hw6-1.rkt")

(sgoutput (lambda () (equal? 15 (memo-ways 4 2))))

