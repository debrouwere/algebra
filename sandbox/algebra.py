"""
The big problem with math exercises is lack of immediate feedback. 
When solving an equation, every step of the way you should be able 
to see if what you're doing is still correct. While equivalence of 
mathematical expressions is a tough problem (sympy can only do it
for simple expressions), numerical probing isn't:
"""

import random
import operator
import itertools
from scipy.stats import distributions
from numpy import isclose
from sympy.abc import x, y, z

orig = (x+y)**2
change = x**2 + 2*x*y + y**2

probes = [{symbol: random.randint(-1000, 1000) for symbol in orig.free_symbols} for i in range(10)]
matches = [isclose(float(orig.evalf(subs=probe)), float(change.evalf(subs=probe))) for probe in probes]
all(matches)

"""
Perhaps we can then hack into IPython's display functionality so that on every print, 
it returns whether the expression is equal to the one in `exercise`.

Or, even better, have it work as an online Python shell, cf. Sympy Live. We could then 
add a login so we know who is doing the exercises, and keep statistics both on 
time spent and (when we get a little bit more advanced) on what kind of mistakes are made
most often.
"""

"""
Then there's the question of how to build exercises in the first place.
I think the best approach is to start from a simple solution, and then apply a couple of 
random splitting rules. This has the additional advantage that the computer can give a 
hint at every step, because the student is just running through the procedure from the 
other direction. (One potential disadvantage is that decompositions/compositions that 
require two or three steps before they make the expression easier won't be provided 
in the exercises. But I think we can code this in too.)

So e.g. for a solution x^10, we can build up an exercise like so:
"""

solution = (x, 10)
op = random.choice([operator.mul, operator.div, operator.add, operator.pow])

base, power = solution

if power % 2 == 0:
    base = random.choice([-1, 1]) * base

if op == operator.mul:
    a = random.randint(-power * 2, power * 2)
    b = power - a
    (base ** a, base ** b)

nodes = []
if op == operator.pow:
    for factor, times in factorint(power).items():
        # consider splitting into parts, e.g. 2^2 * 2 instead of just 2^3=8
        # alternatively, consider merging, e.g. 30 = 2*3*5 but also 6*5 or 10*3
        if times > 1:
            left = random.randint(0, times)
            right = times - left
            nodes.append((base, factor*left), (base, factor*right))
        else:
            nodes.append((base, factor*times))

if op == operator.div:
    b = random.randint(-power * 2, power * 2)
    a = power + b
    (base ** a, base ** b)

"""
Now at this point things are still easy, but go through a couple of iterations of this, 
and you get exercises that are quite involved. (You get a tree structure, and you 
randomly decide whether to keep a node as-is or whether to further expand it, and you
can just keep on doing this, so some nodes will go quite deep, others won't.)

Expansions can operate on a single node or a group of nodes -- from the point of view
of the algorithm this is the same thing, so this will allow us to make very rich exercises
quite easily.

Perhaps easiest in reverse Polish notation or something similar.

Of course, this is just powers; we'll also want expansions, factoring etc.
"""

expression = (operator.add, (operator.mul, 5, (operator.pow, 10, 3)), 33)

# TODO: also evaluate special cases where variables cancel out
# (we should be able to do this without needing a full-blown CAS)
def evaluate(expr):
    if not isinstance(expr, tuple):
        return expr

    op, data = expr[0], expr[1:]
    return op(*list(map(evaluate, data)))

OPS = {
    '^': operator.pow, 
    '*': operator.mul,
    '/': operator.truediv,
    '+': operator.add,
    '-': operator.sub,
}

OP_SYMBOLS = {value:key for key, value in OPS.items()}

# TODO: we can probably cut down on the parentheses a bit by taking into account
# the order of operations; nevertheless, this works
# 
# TODO: write as LaTeX instead, which we can then render online with KaTeX
def write(expr):
    if not isinstance(expr, tuple):
        return str(expr)
    op, a, b = expr
    return " ".join(['(' + write(a), OP_SYMBOLS[op], write(b) + ')'])



