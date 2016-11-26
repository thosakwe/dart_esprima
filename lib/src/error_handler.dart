abstract class EsprimaError implements Exception {
  String get description;
  String get message;
  String get name;
  int get column;
  int get index;
  int get lineNumber;

  factory EsprimaError(String message) => new _EsprimaErrorImpl(message);
}

class _EsprimaErrorImpl implements EsprimaError {
  @override
  String description, message, name;

  @override
  int column, index, lineNumber;

  _EsprimaErrorImpl(this.message);
}

class ErrorHandler {
  final List<EsprimaError> _errors = [];
  List<EsprimaError> get errors => new List<EsprimaError>.unmodifiable(_errors);
  final bool tolerant;

  ErrorHandler({this.tolerant: false});

  void recordError(EsprimaError error) => _errors.add(error);

  void tolerate(EsprimaError error) {
    if (tolerant)
      recordError(error);
    else
      throw error;
  }

  EsprimaError constructError(String msg, int column) {
    _EsprimaErrorImpl error = new _EsprimaErrorImpl(msg);

    try {
      throw error;
    } catch (base) {
      error.column = column;
    } finally {
      return error;
    }
  }

  EsprimaError createError(int index, int line, int col, String description) {
    final msg = 'Line $line: $description';
    final _EsprimaErrorImpl error = constructError(msg, col);
    error.index = index;
    error.lineNumber = line;
    error.description = description;
    return error;
  }

  void throwError(int index, int line, int col, String description) {
    throw createError(index, line, col, description);
  }

  void tolerateError(int index, int line, int col, String description) {
    final error = createError(index, line, col, description);

    if (tolerant)
      recordError(error);
    else
      throw error;
  }
}
