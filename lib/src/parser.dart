import 'assert.dart';
import 'error_handler.dart' show ErrorHandler;
import 'messages.dart' as messages;
import 'nodes.dart' as nodes;
import 'options.dart';
import 'scanner.dart'
    show
        Comment,
        Scanner,
        ScannedToken,
        ScannedTokenLocation,
        ScannedTokenLocationPart;
import 'source_type.dart' as source_type;
import 'syntax.dart' as syntax;
import 'token.dart' show TokenName;
import 'token.dart' as Token;

final String ARROW_PARAMETER_PLACEHOLDER = 'ArrowParameterPlaceHolder';
final Map<String, int> OPERATOR_PRECEDENCE = const {
  ')': 0,
  ';': 0,
  ',': 0,
  '=': 0,
  ']': 0,
  '||': 1,
  '&&': 2,
  '|': 3,
  '^': 4,
  '&': 5,
  '==': 6,
  '!=': 6,
  '==': 6,
  '!==': 6,
  '<': 7,
  '>': 7,
  '<=': 7,
  '>=': 7,
  '<<': 8,
  '>>': 8,
  '>>>': 8,
  '+': 9,
  '-': 9,
  '*': 11,
  '/': 11,
  '%': 11
};

final RegExp _fmt = new RegExp(r'%(\d)');

typedef Comment ParseFunction();
typedef ParserDelegate(Comment node, ScannedTokenLocation metadata);

class Config {
  bool range, loc, tokens, comment, tolerant;
  String source;

  Config(
      {this.range: false,
      this.loc: false,
      this.source,
      this.tokens: false,
      this.comment: false,
      this.tolerant: false});
}

class Context {
  bool allowIn,
      allowYield,
      isAssignmentTarget,
      isBindingElement,
      inFunctionBody,
      inIteration,
      inSwitch,
      strict;

  // Todo: Type for this
  var firstCoverInitializedNameError = null;

  // Todo: And this ;)
  var labelSet = {};

  Context(
      {this.allowIn: false,
      this.allowYield: false,
      this.firstCoverInitializedNameError,
      this.isAssignmentTarget: false,
      this.isBindingElement: false,
      this.inFunctionBody: false,
      this.inIteration: false,
      this.inSwitch: false,
      this.labelSet,
      this.strict: false});
}

class Marker {
  int index, lineNumber, lineStart;

  Marker({this.index, this.lineNumber, this.lineStart});
}

class MetaNode {
  int index, line, column;

  MetaNode({this.column, this.index, this.line});
}

class ArrowParameterPlaceHolderNode {
  String type;
  final List<nodes.Expression> params = [];

  ArrowParameterPlaceHolderNode(
      {this.type, List<nodes.Expression> params: const []}) {
    if (params != null) this.params.addAll(params);
  }
}

class DeclarationOptions {
  bool inFor;

  DeclarationOptions({this.inFor: false});
}

class Parser {
  Config _config;
  ErrorHandler _errorHandler;
  Scanner _scanner;
  Context context = new Context();
  ParserDelegate delegate;
  bool hasLineTerminator = false;
  Marker lastMarker;
  ScannedToken lookahead = null;
  Marker startMarker;
  String sourceType;
  final List tokens = [];

  Config get config => _config;
  ErrorHandler get errorHandler => _errorHandler;
  Scanner get scanner => _scanner;

  // Todo: Typedef for delegate
  Parser(String code, {EsprimaOptions options, this.delegate}) {
    _config = new Config(
        range: options.range,
        loc: options.loc,
        source: null,
        tokens: options.tokens,
        comment: options.comment,
        tolerant: options.tolerant);

    if (_config.loc && options.source != null)
      _config.source = options.source.toString();

    _errorHandler = new ErrorHandler(tolerant: _config.tolerant);
    _scanner = new Scanner(code, _errorHandler, trackComment: _config.comment);

    sourceType = options.sourceType == source_type.MODULE
        ? source_type.MODULE
        : source_type.SCRIPT;
    context.strict = sourceType == source_type.MODULE;

    startMarker =
        new Marker(index: 0, lineNumber: scanner.lineNumber, lineStart: 0);
    lastMarker =
        new Marker(index: 0, lineNumber: scanner.lineNumber, lineStart: 0);
    nextToken();

    lastMarker = new Marker(
        index: scanner.index,
        lineNumber: scanner.lineNumber,
        lineStart: scanner.lineStart);
  }

