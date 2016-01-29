# Current issues with the CAS pattern matcher

**Note:** the issues discussed below are mostly academic. For the purposes of presenting students with algebra exercises and helping them solve it, we don't need an all-powerful pattern matcher, because:

(1) A certain type of exercise can be computer-generated, template-based or even hand-crafted if necessary. Template-based seems most fruitful and does not require any pattern matching at all, but rather just filling in a pattern we craft ourselves. There is really no need to automate everything at the expense of other important pedagogical features.

(2) Being able to tell a student why they're wrong is nice, but it's the immediate feedback of the expression tester (which is fully functional) that'll really kickstart learning, perhaps together with a mechanism for adjusting the difficulty of the exercises based on previous performance.

That said, a more sophisticated computer algebra system does provide more opportunities in both generating and evaluating exercises, the latter with the combined power of a good matcher and differ. But perhaps more importantly: CAS systems are recursion nirvana -- seriously fun to tinker on!


### Commutativity

How can we match the binomial pattern in an expression like `a^2 + b^2 + 55 * 99^3 + 2 * b * a`?

#### Adjacency

While this looks like a flat structure, in reality it's a tree where the `2 * b * a` terms is a couple of levels down from the other terms. But that's just how the internal representation works, so maybe we need a good algorithm for moving between levels within the bounds set by the commutative property. We could build a function `adjacent` which returns all terms that can interact with the current term, so that e.g. all the terms adjacent to `x` in `x + 5 + 7` are 5 and 7, and all the terms adjacent to `x` in `5 + 2xy` are 2 and `y`.

Once we've found a match for one part of an expression, we continue matching not on the rest of the tree as-is, but on all adjacencies, and if that still matches, on any remaining adjacencies. (Adjacency, or whatever the mathematical term is, is a symmetrical concept, which makes this easy.)

#### Canonical ordering

Currently, individual expressions have a canonical ordering, such that e.g. variables always come before numbers, and everything is sorted in alphabetical order or reverse aphabetical order. Perhaps this system can be expanded to the tree as a whole: each expression has a weight assigned, and we order expressions, again within the bounds set by the commutative property. This wouldn't be a solution in itself, for example it still wouldn't allow us to match `a^2 + b^2 + 3 * a * b + 2 * a * b` where the algorithm neatly put the higher-magnitude term `3ab` before the lower-magnitude term `2ab` but perhaps it can help.


### Unknowns can be expressions

Any unknown in a pattern, let's say `x`, can be matched by any part of any expression.

1. `(a + b + c)^2` matches `x^2`
2. `5` matches `x^2 + y^2` too, after all, any value can be written as a sum of unconstrained unknowns

The first problem can be dealt with. The larger the initial expression that is matched, the fewer the places where that expression can appear again, so computationally that's no big deal.

The second problem might have to be dealt with heuristically, or not at all. Anything might be able to match anything else, but this is not a useful definition of pattern matching. We want to match with expressions that might be able to help us simplify an expression or spot a mistake in a student-provided answer, and there is no room for mathematical pedantry.

Depending on how liberally we match, multiple patterns might be matched at the same time, which introduces another little bit of complexity: either we explore the consequences of each match (in the context of a solver -- the matcher itself doesn't care how you use it) or we treat certain kinds of matches preferentially depending on their power to simplify. (Weight each pattern manually or decide based on a complexity metric.)


### Identities

If we allow unknowns to stand for expressions, `(4a^2)^2` would match `x^2`. So far so good, that's still pretty straightforward. But what about `(2 + 14) * a^(3 + 1)` and `2 * a^2 * 8 * a^2`?

One part of the solution is to simplify expressions before matching on them and to calculate everything that can be calculated, which would at least take care of those absurd sums of constants.

Currently our simplification routine doesn't collect terms, which is something that it probably should be able to do -- simple things like changing `aaa` into `a^3`.

Another part of the solution could be figuring out an elegant `satisfies` interface, such that `a + 10` matches an `x + 4` pattern because 10 can be split into 6 and 4. For multiplication, factoring every constant into its constituent primes can help here.

Brute force is an option too: evaluate an expression at a range of points and see if it matches the other expression. But in this particular case that doesn't seem like such a wise idea to me, partly because of the combinatorial explosion and partly because we must remember that the end goal is to explain the process to the student, so "this complex expression is actually just x^2, trust me on this" is not acceptable, but "look, you can simplify this to that, and then it matches this pattern" is.

_Not_ solving this problem is more in line with what we're trying to accomplish.

In any case, a CAS should work one step at a time, exhausting all its options, trying a bunch of things until other possibities open up. This computational approach is much more tenable than a mathematical one, as mentioned before. So to the extent that we wish to work with these identities, first we try to match, then we try to see if we can't swap things around to enable a match, then we match. This is how we'd present it to the user.


### Going backwards to go forward

Sometimes you must factorize to solve an equation or simplify a pattern, sometimes you must expand. Sometimes it's best to calculate everything that you can, but sometimes keeping those constants or expressions just as they are makes things easier down the road.

Reasoning a couple of steps ahead (walking the space), together with good heuristics for what to try first (strategy per strategy rather than brute force of all permutations), are what we need here.

This problem arises in particular when evaluating user-provided problems and figuring out not just a way to solve them, but the most elegant way to solve them -- the solution a human would prefer. For problems we generate ourselves, we have a much nicer mechanism for what the intermediate steps should be (walk the generation process in reverse) but even there, if the student decides to take another tack, we would like to be able to advise on what their next step should be given what they've done now (even if that advice is sometimes "this is a dead end, just go back one step.")

I don't think it's reasonable to expect a CAS system to be able to solve any and all of these kinds of exercises, but the high school curriculum does include simple variants and a fuzzy matcher that can shift around an expression one or two permutation steps to see if it leads to a match, might not be impossible: it'll be brute force, but brute force on fairly shallow trees.
