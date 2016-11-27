// I would have preferred to just use an enum,
// but esprima uses enum initializers, so I can't.
//
// See the original: https://github.com/jquery/esprima/blob/3.1/src/token.ts
library esprima.token;

const int BooleanLiteral = 1;
const int EOF = 2;
const int Identifier = 3;
const int Keyword = 4;
const int NullLiteral = 5;
const int NumericLiteral = 6;
const int Punctuator = 7;
const int StringLiteral = 8;
const int RegularExpression = 9;
const int Template = 10;

const Map<int, String> TokenName = const {
  BooleanLiteral: 'Boolean',
  EOF: '<eof>',
  Identifier: 'Identifier',
  Keyword: 'Keyword',
  NullLiteral: 'Null',
  NumericLiteral: 'Numeric',
  Punctuator: 'Punctuator',
  StringLiteral: 'String',
  RegularExpression: 'RegularExpression',
  Template: 'Template'
};
