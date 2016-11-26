import 'error_handler.dart' show EsprimaError, ErrorHandler;
import 'options.dart';
import 'scanner.dart'
    show
        Comment,
        ScannedToken,
        ScannedTokenLocation,
        ScannedTokenLocationPart,
        Scanner;
import 'token.dart' show Token, TokenName;

const List<String> _beforeFunction = const [
  '(', '{', '[', 'in', 'typeof', 'instanceof', 'new',
  'return', 'case', 'delete', 'throw', 'void',
  // assignment operators
  '=', '+=', '-=', '*=', '**=', '/=', '%=', '<<=', '>>=', '>>>=',
  '&=', '|=', '^=', ',',
  // binary/unary operators
  '+', '-', '*', '**', '/', '%', '++', '--', '<<', '>>', '>>>', '&',
  '|', '^', '!', '~', '&&', '||', '?', ':', '===', '==', '>=',
  '<=', '<', '>', '!=', '!=='
];

class Reader {
  final List<String> values = [];
  int curly = -1, paren = -1;

  /// A function following one of those tokens is an expression.
  bool beforeFunctionExpression(String t) => _beforeFunction.contains(t);

  /// Determine if forward slash (/) is an operator or part of a regular expression
  /// https://github.com/mozilla/sweet.js/wiki/design
  bool isRegexStart() {
    final previous = values.last;
    bool regex = previous != null;

    switch (previous) {
      case 'this':
      case ']':
        regex = false;
        break;

      case ')':
        final check = values[paren - 1];
        regex = ['if', 'while', 'for', 'with'].contains(check);
        break;

      case '}':
        // Dividing a function by anything makes little sense,
        // but we have to check for that.
        regex = false;

        if (values[curly - 3] == 'function') {
          // Anonymous function, e.g. function(){} /42
          final check = values[curly - 4];
          regex = check.isNotEmpty ? !beforeFunctionExpression(check) : false;
        } else if (values[curly - 4] == 'function') {
          // Named function, e.g. function f(){} /42/
          final check = values[curly - 5];
          regex = check.isNotEmpty ? !beforeFunctionExpression(check) : true;
        }
    }

    return regex;
  }

  void push(ScannedToken token) {
    if (token.type == Token.Punctuator || token.type == Token.Keyword) {
      if (token.value == '{')
        curly = values.length;
      else if (token.value == '(') paren = values.length;

      values.add(token.value);
    } else
      values.add(null);
  }
}

class Tokenizer {
  final List<Comment> buffer = [];
  ErrorHandler errorHandler;
  final Reader reader = new Reader();
  Scanner scanner;
  bool trackLoc, trackRange;

  Tokenizer(String code, {EsprimaOptions config}) {
    errorHandler =
        new ErrorHandler(tolerant: config != null && config.tolerant);
    scanner = new Scanner(code, errorHandler,
        trackComment: config != null && config.comment);

    trackRange = config != null && config.range;
    trackRange = config != null && config.loc;
  }

  List<EsprimaError> get errors => errorHandler.errors;

  Comment nextToken() {
    if (buffer.isNotEmpty) {
      final comments = scanner.scanComments();

      if (scanner.trackComment) {
        for (Comment e in comments) {
          final value = scanner.source.substring(e.slice[0], e.slice[1]);
          final comment = new Comment(
              type: e.multiLine ? Comment.BLOCK : Comment.LINE, value: value);

          if (trackRange) comment.range = e.range;

          if (trackLoc) comment.loc = e.loc;

          buffer.add(comment);
        }
      }

      if (!scanner.eof()) {
        ScannedTokenLocation loc;

        if (trackLoc) {
          loc = new ScannedTokenLocation(
              start: new ScannedTokenLocationPart(
                  line: scanner.lineNumber,
                  column: scanner.index - scanner.lineStart));
        }

        ScannedToken token;

        if (scanner.source[scanner.index] == '/')
          token = reader.isRegexStart()
              ? scanner.scanRegExp()
              : scanner.scanPunctuator();
        else
          token = scanner.lex();

        reader.push(token);

        Comment entry = new Comment(
            type: TokenName[token.type],
            value: scanner.source.substring(token.start, token.end));

        if (trackRange) entry.range = [token.start, token.end];

        if (trackLoc) {
          loc.end = new ScannedTokenLocationPart(
              line: scanner.lineNumber,
              column: scanner.index - scanner.lineStart);
          entry.loc = loc;
        }

        if (token.regExp != null)
          entry.regExp = token.regExp;

        buffer.add(entry);
      }
    }

    return buffer.removeAt(0);
  }
}

class TokenizationResult {
  final List<EsprimaError> errors = [];
  final List<Comment> tokens = [];

  TokenizationResult(List<Comment> tokens) {
    this.tokens.addAll(tokens);
  }
}
