should = require 'should'
algebra = require '../src/algebra'

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
        (algebra.tokenize expr).should.eql tokens

it 'can detect an incomplete expression'
    # TODO
    # shunt should throw errors for mismatched parentheses etc.

it 'can determine precedence'
    # hasPrecedence

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
    (algebra.parse 'a^2 + 2*a*b + b^2').should.eql [
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
    (algebra.complexity expr).should.eql 6

it 'can convert an expression tree into LaTeX', ->
    expr =
        ['+',
            ['/', 
                ['+', 'a', 1],
                ['-', 'a', 1]
            ],
            'b'
        ]

    (algebra.writeLaTeX expr).should.eql \
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
    factored = algebra.parse '2*5 + (a+b)^2 - 10'
    expanded = algebra.parse 'a^2 + 2 * a * b + b^2'
    mistaken = algebra.parse 'a^2 + b^2'

    (algebra.test factored, expanded).should.be.true()
    (algebra.test factored, mistaken).should.be.false()

it 'can simplify expressions'
    # simplify

it 'can diff expressions'
    # diff

it 'can calculate the result of a concrete expression', ->
    (algebra.calculate ['*', ['+', 4, 5], 9]).should.eql 81

it 'can fill in variables in an abstract expression', ->
    expr = algebra.parse 'a + (22 * b)^c + 9^(2^c)'
    filled = algebra.substitute expr, 
        a: 1
        b: 2
        c: 3
    (algebra.calculate filled).should.eql 43131906
