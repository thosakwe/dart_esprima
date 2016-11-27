import 'assert.dart';
import 'character.dart' as character;
import 'error_handler.dart';
import 'messages.dart' as messages;
import 'token.dart' as token_type;

const String _HEX = '0123456789abcdef';
const String _OCTAL = '01234567';
final RegExp _rgxEscape1 =
    new RegExp(r'\\u\{([0-9a-fA-F]+)\}|\\u([a-fA-F0-9]{4})');
final RegExp _rgxEscape2 = new RegExp(r'[\uD800-\uDBFF][\uDC00-\uDFFF]');

int hexValue(String ch) => _HEX.indexOf(ch.toLowerCase());

int octalValue(String ch) => _OCTAL.indexOf(ch.toLowerCase());

/// Strangely enough, this seems to not always be
/// a comment at all.
class Comment {
  static const String BLOCK = 'BlockComment';
  static const String LINE = 'LineComment';

  ScannedTokenLocation loc;
  bool multiLine;
  List<int> range, slice;
  RegExp regExp;
  String type, value;

  Comment(
      {this.loc,
      this.multiLine,
      this.range,
      this.regExp,
      this.slice,
      this.type,
      this.value});
}

class ScannedToken {
  int code, end, lineNumber, lineStart, start, type;
  bool head, octal, tail;
  String literal;
  RegExp regExp;
  dynamic value;

  ScannedToken(
      {this.code,
      this.end,
      this.head: false,
      this.lineNumber,
      this.lineStart,
      this.literal,
      this.octal: false,
      this.regExp,
      this.start,
      this.tail: false,
      this.type,
      this.value});
}

class ScannedTokenLocation {
  ScannedTokenLocationPart end, start;

  ScannedTokenLocation({this.end, this.start});
}

class ScannedTokenLocationPart {
  final int line, column;

  ScannedTokenLocationPart({this.line, this.column});
}

class ScannedTemplate {
  final String cooked, raw;

  ScannedTemplate({this.cooked, this.raw});
}

class Scanner {
  final List<String> curlyStack = [];
  int length, index, lineNumber, lineStart = 0;
  final ErrorHandler errorHandler;
  final String source;
  final bool trackComment;

  Scanner(this.source, this.errorHandler, {this.trackComment: false}) {
    length = source.length;
    lineNumber = (source.isNotEmpty) ? 1 : 0;
  }

  bool eof() => index >= length;

  void throwUnexpectedToken([String message]) {
    errorHandler.throwError(index, lineNumber, index - lineStart + 1,
        message ?? messages.UnexpectedTokenIllegal);
  }

  tolerateUnexpectedToken() {
    errorHandler.tolerateError(index, lineNumber, index - lineStart + 1,
        messages.UnexpectedTokenIllegal);
  }

  /// ECMA-262 11.4 Comments
  List<Comment> skipSingleLineComment(int offset) {
    final List<Comment> comments = [];
    int start;
    ScannedTokenLocation loc;

    if (trackComment) {
      start = index - offset;
      loc = new ScannedTokenLocation(
          start: new ScannedTokenLocationPart(
              line: lineNumber, column: index - lineStart - offset));
    }

    while (!eof()) {
      final ch = source.codeUnitAt(index);

      if (character.isLineTerminator(ch)) {
        if (trackComment) {
          loc.end = new ScannedTokenLocationPart(
              line: lineNumber, column: index - lineStart - 1);
          comments.add(new Comment(
              multiLine: false,
              slice: [start + offset, index - 1],
              range: [start, index - 1],
              loc: loc));
        }
      }
    }

    if (trackComment) {
      loc.end = new ScannedTokenLocationPart(
          line: lineNumber, column: index - lineStart);

      comments.add(new Comment(
          multiLine: false,
          slice: [start + offset, index],
          range: [start, index],
          loc: loc));
    }

    return comments;
  }

