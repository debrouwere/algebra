
###
statement = '2 * (3 + 5)^2 + 2'
statement = '5^2 + 2 * 5 * 10 + 10^2 + 22'
statement = '(3/2 * ((3 + 2) * 4)^(a*2) + 5) / (22+2)'
###

#show simplify parse statement

#for i in _.range(10)
#    show confuse (parse 'a + b^2'), 5

#for i in _.range 5
#    show conjure i, 2

###
console.log calculate ['+', 'a', ['*', ['-', 10, 12], 7]]

for i in _.range 5
    conj = conjure 3, 2
    calc = calculate conj
    expr = confuse calc, 2
    show conj
    show calc
    show expr
    console.log '\n'
###

###
show statement
show parse statement
show write parse statement
console.log writeLaTeX parse statement
###

###
statement = parse 'a + (22 * b)^c + 5^(9^c)'
console.log variables statement
show statement
show substitute statement, 
    a: 1
    b: 2
    c: 3
###

###
a = parse '(a+b)^2'
b = parse 'a^2 + 2*a*b + b^2'
c = parse 'a^2 + b^2 + 4*a*b / 2'
d = parse 'a^2 + b^2'

console.log yes, test a, b
console.log yes, test a, c
console.log no, test a, d
console.log yes, test a, a

console.log depth parse '(2 * a + b * 3/2)^2'

###

# Alright, now we have everything in place!

for i in _.range 5
    c = conjurePower()
    console.log c
    console.log confuse c, 5
    console.log '\n'

###
solution = calculate conjure 2, 1
# TODO: in principle, we should also be able to work with e.g. (x+y)^10,
# because it can be reduced down to (x+y)^2^5
solution = parse '(x+y)^2'
# hmm, the main problem with the confusor at the moment seems to 
# be that it does not recurse properly -- part of it is probably that in this
# context, we're not so much talking about "recursion" as we are about
# splitting one expression into multiple others
# (e.g. x^2 into x^5/x^3)
question = calculate confuse solution, 10
console.log '(solution)', write solution
console.log '(question)', write question
console.log test solution, parse '(x+y)^2'
###


###
# proper precedence parsing for equal precedence operators
# (first divide, then multiply)

console.log parse '(a + 22 + b + c) / 22 * b'
console.log parse 'a^2 + 2 * a * b + b^2'
console.log complexity parse 'a^2 + 2 * a * b + b^2'
###

###
# parse negative numbers
console.log tokenize '-b - -7'
console.log tokenize '(-x)^2'
show parse '-b^2 + (-x)^2'
console.log writeLaTeX parse '-1 * b'
###