  void throwError(String messageFormat, List values) {
    final msg = messageFormat.replaceAllMapped(_fmt, (match) {
      final idx = int.parse(match[1]);
      assertCondition(
          idx < values.length, 'Message reference must be in range');
      return values[idx].toString();
    });

    final index = lastMarker.index, line = lastMarker.lineNumber;
    final column = lastMarker.index - lastMarker.lineStart + 1;
    throw errorHandler.createError(index, line, column, msg);
  }

  void tolerateError(String messageFormat, List values) {
    final msg = messageFormat.replaceAllMapped(_fmt, (match) {
      final idx = int.parse(match[1]);
      assertCondition(
          idx < values.length, 'Message reference must be in range');
      return values[idx].toString();
    });

    final index = lastMarker.index, line = lastMarker.lineNumber;
    final column = lastMarker.index - lastMarker.lineStart + 1;
    errorHandler.tolerateError(index, line, column, msg);
  }

  /// Throw an exception because of the token.
  Exception unexpectedTokenError([token, String message]) {
    String msg = message ?? messages.UnexpectedToken;
    var value;

    if (token == null) {
      value = 'ILLEGAL';
    } else {
      if (message == null) {
        msg = (token.type == Token.EOF)
            ? messages.UnexpectedEOS
            : (token.type == Token.Identifier)
                ? messages.UnexpectedIdentifier
                : (token.type == Token.NumericLiteral)
                    ? messages.UnexpectedNumber
                    : (token.type == Token.StringLiteral)
                        ? messages.UnexpectedString
                        : (token.type == Token.Template)
                            ? messages.UnexpectedTemplate
                            : messages.UnexpectedToken;

        if (token.type == token.Keyword) {
          if (scanner.isFutureReservedWord(token.value)) {
            msg = messages.UnexpectedReserved;
          } else if (context.strict &&
              scanner.isStrictModeReservedWord(token.value)) {
            msg = messages.StrictReservedWord;
          }
        }
      }

      value = (token.type == token.Template) ? token.value.raw : token.value;
    }

    msg = msg.replaceAll('%0', value);

    if (token != null && token.lineNumber is num) {
      final index = token.start;
      final line = token.lineNumber;
      final column = token.start - lastMarker.lineStart + 1;
      return errorHandler.createError(index, line, column, msg);
    } else {
      final index = lastMarker.index;
      final line = lastMarker.lineNumber;
      final column = index - lastMarker.lineStart + 1;
      return errorHandler.createError(index, line, column, msg);
    }
  }

  void throwUnexpectedToken([token, message]) {
    throw unexpectedTokenError(token, message);
  }

  void tolerateUnexpectedToken([token, message]) {
    errorHandler.tolerate(unexpectedTokenError(token, message));
  }

  void collectComments() {
    if (!config.comment) {
      scanner.scanComments();
    } else {
      final List<Comment> comments = scanner.scanComments();

      if (comments.isNotEmpty && delegate != null) {
        for (Comment e in comments) {
          Comment node =
              new Comment(type: e.multiLine ? Comment.BLOCK : Comment.LINE);

          if (config.range) nodes.range = e.range;

          if (config.loc) nodes.loc = e.loc;

          final location = new ScannedTokenLocation(
              start: new ScannedTokenLocationPart(
                  line: e.loc.start.line,
                  column: e.loc.start.column,
                  offset: e.range[0]),
              end: new ScannedTokenLocationPart(
                  line: e.loc.end.line,
                  column: e.loc.end.column,
                  offset: e.range[1]));
          delegate(node, location);
        }
      }
    }
  }

  /// From internal representation to an external structure
  String getTokenRaw(ScannedToken token) =>
      scanner.source.substring(token.start, token.end);

  ScannedToken convertToken(ScannedToken token) {
    ScannedToken t = new ScannedToken(
        type: TokenName[token.type], value: getTokenRaw(token));

    if (config.range) {
      t.range = [token.start, token.end];
    }
    if (config.loc) {
      t.loc = {
        start: {
          line: startMarker.lineNumber,
          column: startMarker.index - startMarker.lineStart
        },
        end: {
          line: scanner.lineNumber,
          column: scanner.index - scanner.lineStart
        }
      };
    }

    if (token.regex) {
      t.regex = token.regex;
    }

    return t;
  }

