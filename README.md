# Algebra

[![Build Status](https://travis-ci.org/debrouwere/algebra.svg?branch=master)](https://travis-ci.org/debrouwere/algebra)

A tiny symbolic computer algebra system. Algebra can parse and manipulate mathematical expressions.

Algebra is the core component of an experimental exercise generator for high school students: an application that generates various algebra exercises of increasing difficulty, corrects intermediate results and gives hints when the student is stuck. Parts of it work, parts of it not yet.

Why? The goal is not to build another Maple, SAGE or SymPy, but to have a CAS that (1) runs in the browser and (2) has _minimal_ mathematical coverage, but when it comes to high school algebra has _maximal_ diagnostics, for example through functionality that detects common misconceptions in intermediate solutions to exercises and tells you exactly where things went wrong. This isn't a CAS to allow a computer to do mathematics, it's a CAS to teach humans to do mathematics.