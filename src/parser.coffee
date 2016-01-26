_ = require 'underscore'
{modifies, needs, apply, sum} = require './utils'


OPERATORS =
    '^': (a, b) -> a ** b
    '*': (a, b) -> a * b
    '/': (a, b) -> a / b
    '+': (a, b) -> a + b
    '-': (a, b) -> a - b

PRECEDENCE =
    '^': 4
    '*': 3
    '/': 3
    '+': 2
    '-': 2

SIGILS = _.keys OPERATORS

VARIABLES = (String.fromCharCode(i) for i in _.range 97, 123)


#
# operator precedence
# 

rank = (expr) ->
    [Function, Array, String, Number].indexOf expr.constructor

compare = (a, b) ->
    (a > b) - (b - a)

hasPrecedence = (a, b) ->
    if ranking = compare (rank a), (rank b)
        return ranking
    else if a in SIGILS and b in SIGILS
        return PRECEDENCE[a] - PRECEDENCE[b]
    else
        throw new Error "Cannot determine precedence of #{a.constructor.name} and #{b.constructor.name}: #{a}, #{b}"


#
# tokenization of mathematical expressions
#
cast = (string) ->
    number = parseFloat string

    if isNaN number
        string
    else
        number


tokenize = (s) ->
    pattern = /(\w+|-?[\d\.]+|[\(\)\*\/+-\^])/g
    rawTokens = s.match pattern
    tokens = _.map rawTokens, cast

    # TODO: this is a bit hackish, we will need proper support 
    # for unary operators (+5, -7), functions and right-
    # associative operators at some point
    # (but for now, this little simplification *is* actually
    # nice, because e.g. -b^2 gets exactly the precedence
    # it deserves, without the need for any additional rules)
    #
    # (It might be possible to contain most of the complexity
    # in the shunting algorithm, though, and then all our
    # expression algorithms just have to take into account
    # that not every expression has exactly two arguments.
    # Still, this is hardly a priority, more like a fun little
    # puzzle for a quiet afternoon.)
    cleaned = []
    for i in _.range tokens.length
        prev = tokens[i-1]
        curr = tokens[i]

        if (not prev or prev in SIGILS or prev is '(') and curr in '+-'
            cleaned.push (parseFloat "#{curr}1"), '*'
        else
            cleaned.push curr

    cleaned


shunt = (tokens) ->
    output = []
    ops = []

    for token in tokens
        switch
            when token is '('
                ops.push token
            when token is ')'
                while (_.last ops) isnt '('
                    output.push ops.pop()
                ops.pop()
            when token in SIGILS
                while ops.length and (_.last ops) in SIGILS and (hasPrecedence (_.last ops), token) > -1
                    output.push ops.pop()
                ops.push token
            else
                output.push token

    ###
    Perhaps, while parsing, keep track of whether the current expression is valid, 
    and output the last valid parsed expression as well as the part that was not
    successfully parsed. That way, we can provide more intelligent error messages.
    (Though in reality, I think most errors will be unclosed braces and trailing
    operators while the user is still typing)

    if ops.length
        last = ops.pop()
        if last in '()'
            throw new Error 'mismatched parentheses'
        else
            output.push last
    ###

    while ops.length
        output.push ops.pop()

    output


nest = (tokens) ->
    stack = []

    for token in tokens
        if token in SIGILS
            stack.push [stack.pop(), stack.pop(), token].reverse()
        else
            stack.push token

    stack.pop()


parse = (s) ->
    tokens = tokenize s
    nest shunt tokens


patterns = (mapping) ->
    keys = _.map (_.keys mapping), parse
    values = _.map (_.values mapping), parse
    _.zip keys, values


#
# destructuring expressions
#


isScalar = (expr) ->
    expr not instanceof Array

isExpression = (expr) ->
    not isScalar expr


unwrap = (obj) ->
    if obj.length?
        obj[0]
    else
        obj


destructured = (fn) ->
    (expr, options...) ->
        [op, l, r] = expr
        fn expr, op, l, r, options...


leftmost = modifies isExpression, destructured (expr, op, l, r) ->
    if isSimpleExpression expr
        l
    else
        leftmost l

rightmost = modifies isExpression, destructured (expr, op, l, r) ->
    if isSimpleExpression expr
        r
    else
        rightmost r

#
# evaluation functions
#

isOperator = (expr) ->
    expr in SIGILS

isString = (expr) ->
    isOp = isOperator expr
    isStr = expr instanceof String or (typeof expr) is 'string'
    isStr and not isOp

isVariable = isString

isNumber = (expr) ->
    expr instanceof Number or (typeof expr) is 'number'

isSimpleExpression = (expr) ->
    (isExpression expr) and _.every expr, isScalar

isSimple = (expr) ->
    (isScalar expr) or (isSimpleExpression expr)

isCommutative = destructured (expr, op, l, r) ->
    if isExpression expr
        op in '*+'
    else
        no


#
# measures of complexity and other information about an expression
#