# note: if you set difficulty to 1, the confusion process
# will go on indefinitely
DIFFICULTY = 0.5

"""
TODO:

- associative: reorder expressions so not everything that cancels is right next to each other
- distributive: distribute expressions (not all, but some)
    e.g. 2(x+y) into 2x + 2y
    e.g. 10^5+4 into 10^5 * 10^4
- merge expressions if they respect the order of operations (add, 2, 3, 4, 5)

it would be better to penalize as we go deeper, which is easy to do by adding a difficulty kw 
argument and subtracting from the difficulty each run -- but keeping this as is for now, 
to keep the code simple; the ideal generator would have a fixed depth/difficulty, and the 
random generator is only to decide *where* to add depth
"""

def number(low, high):
    return random.randint(low, high)

def variable(low, high):
    if distributions.bernoulli.rvs(0.25):
        return random.choice(list('abcdefghijklmnopqrstuvwzyx'))
    else:
        return number(low, high)

def negate(v):
    if isinstance(v, str):
        return '-' + v
    else:
        return -v

def expand(expr):
    if not isinstance(expr, tuple) or not expr[0] == operator.pow:
        return expr

    _, base, power = expr

    if isinstance(base, tuple) and power == 2:
        op, a, b = base

        # I wonder, though I know about how minus is usually defined
        # not as a separate operator but as negation, whether it 
        # would make sense for *our purposes* the introduce a 
        # subtraction operator?
        if op == operator.add:
            left = (operator.pow, a, 2)
            # thus far we've been assuming 2-arity 
            middle = (operator.mul, 2, (operator.mul, a, b))
            right = (operator.pow, b, 2)
            return (operator.add, (operator.add, left, middle), right)
    else:
        return expr

# it'd be really cool if we could do this as a sort of inverse operation, 
# that is, we couple expand and factor, so that factor knows it can operate
# in things that have output like what `expand` produces and vice versa
# 
# Haskell would probably be really neat for this, but I need this to work
# in JavaScript so no dice.
def anything(expr):
    return True

# Perhaps a way to register patterns?
operators = (operator.mul, operator.div, operator.add)

expansion = (operator.add,
    (operator.pow, anything, 2),
    (operator.mul, anything, 2),
    (operator.pow, anything, 2),
    )

# Or should patterns be exact?

def substitute(expr, **mapping):
    raise NotImplementedError()

# evaluating an expression means first substituting
# variables and then simplifying it (simplification
# should reduce all operations not involving 
# variables to numbers)
def evaluate(expr, **mapping):
    raise NotImplementedError()

def find_symbols(expr):
    raise NotImplementedError()

def equals(left, right):
    # TODO: try for symbolic equivalence first, before
    # resorting to numeric methods
    symbols = find_symbols(left).union(find_symbols(right))
    probes = [{symbol: random.randint(-1000, 1000) for symbol in symbols} for i in range(10)]
    matches = [isclose(evaluate(left, probe), evaluate(right, probe)) for probe in probes]
    return all(matches)



# Or maybe the former was superfluous and this is better?
distrib2nd = (operator.add,
    (operator.add,
        (operator.pow, 'x', 2),
        (operator.pow, 'y', 2)),
    (operator.mul,
        (operator.mul, 'x', 'y'), 2)
    )

# we could decompose 2*5*7 into primes and then see if
# we can use these primes to reconstruct a and b (but exclusively
# of course you can't reuse a factor)... but probably the easiest
# approach is to just divide the number by two, then by x, then 
# see if you get y
# (operator.mul, 2*5*7, 2),
example = (operator.add, 
    (operator.add, 
        (operator.pow, 5, 2),
        (operator.pow, 7, 2)),
    (operator.mul, 2, 
        (operator.mul, 7, 5)),
    )

match(example, distrib2nd)



# TODO: 




