;; -*- mode: scheme; coding: utf-8 -*-
;; Copyright © 2010, 2012, 2016, 2017 Göran Weinholt <goran@weinholt.se>
;; SPDX-License-Identifier: MIT

;; Permission is hereby granted, free of charge, to any person obtaining a
;; copy of this software and associated documentation files (the "Software"),
;; to deal in the Software without restriction, including without limitation
;; the rights to use, copy, modify, merge, publish, distribute, sublicense,
;; and/or sell copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
;; THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.
#!r6rs

;; Code shared between the disassemblers. Should not be imported by
;; anyone else.

(library (machine-code disassembler private)
  (export raise-UD invalid-opcode? map-in-order
          register-disassembler
          available-disassemblers get-disassembler
          make-disassembler disassembler? disassembler-name
          disassembler-min-instruction-size
          disassembler-max-instruction-size
          disassembler-instruction-getter)
  (import (rnrs))

  (define (map-in-order p l)
    (if (null? l)
        '()
        (cons (p (car l))
              (map-in-order p (cdr l)))))

  (define-condition-type &invalid-opcode &condition
    make-invalid-opcode invalid-opcode?)

  (define (raise-UD msg . irritants)
    (raise (condition
            (make-who-condition 'get-instruction)
            (make-message-condition msg)
            (make-irritants-condition irritants)
            (make-invalid-opcode))))

  (define-record-type disassembler
    (fields name
            min-instruction-size
            max-instruction-size
            instruction-getter))

  (define *registered-disassemblers* '())

  (define (register-disassembler disassembler)
    (set! *registered-disassemblers* (cons (cons (disassembler-name disassembler)
                                                 disassembler)
                                           *registered-disassemblers*)))

  (define (available-disassemblers)
    (map car *registered-disassemblers*))

  (define (get-disassembler name)
    (cond ((assq name *registered-disassemblers*) => cdr)
          (else #f))))
