// Generated by CoffeeScript 1.10.0
(function() {
  var findMisconceptions, match, misconceptions, patterns, ref, toString;

  ref = require('./parser'), patterns = ref.patterns, match = ref.match;

  toString = require('./writer').toString;

  misconceptions = {
    'misapplication of distributivity': patterns({
      '(a + b)^c': 'a^c + b^c'
    }),
    'misapplication of power to a power': patterns({
      'a^(b^c)': 'a^b^c',
      'a^(b+c)': 'a^b^c'
    }),
    'misapplication of multiplying different powers of the same base': patterns({
      'a^(b*c)': 'a^b * a^c'
    })
  };

  findMisconceptions = function(prev, curr) {
    var i, issue, issues, left, len, name, pattern, ref1, right;
    issues = [];
    for (name in mistakes) {
      pattern = mistakes[name];
      for (i = 0, len = pattern.length; i < len; i++) {
        ref1 = pattern[i], left = ref1[0], right = ref1[1];
        issue = {
          name: name,
          prev: toString(prev),
          curr: toString(curr)
        };
        if ((match(prev, left)) && (match(curr, right))) {
          issues.push(issue);
        }
        if ((match(prev, right)) && (match(curr, left))) {
          issues.push(issue);
        }
      }
    }
    return issues;
  };

  module.exports = {
    misconceptions: misconceptions,
    findMisconceptions: findMisconceptions
  };

}).call(this);