"""
It is really important to differentiate between two concepts here: 

1) matching of trees -- this is all about an exact match of a pattern
2) equality calculation -- this can involve comparing trees (and different
   forms of those trees) but ultimately what makes two expressions equal is
   if they have the output, as evaluated over a number of sample points

Totally different things, useful for totally different reasons.

1) figuring out what kind of expression we are dealing with so we can 
   simplify it or confuse it further
2) establishing equality between different expressions, useful to 
   give instant feedback when solving an exercise
"""

import types
import operator

operators = (operator.pow, operator.mul, operator.truediv, operator.add, operator.sub)

# TODO: return should not just return true/false but also any variables that were filled in
# I also imagine that we might return not just a final true/false, but also 
# a tree of e.g. (True, True, (True, True, False)) so that we can correct not just 
# a faulty line but point out exactly what's wrong about it -- at least in some cases
# -- also the state of any matched variables perhaps?

# so it actually gets even trickier, re: pattern matching, because e.g.
# a pattern x^2 might be satisfied by 9, given 3^2 = 9
def flip(l, i, j):
    flipped = list(l)
    flipped[i], flipped[j] = flipped[j], flipped[i]
    return type(l)(flipped)

def commute(expr):
    # TODO: flip for subtraction is (operator.add, neg(a), b)?
    # TODO: flip for division is (operator.mul, (operator.pow, b, -1), a)?
    if isinstance(expr, tuple):
        op, a, b = expr
        if op in (operator.add, operator.mul):
            return flip(expr, 1, 2)
        else:
            return expr
    else:
        return expr

from copy import deepcopy


def cmp(a, b):
    return (a > b) - (a < b)

def score(atom):
    return (types.BuiltinFunctionType, tuple, str, int, float).index(type(atom))

def compare(a, b):
    scored = cmp(score(b), score(a))

    if scored == 0:
        if a in operators:
            return operators.index(b) - operators.index(a)
        elif isinstance(a, tuple):
            for left, right in zip(a, b):
                comparison = compare(left, right)
                if comparison != 0:
                    return comparison
            return 0
        else:
            return cmp(a, b)
    else:
        return scored

def commutative(expr):
    if isinstance(expr, tuple) and expr[0] in (operator.add, operator.mul):
        return True
    else:
        return False

# the canonical format is chosen in such a way that tuples and variables
# will be processed first, making the matching process much easier;
# it also means we don't have to worry about the commutative
# property in our matcher
def canonical(expr):
    if isinstance(expr, tuple):
        expr = tuple(map(canonical, expr))
        if commutative(expr) and compare(expr[1], expr[2]) < 0:
            return commute(expr)
        else:
            return expr
    else:
        return expr

import itertools
import functools

def splat(fn):
    @functools.wraps(fn)
    def splatted(*vargs, **kwargs):
        return fn(*sum(vargs, ()), **kwargs)
    return splatted


def match(expr, pattern, state=None):
    """
    Some care must be taken in how patterns are defined:

    - if we compare x to a number, and we don't yet have 
      x in our state, we won't get a match
    - if x = 3y and y = 5, no match will occur
    - (operator.pow, 'x', 2) should not just match 
      a matching tuple, it should also match any number,
      ditto for multiplications (because any number is a second
      power of some other real number, etc.)

    I hope to improve the algorithm in the future, but I think 
    it's mostly okay for now, because we do not intend the 
    matcher to be a real CAS, mainly something we can use to 
    have a more elegant system to construct exercises

    (We look at a current expression and we match it up with
    "opportunities" to do something interesting with it.)
    """

    expr = canonical(expr)
    pattern = canonical(pattern)

    if state is None:
        state = {}

    comparable = type(expr) is type(pattern)
    abstract = type(expr) is str or type(pattern) is str

    if not (comparable or abstract):
        return False

    if isinstance(pattern, tuple):
        return all(list(map(splat(match), zip(expr, pattern), itertools.repeat((state, )))))
    elif callable(pattern):
        if pattern in operators:
            return pattern is expr
        else:
            return pattern(expr)
    elif pattern == expr:
            return True
    elif pattern in state:
        return state[pattern] == state.get(expr, expr)
    elif isinstance(pattern, str):
        state[pattern] = expr
        return True
    else:
        return False


