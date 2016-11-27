// Error messages should be identical to V8.
library esprima.messages;

const String UnexpectedToken = 'Unexpected token %0';
const String UnexpectedTokenIllegal = 'Unexpected token ILLEGAL';
const String UnexpectedNumber = 'Unexpected number';
const String UnexpectedString = 'Unexpected string';
const String UnexpectedIdentifier = 'Unexpected identifier';
const String UnexpectedReserved = 'Unexpected reserved word';
const String UnexpectedTemplate = 'Unexpected quasi %0';
const String UnexpectedEOS = 'Unexpected end of input';
const String NewlineAfterThrow = 'Illegal newline after throw';
const String InvalidRegExp = 'Invalid regular expression';
const String UnterminatedRegExp = 'Invalid regular expression: missing /';
const String InvalidLHSInAssignment = 'Invalid left-hand side in assignment';
const String InvalidLHSInForIn = 'Invalid left-hand side in for-in';
const String InvalidLHSInForLoop = 'Invalid left-hand side in for-loop';
const String MultipleDefaultsInSwitch =
    'More than one default clause in switch statement';
const String NoCatchOrFinally = 'Missing catch or finally after try';
const String UnknownLabel = 'Undefined label \'%0\'';
const String Redeclaration = '%0 \'%1\' has already been declared';
const String IllegalContinue = 'Illegal continue statement';
const String IllegalBreak = 'Illegal break statement';
const String IllegalReturn = 'Illegal return statement';
const String StrictModeWith =
    'Strict mode code may not include a with statement';
const String StrictCatchVariable =
    'Catch variable may not be eval or arguments in strict mode';
const String StrictVarName =
    'Variable name may not be eval or arguments in strict mode';
const String StrictParamName =
    'Parameter name eval or arguments is not allowed in strict mode';
const String StrictParamDupe =
    'Strict mode function may not have duplicate parameter names';
const String StrictFunctionName =
    'Function name may not be eval or arguments in strict mode';
const String StrictOctalLiteral =
    'Octal literals are not allowed in strict mode.';
const String StrictDelete =
    'Delete of an unqualified identifier in strict mode.';
const String StrictLHSAssignment =
    'Assignment to eval or arguments is not allowed in strict mode';
const String StrictLHSPostfix =
    'Postfix increment/decrement may not have eval or arguments operand in strict mode';
const String StrictLHSPrefix =
    'Prefix increment/decrement may not have eval or arguments operand in strict mode';
const String StrictReservedWord = 'Use of future reserved word in strict mode';
const String TemplateOctalLiteral =
    'Octal literals are not allowed in template strings.';
const String ParameterAfterRestParameter =
    'Rest parameter must be last formal parameter';
const String DefaultRestParameter = 'Unexpected token =';
const String ObjectPatternAsRestParameter = 'Unexpected token {';
const String DuplicateProtoProperty =
    'Duplicate __proto__ fields are not allowed in object literals';
const String ConstructorSpecialMethod =
    'Class constructor may not be an accessor';
const String DuplicateConstructor = 'A class may only have one constructor';
const String Prototype = 'Classes may not have  property named prototype';
const String MissingFromClause = 'Unexpected token';
const String NoAsAfterImportNamespace = 'Unexpected token';
const String InvalidModuleSpecifier = 'Unexpected token';
const String IllegalImportDeclaration = 'Unexpected token';
const String IllegalExportDeclaration = 'Unexpected token';
const String DuplicateBinding = 'Duplicate binding %0';
const String ForInOfLoopInitializer =
    '%0 loop variable declaration may not have an initializer';