  List<Comment> skipMultiLineComment() {
    final List<Comment> comments = [];
    int start;
    ScannedTokenLocation loc;

    if (trackComment) {
      start = index - 2;
      loc = new ScannedTokenLocation(
          start: new ScannedTokenLocationPart(
              line: lineNumber, column: index - lineStart - 2));
    }

    while (!eof()) {
      final ch = source.codeUnitAt(index);
      if (character.isLineTerminator(ch)) {
        if (ch == 0x0D && source.codeUnitAt(index + 1) == 0x0A) index++;

        lineNumber++;
        index++;
        lineStart = index;
      } else if (ch == 0x2A) {
        // Block comment ends with '*/'.
        if (source.codeUnitAt(index + 1) == 0x2F) {
          index += 2;
          if (trackComment) {
            loc.end = new ScannedTokenLocationPart(
                line: lineNumber, column: index - lineStart);

            final Comment entry = new Comment(
                multiLine: true,
                slice: [start + 2, index - 2],
                range: [start, index],
                loc: loc);
            comments.add(entry);
          }
          return comments;
        }
        index++;
      } else {
        index++;
      }
    }

    // Ran off the end of the file - the whole thing is a comment
    if (trackComment) {
      loc.end = new ScannedTokenLocationPart(
          line: lineNumber, column: index - lineStart);

      final Comment entry = new Comment(
          multiLine: true,
          slice: [start + 2, index],
          range: [start, index],
          loc: loc);
      comments.add(entry);
    }

    tolerateUnexpectedToken();
    return comments;
  }

  List<Comment> scanComments() {
    final List<Comment> comments = [];
    bool start = index == 0;

    while (!eof()) {
      int ch = source.codeUnitAt(index);

      if (character.isWhitespace(ch))
        index++;
      else if (character.isLineTerminator(ch)) {
        index++;

        if (ch == 0x0D && source.codeUnitAt(index) == 0x0A) index++;
        lineNumber++;
        lineStart = index;
        start = true;
      } else if (ch == 0x2F) {
        // U+002F is '/
        ch = source.codeUnitAt(index + 1);

        if (ch == 0x2F) {
          index += 2;
          final comment = skipSingleLineComment(2);

          if (trackComment) comments.addAll(comment);

          start = true;
        } else if (ch == 0x2A) {
          // U+002A is '*'
          index += 2;
          final comment = skipMultiLineComment();

          if (trackComment) comments.addAll(comment);
        } else {
          break;
        }
      } else if (start && ch == 0x2D) {
        // U+002D is '-'
        // U+003E is '>'
        if (source.codeUnitAt(index + 1) == 0x2D &&
            source.codeUnitAt(index + 2) == 0x3E) {
          // '-->' is a single-line comment
          index += 3;
          final comment = skipSingleLineComment(3);

          if (trackComment) comments.addAll(comment);
        } else {
          break;
        }
      } else if (ch == 0x3C) {
        // U+003C is '<
        if (source.substring(index + 1, index + 4) == '!--') {
          index += 4; // `<!--`
          final comment = skipSingleLineComment(4);

          if (trackComment) comments.addAll(comment);
        } else {
          break;
        }
      }
    }

    return comments;
  }

  /// ECMA-262 11.6.2.2 Future Reserved Words
  bool isFutureReservedWord(String id) =>
      ['enum', 'export', 'import', 'super'].contains(id);

  bool isStrictModeReservedWord(String id) => [
        'implements',
        'interface',
        'package',
        'private',
        'protected',
        'public',
        'static',
        'yield',
        'let'
      ].contains(id);

  bool isRestrictedWord(String id) => ['eval', 'arguments'].contains(id);

  /// ECMA-262 11.6.2.1 Keywords
  bool isKeyword(String id) {
    switch (id.length) {
      case 2:
        return ['if', 'in', 'do'].contains(id);
      case 3:
        return ['var', 'for', 'new', 'try', 'let'].contains(id);
      case 4:
        return ['this', 'else', 'case', 'void', 'with', 'enum'].contains(id);
      case 5:
        return [
          'while',
          'break',
          'catch',
          'throw',
          'const',
          'yield',
          'class',
          'super'
        ].contains(id);
      case 6:
        return ['return', 'typeof', 'delete', 'switch', 'export', 'import']
            .contains(id);
      case 7:
        return ['default', 'finally', 'extends'].contains(id);
      case 8:
        return ['function', 'continue', 'debugger'].contains(id);
      case 10:
        return id == 'instanceof';
      default:
        return false;
    }
  }

  int codePointAt(int i) {
    int cp = source.codeUnitAt(i);

    if (cp >= 0xD800 && cp <= 0xDBFF) {
      int second = source.codeUnitAt(i + 1);
      if (second >= 0xDC00 && second <= 0xDFFF) {
        int first = cp;
        cp = (first - 0xD800) * 0x400 + second - 0xDC00 + 0x10000;
      }
    }

    return cp;
  }

