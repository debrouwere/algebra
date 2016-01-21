if require?
    _ = require 'underscore'


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

# TODO: I dislike this name
SYMBOLS = _.keys OPERATORS

VARIABLES = (String.fromCharCode(i) for i in _.range 97, 123)


sum = (l) ->
    _.reduce l, OPERATORS['+']


needs = (condition, f) ->
    (expr) ->
        if condition expr
            f expr
        else
            throw Error()

modifies = (condition, f) ->
    (expr, options...) ->
        if condition expr
            f expr, options...
        else
            expr

destructured = (fn) ->
    (expr, options...) ->
        [op, l, r] = expr
        fn expr, op, l, r, options...

isOperator = (expr) ->
    expr in SYMBOLS

isString = (expr) ->
    isOp = isOperator expr
    isStr = expr instanceof String or (typeof expr) is 'string'
    isStr and not isOp

isVariable = isString

isScalar = (expr) ->
    expr not instanceof Array

isNumber = (expr) ->
    expr instanceof Number or (typeof expr) is 'number'

isExpression = (expr) ->
    not isScalar expr

isSimpleExpression = (expr) ->
    (isExpression expr) and _.every expr, isScalar

isSimple = (expr) ->
    (isScalar expr) or (isSimpleExpression expr)

isCommutative = destructured (expr, op, l, r) ->
    if isExpression expr
        op in '*+'
    else
        no

commute = modifies isExpression, (expr) ->
    if isCommutative expr
        flip expr, 1, 2
    else
        expr

flip = (l, i, j) ->
    l = l.slice()
    [l[i], l[j]] = [l[j], l[i]]
    l


rank = (expr) ->
    [Function, Array, String, Number].indexOf expr.constructor

compare = (a, b) ->
    (a > b) - (b - a)

hasPrecedence = (a, b) ->
    comparison = compare (rank a), (rank b)
    return comparison unless comparison is 0

    if a in SYMBOLS
        if b in SYMBOLS
            return PRECEDENCE[a] - PRECEDENCE[b]
        else
            return 1
    else if isExpression a
        for [l, r] in _.zip a, b
            comparison = hasPrecedence l, r
            return comparison if comparison isnt 0
        return 0
    else
        return compare a, b

canonical = modifies isExpression, destructured (expr, op, l, r) ->
    if (isCommutative expr) and (compare l, r) < 0
        commute expr
    else
        expr


# convert op strings in the syntax tree into functions
executable = ->


apply = (f) ->
    (args) ->
        f.apply this, args


substitute = modifies isExpression, (expr, state, recursive=yes) ->
    if recursive
        expr = _.map expr, (_.partial substitute, _, state)
    
    state[el] or el for el in expr


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
            when token in SYMBOLS
                while ops.length and (_.last ops) in SYMBOLS and (hasPrecedence (_.last ops), token) > -1
                    output.push ops.pop()
                ops.push token
            else
                output.push token

    ###
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
        if token in SYMBOLS
            stack.push [stack.pop(), stack.pop(), token].reverse()
        else
            stack.push token

    stack.pop()

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

        if (not prev or prev in SYMBOLS or prev is '(') and curr in '+-'
            cleaned.push (parseFloat "#{curr}1"), '*'
        else
            cleaned.push curr

    cleaned

parse = (s) ->
    tokens = tokenize s
    nest shunt tokens


strategies = 
    '0': '0 * v'
    '(a+b)^2': 'a^2 + 2*a*b + b^2'

strategies = 
    ([(parse pattern), (parse expansion)] for pattern, expansion of strategies)


# TODO: we can already simplify expressions that match a pattern
# but also include some cruft at either end, but we can't yet convert
# a^2 + 2*a*b + c + b^2 to (a+b)^2 + c -- unfortunately canonicalization
# is not sufficient to catch this, so in addition to canonicalization we'll
# have to match all possible permutations of complex expressions
# (but only permutations of expressions that consist of expressions, 
# every individual expression can be kept in canonical form)
simplify = modifies isExpression, (expr) ->
    expr = _.map expr, simplify

    for [replacement, pattern] in strategies
        state = {}
        if match expr, pattern, state
            expr = substitute replacement, state

    expr


