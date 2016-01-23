_ = require 'underscore'
{modifies, needs} = require './utils'
{isExpression, isNumber, isString, isScalar, hasPrecedence} = require './parser'
{destructured, leftmost, rightmost} = require './parser'


parens = (s) ->
    "(#{s})"

braces = (s) ->
    "{#{s}}"

needsParens = (a, b) ->
    if (isExpression a) and (isExpression b)
        (hasPrecedence a[0], b[0]) > 0
    else
        no


toString = modifies isExpression, destructured (expr, op, l, r) ->
    [ops, ls, rs] = _.map expr, toString

    if op not in '^'
        ops = " #{ops} "

    if needsParens expr, l
        ls = parens ls

    if needsParens expr, r
        rs = parens rs

    "#{ls}#{ops}#{rs}"


indent = (s, n) ->
    indentation = (' ' for i in _.range n).join('')
    indentation + (s.replace /\n/g, '\n' + indentation)

toTree = (expr, indentation=0) ->
    if isScalar expr
        indent expr.toString(), indentation
    else
        op = toTree expr[0], indentation
        l  = toTree expr[1], indentation + 2
        r  = toTree expr[2], indentation + 2

        """
        #{op}
        #{l}
        #{r}
        """


text = (s) ->
    "\\text{#{s}}"

toLaTeX = modifies isExpression, destructured (expr, op, l, r, fractions=yes) ->
    isFraction = fractions and op is '/'
    writer = _.partial toLaTeX, _, not isFraction

    [ops, ls, rs] = _.map expr, writer

    if (isString l) and l.length > 1
        ls = text ls

    if (isString r) and r.length > 1
        rs = text rs

    if op not in '^'
        ops = " #{ops} "

    if op is '*'
        if (isNumber rightmost l) and (isNumber leftmost r)
            # use a dot between a multiplication of two constants, 
            # for clarity
            ops = " \\cdot "
        else if l is -1 and (isString leftmost r)
            # negative numbers are a single token, but negative 
            # variables are (or will be) encoded as -1 * v
            ls = '-'
            ops = ''
        else
            ops = ' '

    if not isFraction and needsParens expr, l
        ls = parens ls

    if op is '^'
        rs = braces rs
    else if not isFraction and needsParens expr, r
        rs = parens rs

    if fractions and op is '/'
        "\\frac{\n  #{ls}\n}{\n  #{rs}\n}"
    else
        "#{ls}#{ops}#{rs}"


module.exports = {
    toString,
    toTree,
    toLaTeX,
}