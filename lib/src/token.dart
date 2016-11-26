// I would have preferred to just use an enum,
// but esprima uses enum initializers, so I can't.
//
// See the original: https://github.com/jquery/esprima/blob/3.1/src/token.ts
abstract class Token {
  static const int BooleanLiteral = 1;
  static const int EOF = 2;
  static const int Identifier = 3;
  static const int Keyword = 4;
  static const int NullLiteral = 5;
  static const int NumericLiteral = 6;
  static const int Punctuator = 7;
  static const int StringLiteral = 8;
  static const int RegularExpression = 9;
  static const int Template = 10;
}

const Map<int, String> TokenName = const {
  Token.BooleanLiteral: 'Boolean',
  Token.EOF: '<eof>',
  Token.Identifier: 'Identifier',
  Token.Keyword: 'Keyword',
  Token.NullLiteral: 'Null',
  Token.NumericLiteral: 'Numeric',
  Token.Punctuator: 'Punctuator',
  Token.StringLiteral: 'String',
  Token.RegularExpression: 'RegularExpression',
  Token.Template: 'Template'
};