  ScannedToken nextToken() {
    final token = lookahead;

    lastMarker.index = scanner.index;
    lastMarker.lineNumber = scanner.lineNumber;
    lastMarker.lineStart = scanner.lineStart;

    collectComments();

    startMarker.index = scanner.index;
    startMarker.lineNumber = scanner.lineNumber;
    startMarker.lineStart = scanner.lineStart;

    ScannedToken next = scanner.lex();

    hasLineTerminator =
        (token && next) ? (token.lineNumber != next.lineNumber) : false;

    if (next && context.strict && next.type == Token.Identifier) {
      if (scanner.isStrictModeReservedWord(next.value)) {
        next.type = Token.Keyword;
      }
    }

    lookahead = next;

    if (config.tokens && next.type != Token.EOF) {
      tokens.add(convertToken(next));
    }

    return token;
  }

  ScannedToken nextRegexToken() {
    collectComments();

    final token = scanner.scanRegExp();

    if (config.tokens) {
      // Pop the previous token, '/' or '/='
      // This is added from the lookahead token.
      tokens.removeLast();

      tokens.add(convertToken(token));
    }

    // Prime the next lookahead.
    lookahead = token;
    nextToken();

    return token;
  }

  MetaNode createNode() {
    return new MetaNode(
        index: startMarker.index,
        line: startMarker.lineNumber,
        column: startMarker.index - startMarker.lineStart);
  }

  MetaNode startNode(ScannedToken token) {
    return new MetaNode(
        index: token.start,
        line: token.lineNumber,
        column: token.start - token.lineStart);
  }

  Comment finalize(MetaNode meta, Comment node) {
    if (config.range) {
      nodes.range = [meta.index, lastMarker.index];
    }

    if (config.loc) {
      nodes.loc = new ScannedTokenLocation(
          start: new ScannedTokenLocationPart(
              line: meta.line, column: meta.column),
          end: new ScannedTokenLocationPart(
              line: lastMarker.lineNumber,
              column: lastMarker.index - lastMarker.lineStart));

      if (config.source) {
        nodes.loc.source = config.source;
      }
    }

    if (delegate != null) {
      final ScannedTokenLocation metadata = new ScannedTokenLocation(
          start: new ScannedTokenLocationPart(
              line: meta.line, column: meta.column, offset: meta.index),
          end: new ScannedTokenLocationPart(
              line: lastMarker.lineNumber,
              column: lastMarker.index - lastMarker.lineStart,
              offset: lastMarker.index));

      delegate(node, metadata);
    }

    return node;
  }

  /// Expect the next token to match the specified punctuator.
  /// If not, an exception will be thrown.
  void expect(value) {
    final token = nextToken();

    if (token.type != Token.Punctuator || token.value != value) {
      throwUnexpectedToken(token);
    }
  }

  /// Quietly expect a comma when in tolerant mode, otherwise delegates to expect().
  void expectCommaSeparator() {
    if (config.tolerant) {
      ScannedToken token = lookahead;
      if (token.type == Token.Punctuator && token.value == ',') {
        nextToken();
      } else if (token.type == Token.Punctuator && token.value == ';') {
        nextToken();
        tolerateUnexpectedToken(token);
      } else {
        tolerateUnexpectedToken(token, messages.UnexpectedToken);
      }
    } else {
      expect(',');
    }
  }

  /// Expect the next token to match the specified keyword.
  /// If not, an exception will be thrown.
  void expectKeyword(keyword) {
    const token = nextToken();
    if (token.type != Token.Keyword || token.value != keyword) {
      throwUnexpectedToken(token);
    }
  }

  /// Return true if the next token matches the specified punctuator.
  bool match(value) =>
      lookahead.type == Token.Punctuator && lookahead.value == value;

  /// Return true if the next token matches the specified keyword
  bool matchKeyword(keyword) =>
      lookahead.type == Token.Keyword && lookahead.value == keyword;

  /// Return true if the next token matches the specified contextual keyword
  /// (where an identifier is sometimes a keyword depending on the context)
  bool matchContextualKeyword(keyword) =>
      lookahead.type == Token.Identifier && lookahead.value == keyword;