# calculate, unlike solve, does not involve
# itself in symbolic manipulation
# TODO: while `calculate` can do partial calculations that keep
# symbols intact, it's not quite smart enough to use the 
# associative property to rejig the expression tree, so it 
# currently cannot simplify e.g. `3 + a + 5` to `8 + a`
calculate = modifies isExpression, destructured (expr, op, l, r) ->
    l = calculate l
    r = calculate r
    if (isNumber l) and (isNumber r)
        OPERATORS[op] l, r
    else
        [op, l, r]

depth = (expr) ->
    if isScalar expr
        0
    else
        1 + _.max _.map expr, depth

# count the number of terms; usually when solving an exercise
# we want to gradually reduce the amount of terms (though
# sometimes we might need to regress)
complexity = (expr) ->
    if isScalar expr
        0
    else if isSimpleExpression expr
        1
    else
        1 + sum _.map expr, complexity


# TODO: the highest power to which a variable is taken in an expression
# (another measure of complexity; often the preferred solution is
# the polynomial of the lowest order rather than those with the least
# amount of terms)
# Q: should this return a {var: order, ...} dictionary (using _.max on
# a number of [var, order] tuples) or just a single number?
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


# testing is brute-force equality matching:
# just evaluate each of two expressions at a wide
# range of values for all free variables, and 
# if the zipped results are all equal pairs, 
# you're good
# (needs `variables` and `substitute` functions
# so that symbolic expressions can be evaluated
# at these various points)
test = (a, b) ->
    vars = _.uniq (variables a).concat(variables b)

    for x in [-100, 100]
        values = (x for i in _.range vars.length)
        map = _.object vars, values
        ax = substitute a, map
        bx = substitute b, map
        return no unless (calculate ax) is (calculate bx)

    yes


# spot the differences between two expressions; this is part of the groundwork
# for later being able to spot mistakes (e.g. misuse of the distributive
# property): "you changed _ into _; it looks like you applied _ but you
# can only do that with _ or _, not with _"
diff = (left, right, context) ->
    if (isSimple left) or (isSimple right)
        if match left, right
            []
        else
            [{left, right, context}]
    else
        _.flatten (diff l, r, left for [l, r] in _.zip left, right), yes


mistakes =
    'misapplication of distributivity':
        '(a + b)^c': 'a^c + b^c'
    'misapplication of power to a power':
        'a^b^c': 'a^(b^c)'
        'a^b^c': 'a^(b+c)'
    'misapplication of multiplying different powers of the same base':
        'a^b * a^c': 'a^(b*c)'
    # and so on...

# console.log diff (parse '3 + (55 + 7) * 12^5'), parse ('4 + (7 + 55) * 12^(4+2)')


# TODO: randomize, add opportunities
# NOTE: this is the opposite of solving, though for solving
# we can probably just use the `executable` function and 
# then fold everything up, so solving and confusing are
# not necessarily similar code paths
# NOTE: by using `this` for random number generation, 
# we can further control the difficulty (e.g. 
# only generate small numbers)
# NOTE: these opportunities rely on the fact that confusion
# happens recursively, so that while e.g. expr + 1700 * 0
# is a no-brainer, expr + 1700 * 9^2 * (8 - 2^3) does
# take a couple of steps to properly simplify
# (but again, the really interesting stuff will happen when
# we have a good swapping mechanism so not everything is 
# adjacent until the student makes it so)
confusors =
    'swap':
        condition: isCommutative
        weight: 1
        op: commute
    'sum':
        condition: isNumber
        weight: 1
        op: (a) ->
            b = this.integer()
            ['+', b, a - b]
    'cancel':
        condition: no
        weight: 1
        op: (expr) ->
            a = this.scalar()
            ['-', ['+', expr, a], a]
    'null':
        condition: isScalar
        weight: 1
        op: (expr) ->
            a = this.scalar()
            ['+', expr, ['*', a, 0]]
    'power':
        condition: no
        weight: 1
        op: (expr) ->
            ['^', expr, 1]


