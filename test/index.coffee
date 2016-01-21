should = require 'should'

it 'can tokenize a mathematical expression'
    # tokenize

it 'can reorder tokens to RPN notation'
    # shunt
    # (test for correct precedence)

it 'can convert ordered tokens into an expression tree'
    # nest

it 'can reorder commutative expressions into a canonical form'
    # canonical

it 'can count the amount of terms in an expression'
    # complexity

it 'can convert an expression tree into LaTeX'
    # writeLaTeX

it 'can pattern-match expressions'
    # match

it 'can match expressions by evaluating them at various points'
    # test

it 'can simplify expressions'
    # simplify

it 'can diff expressions'
    # diff

it 'can calculate the result of a concrete expression'
    # calculate

it 'can fill in variables in an abstract expression'
    # concrete