ex = (operator.mul, (operator.add, 2, 5), 5)
pat = (operator.mul, 'x', (operator.add, 3, 'x'))
print(match(ex, pat)) # should be false
print('---')
ex = (operator.mul, (operator.add, 5, 3), 5)
print(match(ex, pat)) # should be true


"""
So now we've got one big thing out of the way: a first stab at a matcher.

Now we should get the matcher to return the variables that it found, 
so that we can then use these in a `fill` function.

We then match on one pattern, and use the variables that our matcher returns
to fill in another pattern. The stereotypical use case:

    (a+b)^2  --> (a^2 + 2ab + b^2)

but it could also be used in the other direction to build a `simplify` function.

Finally the confusor can also use it to do e.g.

    0 --> anything * 0
    1 --> ...
    a/b --> (r * a) / (r * b)

and so on.
"""


"""
Anyway, the whole point of this yak shaving expedition is that once all of 
this infrastructure is built, 

(1) we get a simplification algorithm "for free"
(just run through all of the operations we know that we consider to be 
simplifications, like factoring, evaluating expressions without variables,
replacing x^0 by 1 and so on), 

(2) a simplification algorithm is a large part of an equation solver

(3) this pattern matching approach can be expanded to deal with different 
contexts, e.g. differentiation is simply a question of adding a new 
set of strategies (apply simplifications, apply differentiation, rinse
repeat until every part of the expression is marked as differentiated,
then do a final round of simplifications.)

(4) It simplifies the confusion algorithm.
"""

from functools import reduce

# pseudocode, doesn't include a couple of important things like recursion
# and configurable depth / difficulty, but you get the idea
def confuse2(expr):
    matches = [match(expr, pattern) for pattern in patterns]
    choices = reduce(operator.add, [[pattern] * weights[pattern] for pattern in matches])
    pattern = random.choice(choices)
    return apply(pattern, expr)


def factor(expr):
    is_tuple = isinstance(expr, tuple)
    is_add = expr[0] == operator.add

# I'm still not sure whether I want to stick to two-arity; 
# it simplifies a lot of the tree operations but complicates others, 
# in any case, if I do stick with two-arity, this would be a method to
# keep it manageable.
def multiply(*values):
    head, tail = values[0], values[1:]

    if not len(tail):
        return head
    else:
        return (operator.mul, head, multiply(*tail))

def distribute(multiplier, expr):
    op, a, b = expr
    if op == operator.add:
        return (operator.add, multiply(multiplier, a, b))
    elif op == operator.mul:
        return multiply(multiplier, expr)
    else:
        return (operator.mul, multiplier, expr)

def confuse(expr):
    """
    I think it's okay to keep this monolithic for now, but I'm seeing a system
    popping up where you have a number of "opportunities" (things you can 
    do with an expression provided it is of a certain nature) that we wish to
    grab with a certain probability (some more often than others).

    No rush, but we can probably turn this into some lovely, elegant code.
    """

    if not distributions.bernoulli.rvs(DIFFICULTY):
        return expr

    if distributions.bernoulli.rvs(0.2):
        coeff = variable(-5, 5)
        a = (operator.mul, coeff, expr)
        return (operator.div, confuse(a), confuse(coef))

    if expr == 0:
        if distributions.bernoulli.rvs(0.5):
            a = variable(-100, 100)
            return (operator.mul, confuse(a), confuse(0))
        else:
            a = variable(-100, 100)
            return (operator.add, confuse(a), confuse(negate(a)))
    elif expr == 1:
        a = variable(-100, 100)
        return (operator.pow, confuse(a), confuse(0))
    elif isinstance(expr, tuple):
        # we really should prefer these kinds of easy powers, perhaps 
        # generate powers using a discretized normal distribution 
        # centered on 1?
        op, data = expr[0], expr[1:]
        if op == operator.pow:
            base, power = data

            if distributions.bernoulli.rvs(0.5):
                return expand(expr)

            # here it gets tricky because we can't assume that the power is a number
            if not isinstance(power, (int, float)):
                return (op, confuse(base), confuse(power))
            else:
                a = number(*sorted([-power * 2, power * 2]))
                b = power - a
                return (operator.mul, (op, confuse(base), confuse(a)), (op, confuse(base), confuse(b)))
        else:
            return (op,) + tuple(map(confuse, data))
    elif isinstance(expr, (int, float)):
        # TODO: we can do some interesting things with squares and square roots etc. too
        if distributions.bernoulli.rvs(0.5):
            a = number(*sorted([-expr, expr]))
            b = expr - a
        else:
            a = expr
            b = negate(expr)
        return confuse((operator.add, a, b))
    else:
        return expr