choose = (l) ->
    ix = _.random 0, l.length - 1
    l[ix]


# TODO: make this probabilistic, but with a fixed 
# amount of confusions (only *where* the confusions
# happen should be probabilistic)
# TODO: also swap stuff (similar to the permutations
# we'll need for more powerful solving)
# TODO: a mix of concrete (numbers) and abstract (variables)
class Context
    # TODO: figure out symbols that are actually still available
    constructor: ->
        @freeSymbols = ['x', 'y', 'z']

    # TODO
    symbol: ->
        choose ['x', 'y', 'z']
    
    scalar: ->
        (choose [@symbol, @integer])()
    
    integer: ->
        _.random -10, 10


# TODO: hmm, I think this has all the right elements --
# it has the recursion, it has the "make stuff more difficult"
# strategies as well as the "split into factors" strategies, 
# but I need to figure out how to make all of this work together
# nicely
factor = (expr) ->
    for [pattern, replacement] in strategies
        #console.log expr, pattern
        state = {}
        if match expr, pattern, state
            expr = substitute replacement, state

    expr

confuse = (expr, iterations=1) ->
    return expr unless iterations

    # TODO: in addition to using more strategies, 
    # also use equivalencies (e.g. replace a number
    # with a sum of two other numbers, then
    # maybe confuse those further)
    expr = factor expr

    # confuse
    opportunities = []
    for name, confusor of confusors
        isApplicable = confusor.condition or (-> yes)
        continue unless isApplicable expr
        for i in _.range confusor.weight
            opportunities.push confusor.op

    # TODO: maintain and customize context
    context = new Context()
    confusor = choose opportunities
    expr = confusor.call context, expr

    # recurse
    if isExpression expr
        for el, i in expr
            break unless i and iterations
            replacement = confuse el, iterations
            if el isnt replacement
                expr[i] = replacement
                iterations -= 1

    expr


# conjure up an expression with at most n terms
# and at most v variables
conjureOld = (n, v) ->
    if n < 1
        integer = _.random -10, 10
        variable = choose VARIABLES.slice 0, v
        choose [integer, variable]
    else
        symbol = choose SYMBOLS
        l = conjure n - 1, v
        r = conjure n - 2, v
        [symbol, l, r]


# let's start simple
conjurePower = ->
    a = _.random -10, 10
    n = _.random -10, 10
    ['^', a, n]

conjurePolynomial = (order) ->
    terms = []

    for n in _.range order + 1
        a = _.random -10, 10
        term = ['*', a, ['^', 'x', n]]
        if terms.length
            terms = ['+', terms, term]
        else
            terms = term


conjure = conjurePolynomial


parens = (s) ->
    "(#{s})"

braces = (s) ->
    "{#{s}}"


write = modifies isExpression, destructured (expr, op, l, r) ->
    [ops, ls, rs] = _.map expr, write

    if op not in '^'
        ops = " #{ops} "

    if (hasPrecedence expr, l) > 0
        ls = parens ls

    if (hasPrecedence expr, r) > 0
        rs = parens rs

    "#{ls}#{ops}#{rs}"


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

text = (s) ->
    "\\text{#{s}}"


writeLaTeX = modifies isExpression, destructured (expr, op, l, r, fractions=yes) ->
    isFraction = fractions and op is '/'
    writer = _.partial writeLaTeX, _, not isFraction

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

    if not isFraction and (hasPrecedence expr, l) > 0
        ls = parens ls

    if op is '^'
        rs = braces rs
    else if not isFraction and (hasPrecedence expr, r) > 0
        rs = parens rs

    if fractions and op is '/'
        "\\frac{\n  #{ls}\n}{\n  #{rs}\n}"
    else
        "#{ls}#{ops}#{rs}"


show = (o) ->
    console.log (JSON.stringify o).replace /"/g, ''



module.exports = {
    tokenize,
    hasPrecedence,
    shunt,
    parse,
    nest,
    canonical,
    complexity,
    writeLaTeX,
    match,
    test,
    simplify,
    diff,
    calculate,
    substitute,
}