# An overview of common high school pre-algebra and algebra exercises

Many high school pre-algebra and algebra exercises are mathematically trivial but arithmetically complex. Calculating a large polynomial or factoring an expression are mostly mechanical operations where you just shuffle things around until you get what you want, but there is no tolerance for mistakes and a lot of opportunities to make them.

Most exercises below don't need unknowns to be challenging to students. The outcome can be a constant. Correctly applying the order of operations and keeping intermediate steps in your head is practice enough.

I'm particularly interested in the computational side of things: if you know how to manipulate expressions really well, everything else should be easier. So while people usually think of solving equations and the like when they think of algebra, from an educational point of view getting the arithmetical aspect of it down pat feels more essential to me -- though admittedly that's just a theory.


## Basic techniques

1. get to know the operations

* commutative, associative, distributive
* apply the order of operations on complex expressions
  * e.g. `c^4 c^2 = c^6`, `-4d - 4 + 4d = -4`
  * e.g. `-(5 + (-x + (-x)^2)^3) * 5`
* negatives
  * `- * +` and `- * -`
  * `-(a - b) = b - a` and `-(b - a) = a - b`
* working with powers
  * e.g. `(x^3)^2` vs. `(x^2 * x^3)` vs. `(x^3 + x^2)`
  * this can be tricky, because intuitively you might want to reduce these different powers to a single factor, so metacognition is important here)
  * e.g. `1/x^-3` = x^3`, `x^(-2/3) = 1/qrt(x^2)`
  * e.g. `x^(1/2) = sqrt(x)`
  * e.g. `a / b^3 = a * b^-3`
  * e.g. what is the solution to x / (x + y^3)^2
  * e.g. how can you simplify `1 / x^(-3/2)` such that it does not have any negative powers or fractional powers, or conversely, how can you write a bunch of powers and roots as a single fractional power
  * the difference between `-x^2` and `(-x)^2`
  * remove square roots or negative powers from denominators, e.g. from `1/sqrt(2)` to `sqrt(2)/2`
* extract wholes from square roots and squares
  * e.g. `sqrt(40) = 2 sqrt(10)`
  * e.g. `4x^2 + 9 = (2x)^2 + 3^2`

2. distributivity and other operations on polynomials
  * e.g. `3(2x + 5)`, `(2x + 5) - 3`, `(2x + 5)/3`
  * e.g. `(2x + 5) / (3x + 7)`
  * nothing really new, but it gets confusing really fast because you need to keep a lot in working memory (tricks like assigning each factor to a variable and then filling in work well)

3. expanding and factoring
   * binomial products: (a+b)^2, (a-b)^2, (a+b)(a-b)
     * e.g. straight-up: just expand everything you can, and simplify while you're at it
     * e.g. more involved: intelligently expand or factor to get rid of certain terms and simplify the final expression

4. cross-multiplication and addition/subtraction with fractions
   * `a/b + c/d = (ad + bc) / bd`
   * `(a + b)(c + d) = ac + ad + bc + bd`
   * `(a + b)(c - d) = ac - ad + bc - bd`
   * `(a - b)(c - d) = ac - ad - bc + bd`
   * recognize that these apply to simpler variants too
      * e.g. `(a+b)(a+b) = a^2 + ab + ba + b^2 = a^2 + 2ab + b^2`
      * e.g. `(x+a)(x+b) = x^2 + xa + xb + ab = x^2 + (a + b)x + ab`


If we were to roughly catalog these techniques, I'd say there are three big categories

* calculations
    * order of operations
    * distributive, commutative, associative properties
    * special attention to fractions (trips people up if they don't see the link with division and negative powers), double negatives, negative numbers raised to a power etc.
    * memorized formulas to speed things up: the binomial formulas, cross-multiplication and others
* identities
    * expansion, factoring and other simplifications
    * extract whole numbers from roots and powers
* equations

## Further techniques

* logarithms and exponentials
* summation and product notation
* simplify expressions with sin, cos and tan (using Pythagoras' theorem and other identities)

Solving first-order and second order equations could be another interesting avenue. On the one hand it'd mean an entirely new addition to the code base, on the other hand it's a solved problem (Gaussian elimination)

It also wouldn't be that much of a stretch to add differentiation and integration if the pattern matcher and conjuring/generation mechanism are up to scratch -- it's just rules for two more operators.

## Exercise types

There are different ways to quiz students on whether they do or do not know a technique.

* solve or calculate
    * technique in isolation
    * technique in a different context
      * e.g. solving `x^4 + x^2` by realizing that your unknown is not `x` but `x^2`
    * everything we've learned so far
* right or wrong (good for metacognition)
* different ways of writing the same thing
