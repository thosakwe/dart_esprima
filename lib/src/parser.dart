import 'assert.dart';
import 'error_handler.dart' show ErrorHandler;
import 'messages.dart' as messages;
import 'nodes.dart' as nodes;
import 'options.dart';
import 'scanner.dart' show Comment, Scanner;
import 'source_type.dart' as source_type;
import 'syntax.dart' as syntax;
import 'token.dart' show TokenName;
import 'token.dart' as token;

const String ARROW_PARAMETER_PLACEHOLDER = 'ArrowParameterPlaceHolder';
const Map<String, int> OPERATOR_PRECEDENCE = const {
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
  '===': 6,
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
  Function delegate;
  bool hasLineTerminator = false;
  Marker lastMarker;
  var lookahead = null;
  Marker startMarker;
  String sourceType;
  final List tokens = [];

  Config get config => _config;
  ErrorHandler get errorHandler => _errorHandler;
  Scanner get scanner => _scanner;

  // Todo: Typedef for delegate
  Parser(String code, {EsprimaOptions options, Function delegate}) {
    _config = new Config(
        range: options.range,
        loc: options.loc,
        source: null,
        tokens: options.tokens,
        comment: options.comment,
        tolerant: options.tolerant);

    if (_config.loc && options.source != null)
      _config.source = options.source.toString();

    this.delegate = delegate;

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
}