  /// Return true if the next token is an assignment operator
  bool matchAssign() {
    if (this.lookahead.type != Token.Punctuator) {
      return false;
    }

    final op = this.lookahead.value;
    return op == '=' ||
        op == '*=' ||
        op == '**=' ||
        op == '/=' ||
        op == '%=' ||
        op == '+=' ||
        op == '-=' ||
        op == '<<=' ||
        op == '>>=' ||
        op == '>>>=' ||
        op == '&=' ||
        op == '^=' ||
        op == '|=';
  }

  /// Cover grammar support.
  ///
  /// When an assignment expression position starts with an left parenthesis, the determination of the type
  /// of the syntax is to be deferred arbitrarily long until the end of the parentheses pair (plus a lookahead)
  /// or the first comma. This situation also defers the determination of all the expressions nested in the pair.
  ///
  /// There are three productions that can be parsed in a parentheses pair that needs to be determined
  /// after the outermost pair is closed. They are:
  ///
  ///   1. AssignmentExpression
  ///   2. BindingElements
  ///   3. AssignmentTargets
  ///
  /// In order to avoid exponential backtracking, we use two flags to denote if the production can be
  /// binding element or assignment target.
  ///
  /// The three productions have the relationship:
  ///
  ///   BindingElements ⊆ AssignmentTargets ⊆ AssignmentExpression
  ///
  /// with a single exception that CoverInitializedName when used directly in an Expression, generates
  /// an early error. Therefore, we need the third state, firstCoverInitializedNameError, to track the
  /// first usage of CoverInitializedName and report it when we reached the end of the parentheses pair.
  ///
  /// isolateCoverGrammar function runs the given parser function with a new cover grammar context, and it does not
  /// effect the current flags. This means the production the parser parses is only used as an expression. Therefore
  /// the CoverInitializedName check is conducted.
  ///
  /// inheritCoverGrammar function runs the given parse function with a new cover grammar context, and it propagates
  /// the flags outside of the parser. This means the production the parser parses is used as a part of a potential
  /// pattern. The CoverInitializedName check is deferred.

  Comment isolateCoverGrammar(ParseFunction parseFunction) {
    final previousIsBindingElement = context.isBindingElement;
    final previousIsAssignmentTarget = context.isAssignmentTarget;
    final previousFirstCoverInitializedNameError =
        context.firstCoverInitializedNameError;

    context.isBindingElement = true;
    context.isAssignmentTarget = true;
    context.firstCoverInitializedNameError = null;

    final result = parseFunction();
    if (context.firstCoverInitializedNameError != null) {
      throwUnexpectedToken(context.firstCoverInitializedNameError);
    }

    context.isBindingElement = previousIsBindingElement;
    context.isAssignmentTarget = previousIsAssignmentTarget;
    context.firstCoverInitializedNameError =
        previousFirstCoverInitializedNameError;

    return result;
  }

  Comment inheritCoverGrammar(ParseFunction parseFunction) {
    final previousIsBindingElement = context.isBindingElement;
    final previousIsAssignmentTarget = context.isAssignmentTarget;
    final previousFirstCoverInitializedNameError =
        context.firstCoverInitializedNameError;

    context.isBindingElement = true;
    context.isAssignmentTarget = true;
    context.firstCoverInitializedNameError = null;

    final result = parseFunction();

    context.isBindingElement =
        context.isBindingElement && previousIsBindingElement;
    context.isAssignmentTarget =
        context.isAssignmentTarget && previousIsAssignmentTarget;
    context.firstCoverInitializedNameError =
        previousFirstCoverInitializedNameError ||
            context.firstCoverInitializedNameError;

    return result;
  }

  void consumeSemicolon() {
    if (match(';')) {
      nextToken();
    } else if (!hasLineTerminator) {
      if (lookahead.type != Token.EOF && !match('}')) {
        throwUnexpectedToken(lookahead);
      }
      lastMarker.index = startMarker.index;
      lastMarker.lineNumber = startMarker.lineNumber;
      lastMarker.lineStart = startMarker.lineStart;
    }
  }