  String scanHexEscape(String prefix) {
    final int len = prefix == 'u' ? 4 : 2;
    int code = 0;

    for (int i = 0; i < len; i++) {
      if (!eof() && character.isHexDigit(source.codeUnitAt(index))) {
        code = code * 16 + hexValue(source[index++]);
      } else {
        return '';
      }
    }

    return new String.fromCharCode(code);
  }

  String scanUnicodeCodePointEscape() {
    String ch = source[index];
    int code = 0;

    // At least, one hex digit is required.
    if (ch == '}') throwUnexpectedToken();

    while (!eof()) {
      ch = source[index++];

      if (!character.isHexDigit(ch.codeUnitAt(0))) break;

      code = code * 16 + hexValue(ch);
    }

    if (code > 0x10FFFF || ch != '}') throwUnexpectedToken();

    return character.fromCodePoint(code);
  }

  String getIdentifier() {
    final start = index++;

    while (!eof()) {
      final ch = source.codeUnitAt(index);

      if (ch == 0x5C) {
        // Blackslash (U+005C) marks Unicode escape sequence.
        index = start;
        return getComplexIdentifier();
      } else if (ch >= 0xD800 && ch < 0xDFFF) {
        // Need to handle surrogate pairs.
        index = start;
        return getComplexIdentifier();
      }

      if (character.isIdentifierPart(ch)) {
        index++;
      } else {
        break;
      }
    }

    return source.substring(start, index);
  }

  String getComplexIdentifier() {
    int cp = codePointAt(index);
    String id = character.fromCodePoint(cp);
    index += id.length;

    // '\u' (U+005C, U+0075) denotes an escaped character.
    String ch;

    if (cp == 0x5C) {
      if (source.codeUnitAt(index) != 0x75) {
        throwUnexpectedToken();
      }

      index++;
      if (source[index] == '{') {
        index++;
        ch = scanUnicodeCodePointEscape();
      } else {
        ch = scanHexEscape('u');
        cp = ch.codeUnitAt(0);

        if (ch.isEmpty || ch == '\\' || !character.isIdentifierStart(cp)) {
          throwUnexpectedToken();
        }
      }

      id = ch;
    }

    while (!eof()) {
      cp = codePointAt(index);

      if (!character.isIdentifierPart(cp)) break;

      ch = character.fromCodePoint(cp);
      id += ch;
      index += ch.length;

      // '\u' (U+005C, U+0075) denotes an escaped character.
      if (cp == 0x5C) {
        id = id.substring(0, id.length - 1);

        if (source.codeUnitAt(index) != 0x75) throwUnexpectedToken();

        index++;

        if (source[index] == '{') {
          index++;
          ch = scanUnicodeCodePointEscape();
        } else {
          ch = scanHexEscape('u');
          cp = ch.codeUnitAt(0);

          if (ch.isEmpty || ch == '\\' || !character.isIdentifierPart(cp))
            throwUnexpectedToken();
        }

        id += ch;
      }
    }

    return id;
  }

  ScannedToken octalToDecimal(String ch) {
    // \0 is not octal escape sequence
    bool octal = ch != '0';
    int code = octalValue(ch);

    if (!eof() && character.isOctalDigit(source.codeUnitAt(index))) {
      octal = true;
      code = code * 8 + octalValue(source[index++]);

      // 3 digits are only allowed when string starts
      // with 0, 1, 2, 3
      if ('0123'.indexOf(ch) >= 0 &&
          !eof() &&
          character.isOctalDigit(source.codeUnitAt(index))) {
        code = code * 8 + octalValue(source[index++]);
      }
    }

    return new ScannedToken(code: code, octal: octal);
  }