precedence = {
    '^': 4,
    '*': 3,
    '/': 3,
    '+': 2,
    '-': 2,
}

# TODO: better tokenization (contiguous alphanumeric characters represent a function)
# TODO: handling functions
def shunt(s):
    output = []
    ops = []

    for token in s:
        if token == '(':
            ops.append(token)
        elif token == ')':
            while ops[-1] != '(':
                output.append(ops.pop())
            ops.pop()
        elif token in precedence.keys():
            while len(ops) and ops[-1] in precedence and precedence[token] <= precedence[ops[-1]]:
                output.append(ops.pop())
            ops.append(token)
        else:
            output.append(token)

    while len(ops):
        output.append(ops.pop())
    return output

# TODO: change to working with operator strings instead of functions (will have to adapt
# `match` and the functions it relies on.)
def nest(polish):
    stack = []

    for token in polish:
        if token in precedence:
            stack.append((OPS[token], stack.pop(-2), stack.pop(-1)))
        else:
            stack.append(token)

    return stack.pop()

def cast(s):
    if s.isdigit():
        return int(s)
    elif re.match(r'[\d\.]+', s):
        return float(s)
    else:
        return s

def parse(s):
    tokens = re.findall(r'(\w+|[\d\.]+|[\(\)*/+-\^])', s)
    tokens = map(cast, tokens)
    return nest(shunt(tokens))




zero_identity = ('0', '0 * v')
distribute_2nd = ('(a+b)^2', 'a^2 + 2*a*b + b^2')

def parse_strategies(*strategies):
    return {parse(left): parse(right) for left, right in strategies}

strategies = parse_strategies(
    zero_identity,
    distribute_2nd,
    )

def invert(d):
    return {v: k for k, v in d.items()}

simplifications = invert(strategies)


# TODO: actually fill in with the right values!
# (finish the `fill` function and modify the `match` function so it returns its state)
def simplify(expr):
    for replacement, pattern in strategies.items():
        print(expr, pattern)
        if match(expr, pattern):
            expr = replacement
    return expr

# TODO also: a more intelligent writing algorithm, that only puts parentheses where they are needed, 
# (and ideally also has a "fraction mode / LaTeX mode")


# and of course, the neat thing is that our confusor does not care whether it's working with numbers or variables
confuse(expression)
confuse((operator.pow, 'a', (operator.pow, 33, 'c')))

"""
we're still missing a number of things
- factorization
- adding in terms that cancel out (e.g. multiply by 9^0, add 5 somewhere and remove it somewhere else, etc.)
- ...
now to expand this to equations, we would have to
1) have two expressions (left and right side)
2) encode the rules for switching things between sides
3) switch and confuse

The switching part might get a tad hairy because we have to peek inside expressions and modify them, 
rather than just stacking things like we did for the confusion (otherwise you're giving away the game)

e.g.

    ('x') == (operator.mul, 33, 'y')
    (operator.div, 'x', 'y') == 33

Strategies include: 

- move things to the other side (+-)
- divide by something (here, as with confusion, it doesn't have to be something that's already present:
  we can "make something up" that has a zero overall effect, e.g. divide by 345 on both sides, and then confuse(345)
  to make things interesting)

One thing we can probably do is just

    confuse(left) == confuse(right)

but this in itself is not sufficient, as a good equation includes the variable on both sides, and so just building
up the two expressions entirely independently will produce exercises that are not very challenging or at the very 
least don't require the "do the same thing to both sides" rule.
"""