  /// ECMA-262 12.2 Primary Expressions
  nodes.Expression parsePrimaryExpression() {
    final node = createNode();

    nodes.Expression expr;
    var value, token, raw;

    switch (lookahead.type) {
      case Token.Identifier:
        if (sourceType == 'module' && lookahead.value == 'await') {
          tolerateUnexpectedToken(lookahead);
        }
        expr = finalize(node, new nodes.Identifier(nextToken().value));
        break;

      case Token.NumericLiteral:
      case Token.StringLiteral:
        if (context.strict && lookahead.octal) {
          tolerateUnexpectedToken(lookahead, Messages.StrictOctalLiteral);
        }
        context.isAssignmentTarget = false;
        context.isBindingElement = false;
        token = nextToken();
        raw = getTokenRaw(token);
        expr = finalize(node, new nodes.Literal(token.value, raw));
        break;

      case Token.BooleanLiteral:
        context.isAssignmentTarget = false;
        context.isBindingElement = false;
        token = nextToken();
        token.value = (token.value == 'true');
        raw = getTokenRaw(token);
        expr = finalize(node, new nodes.Literal(token.value, raw));
        break;

      case Token.NullLiteral:
        context.isAssignmentTarget = false;
        context.isBindingElement = false;
        token = nextToken();
        token.value = null;
        raw = getTokenRaw(token);
        expr = finalize(node, new nodes.Literal(token.value, raw));
        break;

      case Token.Template:
        expr = parseTemplateLiteral();
        break;

      case Token.Punctuator:
        value = lookahead.value;
        switch (value) {
          case '(':
            context.isBindingElement = false;
            expr = inheritCoverGrammar(parseGroupExpression);
            break;
          case '[':
            expr = inheritCoverGrammar(parseArrayInitializer);
            break;
          case '{':
            expr = inheritCoverGrammar(parseObjectInitializer);
            break;
          case '/':
          case '/=':
            context.isAssignmentTarget = false;
            context.isBindingElement = false;
            scanner.index = startMarker.index;
            token = nextRegexToken();
            raw = getTokenRaw(token);
            expr = finalize(
                node, new nodes.RegexLiteral(token.value, raw, token.regex));
            break;
          default:
            throwUnexpectedToken(nextToken());
        }
        break;

      case Token.Keyword:
        if (!context.strict && context.allowYield && matchKeyword('yield')) {
          expr = parseIdentifierName();
        } else if (!context.strict && matchKeyword('let')) {
          expr = finalize(node, new nodes.Identifier(nextToken().value));
        } else {
          context.isAssignmentTarget = false;
          context.isBindingElement = false;
          if (matchKeyword('function')) {
            expr = parseFunctionExpression();
          } else if (matchKeyword('this')) {
            nextToken();
            expr = finalize(node, new nodes.ThisExpression());
          } else if (matchKeyword('class')) {
            expr = parseClassExpression();
          } else {
            throwUnexpectedToken(nextToken());
          }
        }
        break;

      default:
        throwUnexpectedToken(nextToken());
    }

    return expr;
  }

  /// ECMA-262 12.2.5 Array Initializer
  nodes.SpreadElement parseSpreadElement() {
    final node = createNode();
    expect('...');
    final arg = inheritCoverGrammar(parseAssignmentExpression);
    return finalize(node, new nodes.SpreadElement(argument: arg));
  }

  nodes.ArrayExpression parseArrayInitializer() {
    final node = createNode();
    final List<nodes.ArrayExpressionElement> elements = [];

    expect('[');
    while (!match(']')) {
      if (match(',')) {
        nextToken();
        elements.add(null);
      } else if (match('...')) {
        final element = parseSpreadElement();
        if (!match(']')) {
          context.isAssignmentTarget = false;
          context.isBindingElement = false;
          expect(',');
        }
        elements.add(element);
      } else {
        elements.add(inheritCoverGrammar(parseAssignmentExpression));
        if (!match(']')) {
          expect(',');
        }
      }
    }
    expect(']');

    return finalize(node, new nodes.ArrayExpression(elements));
  }

  // Just using a Map because I'm lazy
  nodes.BlockStatement parsePropertyMethod(Map params) {
    context.isAssignmentTarget = false;
    context.isBindingElement = false;

    const previousStrict = context.strict;
    const body = isolateCoverGrammar(parseFunctionSourceElements);

    if (context.strict && params['firstRestricted']) {
      tolerateUnexpectedToken(params['firstRestricted'], params['message']);
    }

    if (context.strict && params['stricted']) {
      tolerateUnexpectedToken(params['stricted'], params['message']);
    }
    context.strict = previousStrict;

    return body;
  }
}
