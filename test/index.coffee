_ = require 'underscore'
should = require 'should'

parser = require '../src/parser'
solver = require '../src/solver'
writer = require '../src/writer'
generator = require '../src/generator'
helper = require '../src/helper'


it 'can tokenize a mathematical expression', ->
    expressions = 
        '2 * (3 + 5)^2 + 2': [2, '*', '(', 3, '+', 5, ')', '^', 2, '+', 2]
        '5^2 + 2 * 5 * 10 + 10^2 + 22': [5, '^', 2, '+', 2, '*', 5, '*', 10, '+', 10, '^', 2, '+', 22]
        '(3/2 * ((3 + 2) * 4)^(a*2) + 5) / (22+2)':  [
            '(', 3, '/', 2, '*', 
            '(', '(', 3, '+', 2, ')', '*', 4, ')', '^', '(', 'a', '*', 2, ')', '+', 5, ')',
            '/', '(', 22, '+', 2, ')'
        ]

    for expr, tokens of expressions
        (parser.tokenize expr).should.eql tokens

it 'can detect an incomplete expression'
# TODO
# shunt should throw errors for mismatched parentheses etc.

it 'can determine precedence'
###
hasPrecedence

# proper precedence parsing for equal precedence operators
# (first divide, then multiply)

console.log parse '(a + 22 + b + c) / 22 * b'
console.log parse 'a^2 + 2 * a * b + b^2'
console.log complexity parse 'a^2 + 2 * a * b + b^2'

# parse negative numbers
console.log tokenize '-b - -7'
console.log tokenize '(-x)^2'
show parse '-b^2 + (-x)^2'
console.log writeLaTeX parse '-1 * b'
###

it 'can reorder tokens to RPN notation'
# shunt
# (test for correct precedence)

it 'can parse functions'
# TODO

it 'can parse unary operators'
# TODO
# +5 and -7... but more importantly things
# like the factorial operator

it 'can convert ordered tokens into an expression tree'
# nest

it 'can parse a mathematical expression into an expression tree', ->
    (parser.parse 'a^2 + 2*a*b + b^2').should.eql [
        '+',
            ['+',
                ['^', 'a', 2], 
                ['*', ['*', 2, 'a'], 'b']
            ],
        ['^', 'b', 2]
    ]

it 'can reorder commutative expressions into a canonical form'
# canonical

it 'can count the amount of terms in an expression', ->
    expr = [
        '+',
            ['+',
                ['^', 'a', 2], 
                ['*', ['*', 2, 'a'], 'b']
            ],
        ['^', 'b', 2]
    ]
    (parser.tuples expr).should.eql 6

it 'can convert an expression tree into LaTeX', ->
    expr =
        ['+',
            ['/', 
                ['+', 'a', 1],
                ['-', 'a', 1]
            ],
            'b'
        ]

    (writer.toLaTeX expr).should.eql \
        """
        \\frac{
          a + 1
        }{
          a - 1
        } + b
        """

it 'can match an expression to a pattern'
# match

it 'can match two expressions by evaluating them at various points', ->
    factored = parser.parse '2*5 + (a+b)^2 - 10'
    expanded = parser.parse 'a^2 + 2 * a * b + b^2'
    mistaken = parser.parse 'a^2 + b^2'

    (parser.test factored, expanded).should.be.true()
    (parser.test factored, mistaken).should.be.false()

it 'can simplify expressions'
# simplify

it 'can diff expressions'
# diff
# console.log diff (parse '3 + (55 + 7) * 12^5'), parse ('4 + (7 + 55) * 12^(4+2)')

it 'can point out mistakes in intermediate solutions', ->
    issues = helper.findMisconceptions \
        (parser.parse '(x+y)^3'),
        (parser.parse 'y^3 + x^3')
    issueNames = _.pluck issues, 'name'
    issueNames.should.containEql 'misapplication of distributivity'


it 'can calculate the result of a concrete expression', ->
    (solver.calculate ['*', ['+', 4, 5], 9]).should.eql 81

it 'can fill in variables in an abstract expression', ->
    expr = parser.parse 'a + (22 * b)^c + 9^(2^c)'
    filled = parser.substitute expr, 
        a: 1
        b: 2
        c: 3
    (solver.calculate filled).should.eql 43131906