"""
Would it be easy(-ish) to code up a Gaussian elimination algorithm? And if we do, is Gaussian elimination generally
the fastest/most efficient approach for a person rather than a computer? This, and a similar algorithm for simplifying
single expressions (rather than equated expressions) would allow us to give students a hint when completing an exercise
that does not rely on them solving the exercise in exactly the inverse way that we generated it. There might be cases
when this reverse-engineering entails additional steps, and there might be cases when the steps are performed in 
a more roundabout way or whatever, but you still want to give people an idea of "this is what you could do next,
from where you are right now".

Cherry on top would be if we could score the difficulty of an expression by how many steps it is removed from the solution, 
so we can say "you know, what you just did was perfectly right, but actually it gets you farther from the solution rather
than closer."
"""

def solve(left, right, dependent):
    """
    (The dependent variable is the variable for which to solve.)

    The rules of Gaussian elimination again, to refresh my memory:

    * Type 1: Swap the positions of two rows.
    * Type 2: Multiply a row by a nonzero scalar.
    * Type 3: Add to one row a scalar multiple of another.

    Of course this in and of itself does not tell us anything about opportunities to apply
    these operations.

    First off, 

        x = y <=>
            x - y = 0
            -x + y = 0

    (Gaussian elimination is mainly an algorithm for solving systems of equations, but
    am I so wrong in thinking that it should work just as well for a single equation?
    It does however require that we reduce every equation to a linear one, that is, 
    to a sum of variables.)
    
    My main worry right now is: is it possible to solve an equation and/or simplify an expression
    by looking only one level deep? At most two levels deep?

    e.g. 

        (<function _operator.add>,
         (<function _operator.pow>, 'a', 2),
         (<function _operator.mul>, 2, (<function _operator.mul>, 'a', 'b')),
         (<function _operator.pow>, 'b', 2))

        <=>

        (operator.pow, (operator.add, 'a', 'b'), 2)

    (We must look at the first level, and then whether the second level follows a pattern.)

    If more is needed, things might get hairy. Though on the other hand, every "opportunity"
    could simply register a function that looks at an equation and returns True/False depending
    on whether it applies.

    Keeping things manageable might depend more on creating a good DSL than on only operating
    one level deep. For example earlier we defined `distribute` which, for a sum, does the
    fairly complicated operation

        (operator.add, (operator.mul, multiplier, a), (operator.mul, multiplier, b))

    but reduces it to

        distribute(multiplier, expr)

    Turning difficult operations into elementary ones might prove to be a good way forward.

    That said, as with chess, I can imagine that for some simplifications our algorithm
    will have to go through a tree of possible simplifications and might only be able 
    to decide which is the one that is easiest to manage after having gone a few levels
    deep. This is ultimately no problem, but the more deterministic we can keep things, 
    the better. (I remember in my logic courses that there was a heuristic that always
    worked, no exceptions. There might sometimes be a faster way to solve the problem, 
    but the heuristic was always right.)

    In any case, the great thing about our solver is that (1) meh, we don't really need it, 
    it would just be nice to have and fun to build, (2) it doesn't need to be able to solve
    anything and everything, just the exercises we generate and (3) even if I don't manage to 
    create a working solver, well, we still have our exercise generator and that works
    fine on its own!

    Note also that the real goal is not so much solving the equation as solving it and, 
    every step of the way, being able to show what exactly happened and why this is a 
    valid step.
    """
    pass