depth = (expr) ->
    if isScalar expr
        0
    else
        1 + _.max _.map expr, depth


# count the number of terms (when solving an exercise, often we want to 
# reduce the amount of terms with every step)
tuples = (expr) ->
    if isScalar expr
        0
    else if isSimpleExpression expr
        1
    else
        1 + sum _.map expr, tuples


# TODO
# the highest power to which a variable is taken in an expression
# (another useful measure of the complexity of an expression)
# TODO: maybe return a variable-order hash
# NOTE: for complex powers, we should probably just keep those
# (so e.g. 2^4x is taken to the 4x'th power)
order = destructured (expr, op, l, r) ->
    if isExpression
        if op is '^' and (isVariable l) or (isVariable r)
            r
    else
        0


variables = (expr) ->
    if isString expr
        [expr]
    else if isExpression expr
        _.uniq _.flatten _.map expr[1..], variables
    else
        []


#
# manipulating simple expressions
#

flip = (l, i, j) ->
    l = l.slice()
    [l[i], l[j]] = [l[j], l[i]]
    l

commute = modifies isExpression, (expr) ->
    if isCommutative expr
        flip expr, 1, 2
    else
        expr


#
# manipulating expression trees
#

canonical = modifies isExpression, destructured (expr, op, l, r) ->
    if (isCommutative expr) and (compare l, r) < 0
        commute expr
    else
        expr


substitute = modifies isExpression, (expr, state, recursive=yes) ->
    if recursive
        expr = _.map expr, (_.partial substitute, _, state)
    
    state[el] or el for el in expr


#
# solving expressions
#

###
NOTE: we can already simplify expressions that match a pattern
but also include some cruft at either end, but we can't yet convert
a^2 + 2*a*b + c + b^2 to (a+b)^2 + c -- unfortunately canonicalization
is not sufficient to catch this, so in addition to canonicalization we'll
have to match all possible permutations of complex expressions
(but only permutations of expressions that consist of expressions, 
every individual expression can be kept in canonical form)
###
simplify = modifies isExpression, (expr) ->
    expr = _.map expr, simplify

    for [replacement, pattern] in strategies
        state = {}
        if match expr, pattern, state
            expr = substitute replacement, state

    expr


# calculate a concrete expression (without any symbolic manipulation)
###
NOTE: while `calculate` can do partial calculations that keep
symbols intact, it's not quite smart enough to use the 
associative property to rejig the expression tree, so it 
currently cannot simplify e.g. `3 + a + 5` to `8 + a`
###
calculate = modifies isExpression, destructured (expr, op, l, r) ->
    l = calculate l
    r = calculate r
    if (isNumber l) and (isNumber r)
        OPERATORS[op] l, r
    else
        [op, l, r]


#
# testing and pattern matching
#

# brute-force equality matching by evaluating expressions
# at multiple points and seeing if the results are equal
test = (a, b) ->
    vars = _.uniq (variables a).concat(variables b)

    for x in [-100, 100]
        values = (x for i in _.range vars.length)
        map = _.object vars, values
        ax = substitute a, map
        bx = substitute b, map
        return no unless (calculate ax) is (calculate bx)
    
    yes


# match an abstract algebraic pattern
match = (expr, pattern, state={}) ->
    # we recurse through expressions in our if/else loop, 
    # so no need to recursively make things concrete
    # at this point (saves some cycles)
    expr = canonical substitute expr, state, no
    pattern = canonical substitute pattern, state, no

    isComparable = expr and expr.constructor is pattern.constructor
    isAbstract = (isString expr) or (isString pattern)

    return no unless isComparable or isAbstract

    if isExpression pattern
        _.every _.map (_.zip expr, pattern, _.times 3, -> state), (apply match)
    else if pattern is expr
        yes
    else if isString pattern
        state[pattern] = expr
        yes
    else
        no


# spot the differences between two expressions
###
NOTE: this is part of the groundwork for later being able to spot mistakes (e.g. misuse 
of the distributive property): "you changed _ into _; it looks like you applied _
but you can only do that with _ or _, not with _"
###
diff = (left, right, context) ->
    if (isSimple left) or (isSimple right)
        if match left, right
            []
        else
            [{left, right, context}]
    else
        _.flatten (diff l, r, left for [l, r] in _.zip left, right), yes


module.exports = {
    # constants
    OPERATORS,
    PRECEDENCE,
    SIGILS,
    VARIABLES,
    # precedence
    hasPrecedence,    
    # parsing
    tokenize,
    shunt,
    nest,    
    parse,
    patterns,
    # destructuring and extraction
    leftmost,
    rightmost,
    destructured,
    commute,
    canonical,
    substitute,    
    # test functions
    isOperator,
    isString,
    isVariable,
    isScalar,
    isNumber,
    isExpression,
    isSimpleExpression,
    isSimple,
    isCommutative,
    # statistics
    depth,
    tuples,
    order,
    # comparisons
    test,
    match,
    diff,
    # (partial) solving
    simplify,
    calculate,
}