  /// ECMA-262 11.6 Names and Keywords
  ScannedToken scanIdentifier() {
    int type;
    final start = index;

    // Backslash (U+005C) starts an escaped character.
    final id = source.codeUnitAt(start) == 0x5C
        ? getComplexIdentifier()
        : getIdentifier();

    // There is no keyword or literal with only one character.
    // Thus, it must be an identifier.
    if (id.length == 1)
      type = token_type.Identifier;
    else if (isKeyword(id))
      type = token_type.Keyword;
    else if (id == 'null')
      type = token_type.NullLiteral;
    else if (['true', 'false'].contains(id))
      type = token_type.BooleanLiteral;
    else
      type = token_type.Identifier;

    return new ScannedToken(
        type: type,
        value: id,
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  /// ECMA-262 11.7 Punctuators
  ScannedToken scanPunctuator() {
    final ScannedToken token = new ScannedToken(
        type: token_type.Punctuator,
        value: '',
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: index,
        end: index);

    // Check for most common single-character punctuators.
    String str = source[index];

    switch (str) {
      case '(':
      case '{':
        if (str == '{') curlyStack.add('{');
        index++;
        break;

      case '.':
        index++;

        if (source[index] == '.' && source[index + 1] == '.') {
          // Spread operator: ...
          index += 2;
          str = '...';
        }

        break;

      case '}':
        index++;
        curlyStack.removeLast();
        break;
      case ')':
      case ';':
      case ',':
      case '[':
      case ':':
      case '?':
      case '~':
        index++;
        break;

      default:
        // 4-character punctuator.
        str = source.substring(index, index + 4);

        if (str == '>>>=')
          index += 4;
        else {
          // 3-character punctuators.
          str = str.substring(0, 3);

          if (str == '===' ||
              str == '!==' ||
              str == '>>>' ||
              str == '<<=' ||
              str == '>>=' ||
              str == '**=') {
            index += 3;
          } else {
            // 2-character punctuators.
            str = str.substring(0, 2);

            if (str == '&&' ||
                str == '||' ||
                str == '==' ||
                str == '!=' ||
                str == '+=' ||
                str == '-=' ||
                str == '*=' ||
                str == '/=' ||
                str == '++' ||
                str == '--' ||
                str == '<<' ||
                str == '>>' ||
                str == '&=' ||
                str == '|=' ||
                str == '^=' ||
                str == '%=' ||
                str == '<=' ||
                str == '>=' ||
                str == '=>' ||
                str == '**') {
              index += 2;
            } else {
              // 1-character punctuators.
              str = source[index];

              if ('<>=!+-*%&|^/'.indexOf(str) >= 0) index++;
            }
          }
        }
    }

    if (index == token.start) throwUnexpectedToken();

    token.end = index;
    token.value = str;
    return token;
  }

  /// ECMA-262 11.8.3 Numeric Literals
  ScannedToken scanHexLiteral(int start) {
    String number = '';

    while (!eof()) {
      if (!character.isHexDigit(source.codeUnitAt(index))) break;

      number += source[index++];
    }

    if (number.isEmpty) throwUnexpectedToken();

    if (character.isIdentifierStart(source.codeUnitAt(index)))
      throwUnexpectedToken();

    return new ScannedToken(
        type: token_type.NumericLiteral,
        value: int.parse('0x$number', radix: 16),
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  ScannedToken scanBinaryLiteral(int start) {
    String number = '', ch;

    while (!eof()) {
      ch = source[index];

      if (ch != '0' && ch != '1') break;
    }

    if (number.isEmpty) {
      // only 0b or 0B
      throwUnexpectedToken();
    }

    if (!eof()) {
      int ch = source.codeUnitAt(index);

      if (character.isIdentifierStart(ch) || character.isDecimalDigit(ch))
        throwUnexpectedToken();
    }

    return new ScannedToken(
        type: token_type.NumericLiteral,
        value: int.parse(number, radix: 2),
        lineNumber: lineNumber,
        start: start,
        end: index);
  }

  ScannedToken scanOctalLiteral(String prefix, int start) {
    String number = '';
    bool octal = false;

    if (character.isOctalDigit(prefix.codeUnitAt(0))) {
      octal = true;
      number = '0' + source[index++];
    } else {
      index++;
    }

    while (!eof()) {
      if (!character.isOctalDigit(source.codeUnitAt(index))) break;

      number += source[index++];
    }

    if (!octal && number.isEmpty) {
      // only 0o or 0O
      throwUnexpectedToken();
    }

    if (character.isIdentifierStart(source.codeUnitAt(index)) ||
        character.isDecimalDigit(source.codeUnitAt(index)))
      throwUnexpectedToken();

    return new ScannedToken(
        type: token_type.NumericLiteral,
        value: int.parse(number, radix: 8),
        octal: octal,
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  bool isImplicitOctalLiteral() {
    // Implicit octal, unless there is a non-octal digit.
    // (Annex B.1.1 on Numeric Literals)
    for (int i = index + 1; i < length; i++) {
      final ch = source[i];

      if (ch == '8' || ch == '9') {
        return false;
      }

      if (!character.isOctalDigit(ch.codeUnitAt(0))) {
        return true;
      }
    }

    return true;
  }

  ScannedToken scanNumericLiteral() {
    final start = index;
    String ch = source[start];
    assertCondition(character.isDecimalDigit(ch.codeUnitAt(0)) || (ch == '.'),
        'Numeric literal must start with a decimal digit or a decimal point');

    String number = '';

    if (ch != '.') {
      number = source[index++];
      ch = source[index];

      // Hex number starts with '0x'.
      // Octal number starts with '0'.
      // Octal number in ES6 starts with '0o'.
      // Binary number in ES6 starts with '0b'.
      if (number == '0') {
        if (ch == 'x' || ch == 'X') {
          index++;
          return scanHexLiteral(start);
        }

        if (ch == 'b' || ch == 'B') {
          index++;
          return scanBinaryLiteral(start);
        }

        if (ch == 'o' || ch == 'O') {
          return scanOctalLiteral(ch, start);
        }

        if (ch.isNotEmpty && character.isOctalDigit(ch.codeUnitAt(0))) {
          if (isImplicitOctalLiteral()) {
            return scanOctalLiteral(ch, start);
          }
        }
      }

      while (character.isDecimalDigit(source.codeUnitAt(index))) {
        number += source[index++];
      }

      ch = source[index];
    }

    if (ch == '.') {
      number += source[index++];

      while (character.isDecimalDigit(source.codeUnitAt(index))) {
        number += source[index];
      }

      ch = source[index];
    }

    if (ch == 'e' || ch == 'E') {
      number += source[index++];

      ch = source[index];

      if (ch == '+' || ch == '-') number += source[index];

      if (character.isDecimalDigit(source.codeUnitAt(index))) {
        while (character.isDecimalDigit(source.codeUnitAt(index))) {
          number += source[index++];
        }
      } else {
        throwUnexpectedToken();
      }
    }

    if (character.isIdentifierStart(source.codeUnitAt(index))) {
      throwUnexpectedToken();
    }

    return new ScannedToken(
        type: token_type.NumericLiteral,
        value: double.parse(number),
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  /// ECMA-262 11.8.4 String Literals
  ScannedToken scanStringLiteral() {
    final start = index;
    String quote = source[start];
    assertCondition((quote == '\'' || quote == '"'),
        'String literal must starts with a quote');

    index++;
    bool octal = false;
    String str = '';

    while (!eof()) {
      String ch = source[index++];

      if (ch == quote) {
        quote = '';
        break;
      } else if (ch == '\\') {
        ch == source[index++];

        if (ch.isEmpty || !character.isLineTerminator(ch.codeUnitAt(0))) {
          switch (ch) {
            case 'u':
            case 'x':
              if (source[index] == '{') {
                index++;
                str += scanUnicodeCodePointEscape();
              } else {
                final unescaped = scanHexEscape(ch);

                if (unescaped.isEmpty) throwUnexpectedToken();

                str += unescaped;
              }

              break;
            case 'n':
              str += '\n';
              break;
            case 'r':
              str += '\r';
              break;
            case 't':
              str += '\t';
              break;
            case 'b':
              str += '\b';
              break;
            case 'f':
              str += '\f';
              break;
            case 'v':
              str += '\x0B';
              break;
            case '8':
            case '9':
              str += ch;
              tolerateUnexpectedToken();
              break;

            default:
              if (ch.isNotEmpty && character.isOctalDigit(ch.codeUnitAt(0))) {
                final octToDec = octalToDecimal(ch);

                octal = octToDec.octal || octal;
                str += new String.fromCharCode(octToDec.code);
              } else {
                str += ch;
              }

              break;
          }
        } else {
          lineNumber++;

          if (ch == '\r' && source[index] == '\n') index++;

          lineStart = index;
        }
      } else if (character.isLineTerminator(ch.codeUnitAt(0))) {
        break;
      } else {
        str += ch;
      }
    }

    if (quote != '') {
      index = start;
      throwUnexpectedToken();
    }

    return new ScannedToken(
        type: token_type.StringLiteral,
        value: str,
        octal: octal,
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  /// ECMA-262 11.8.6 Template Literal Lexical Components
  ScannedToken scanTemplate() {
    String cooked = '';
    bool terminated = false;
    int start = index++, rawOffset = 2;
    bool head = source[start] == '`', tail = false;

    while (!eof()) {
      String ch = source[index++];

      if (ch == '`') {
        rawOffset = 1;
        tail = true;
        terminated = true;
        break;
      } else if (ch == r'$') {
        if (source[index] == '{') {
          curlyStack.add(r'${');
          index++;
          terminated = true;
          break;
        }

        cooked += ch;
      } else if (ch == '\\') {
        ch = source[index++];

        if (!character.isLineTerminator(ch.codeUnitAt(0))) {
          switch (ch) {
            case 'n':
              cooked += '\n';
              break;
            case 'r':
              cooked += '\r';
              break;
            case 't':
              cooked += '\t';
              break;
            case 'u':
            case 'x':
              if (source[index] == '{') {
                index++;
                cooked += this.scanUnicodeCodePointEscape();
              } else {
                final restore = index;
                final unescaped = scanHexEscape(ch);

                if (unescaped.isNotEmpty) {
                  cooked += unescaped;
                } else {
                  index = restore;
                  cooked += ch;
                }
              }

              break;
            case 'b':
              cooked += '\b';
              break;
            case 'f':
              cooked += '\f';
              break;
            case 'v':
              cooked += '\v';
              break;

            default:
              if (ch == '0') {
                if (character.isDecimalDigit(source.codeUnitAt(index))) {
                  // Illegal: \01 \02 and so on
                  throwUnexpectedToken(messages.TemplateOctalLiteral);
                }
                cooked += '\0';
              } else if (character.isOctalDigit(ch.codeUnitAt(0))) {
                // Illegal: \1 \2
                throwUnexpectedToken(messages.TemplateOctalLiteral);
              } else {
                cooked += ch;
              }

              break;
          }
        } else {
          lineNumber++;

          if (ch == '\r' && source[index] == '\n') {
            index++;
          }

          lineStart = index;
        }
      } else if (character.isLineTerminator(ch.codeUnitAt(0))) {
        lineNumber++;

        if (ch == '\r' && source[index] == '\n') index++;

        lineStart = index;
        cooked += '\n';
      } else {
        cooked += ch;
      }
    }

    if (!terminated) throwUnexpectedToken();

    if (!head) curlyStack.removeLast();

    return new ScannedToken(
        type: token_type.Template,
        value: new ScannedTemplate(
            cooked: cooked,
            raw: source.substring(start + 1, index - rawOffset)),
        head: head,
        tail: tail,
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  /// ECMA-262 11.8.5 Regular Expression Literals
  RegExp testRegExp(String pattern, String flags) {
    // The BMP character to use as a replacement for astral symbols when
    // translating an ES6 "u"-flagged pattern to an ES5-compatible
    // approximation.
    // Note: replacing with '\uFFFF' enables false positives in unlikely
    // scenarios. For example, `[\u{1044f}-\u{10440}]` is an invalid
    // pattern that would not be detected by this substitution.
    const astralSubstitute = '\uFFFF';
    var tmp = pattern;

    if (flags.indexOf('u') >= 0) {
      tmp = tmp.replaceAllMapped(_rgxEscape1, (match) {
        // Replace every Unicode escape sequence with the equivalent
        // BMP character or a constant ASCII code point in the case of
        // astral symbols. (See the above note on `astralSubstitute`
        // for more information.
        final codePoint = int.parse(
            (match[1] != null && match[1].isNotEmpty) ? match[1] : match[2],
            radix: 16);

        if (codePoint > 0x10FFFF) throwUnexpectedToken(messages.InvalidRegExp);

        if (codePoint <= 0xFFFF) return new String.fromCharCode(codePoint);

        return astralSubstitute;
      }).replaceAllMapped(_rgxEscape2, (match) {
        // Replace each paired surrogate with a single ASCII symbol to
        // avoid throwing on regular expressions that are only valid in
        // combination with the "u" flag.
        return astralSubstitute;
      });
    }

    // First, detect invalid regular expressions.
    try {
      new RegExp(tmp);
    } catch (e) {
      throwUnexpectedToken(messages.InvalidRegExp);
    }

    // Return a regular expression object for this pattern-flag pair, or
    // `null` in case the current environment doesn't support the flags it
    // uses.
    try {
      return new RegExp(pattern,
          caseSensitive: !flags.contains('i'), multiLine: flags.contains('m'));
    } catch (exception) {
      /* istanbul ignore next */
      return null;
    }
  }

  ScannedToken scanRegExpBody() {
    String ch = source[index];
    assertCondition(
        ch == '/', 'Regular expression literal must start with a slash');

    String str = source[index++];
    bool classMarker = false, terminated = false;

    while (!eof()) {
      ch = source[index++];
      str += ch;

      if (ch == '\\') {
        ch = source[index++];

        // ECMA-262 7.8.5
        if (character.isLineTerminator(ch.codeUnitAt(0)))
          throwUnexpectedToken(messages.UnterminatedRegExp);

        str += ch;
      } else if (character.isLineTerminator(ch.codeUnitAt(0))) {
        throwUnexpectedToken(messages.UnterminatedRegExp);
      } else if (classMarker) {
        if (ch == ']') classMarker = false;
      } else {
        if (ch == '/') {
          terminated = true;
          break;
        } else if (ch == '[') {
          classMarker = true;
        }
      }
    }

    if (!terminated) throwUnexpectedToken(messages.UnterminatedRegExp);

    // Exclude leading and trailing slash.
    final body = str.substring(1, str.length - 2);

    return new ScannedToken(value: body, literal: str);
  }

  ScannedToken scanRegExpFlags() {
    String str = '', flags = '';

    while (!eof()) {
      String ch = source[index];

      if (!character.isIdentifierPart(ch.codeUnitAt(0))) break;

      index++;

      if (ch == '\\' && !eof()) {
        ch = source[index];

        if (ch == 'u') {
          index++;
          int restore = index;
          ch = scanHexEscape('u');

          if (ch.isNotEmpty) {
            flags += ch;

            for (str += '\\u'; restore < index; restore++) {
              str += source[restore];
            }
          } else {
            index = restore;
            flags += 'u';
            str += '\\u';
          }

          tolerateUnexpectedToken();
        } else {
          str += '\\';
          tolerateUnexpectedToken();
        }
      } else {
        flags += ch;
        str += ch;
      }
    }

    return new ScannedToken(value: flags, literal: str);
  }

  ScannedToken scanRegExp() {
    final start = index;
    final body = scanRegExpBody();
    final flags = scanRegExpFlags();
    final value = testRegExp(body.value, flags.value);

    return new ScannedToken(
        type: token_type.RegularExpression,
        value: value,
        literal: body.literal + flags.literal,
        regExp: new RegExp(body.value,
            caseSensitive: !flags.value.contains('i'),
            multiLine: flags.value.contains('m')),
        lineNumber: lineNumber,
        lineStart: lineStart,
        start: start,
        end: index);
  }

  ScannedToken lex() {
    if (eof()) {
      return new ScannedToken(
          type: token_type.EOF,
          lineNumber: lineNumber,
          lineStart: lineStart,
          start: index,
          end: index);
    }

    final cp = source.codeUnitAt(index);

    if (character.isIdentifierPart(cp)) {
      return scanIdentifier();
    }

    // Very common: ( and ) and ;
    if (cp == 0x28 || cp == 0x29 || cp == 0x3B) {
      return scanPunctuator();
    }

    // String literal starts with single quote (U+0027) or double quote (U+0022).
    if (cp == 0x27 || cp == 0x22) {
      return scanStringLiteral();
    }

    // Dot (.) U+002E can also start a floating-point number, hence the need
    // to check the next character.
    if (cp == 0x2E) {
      if (character.isDecimalDigit(source.codeUnitAt(this.index + 1))) {
        return scanNumericLiteral();
      }

      return scanPunctuator();
    }

    if (character.isDecimalDigit(cp)) return scanNumericLiteral();

    // Template literals start with ` (U+0060) for template head
    // or } (U+007D) for template middle or template tail.
    if (cp == 0x60 ||
        (cp == 0x7D && curlyStack[curlyStack.length - 1] == r'${'))
      return scanTemplate();

    // Possible identifier start in a surrogate pair.
    if (cp >= 0xD800 && cp < 0xDFFF) {
      if (character.isIdentifierStart(codePointAt(index)))
        return scanIdentifier();
    }

    return scanPunctuator();
  }
}
