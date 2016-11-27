import 'comment_handler.dart' show Comment;
import 'scanner.dart' show ScannedTemplate;
import 'syntax.dart' as syntax;

// Todo: Look through interfaces for shared fields ;)
class Node {
  List<Comment> get leadingComments => [];
  List<Comment> get trailingComments => [];

  String get type => null;
}

class _NodeImpl implements Node {
  @override
  final List<Comment> leadingComments = [], trailingComments = [];

  @override
  String get type => null;
}

abstract class ArgumentListElement implements Node {}

abstract class ArrayExpressionElement implements Node {}

abstract class ArrayPatternElement implements Node {}

abstract class BindingPattern
    implements ArrayPatternElement, FunctionParameter {}

abstract class BindingIdentifier
    implements ArrayPatternElement, FunctionParameter, PropertyValue {}

abstract class Declaration implements Node, Statement {}

abstract class ExportDeclaration implements Declaration {}

abstract class Expression
    implements ArgumentListElement, ArrayExpressionElement {}

abstract class FunctionParameter implements Node {}

abstract class ImportDeclarationSpecifier implements Node {}

abstract class Statement implements Node, StatementListItem {}

abstract class PropertyKey implements Node {}

abstract class PropertyValue implements Node {}

abstract class StatementListItem implements Node {}

class ArrayExpression extends _NodeImpl implements Expression {
  final String type = syntax.ArrayExpression;
  final List<ArrayExpressionElement> elements = [];

  ArrayExpression({List<ArrayExpressionElement> elements: const []}) {
    if (elements != null) this.elements.addAll(elements);
  }
}

class ArrayPattern extends _NodeImpl
    implements ArrayPatternElement, BindingPattern {
  final String type = syntax.ArrayPattern;
  final List<ArrayPatternElement> elements = [];

  ArrayPattern({List<ArrayPatternElement> elements: const []}) {
    if (elements != null) this.elements.addAll(elements);
  }
}

class ArrowFunctionExpression extends _NodeImpl implements Expression {
  final String type = syntax.ArrowFunctionExpression;
  Identifier id;
  final List<Expression> defaults = [];
  final List<FunctionParameter> params = [];
  var body;
  bool generator;
  bool expression;
  Identifier rest;

  ArrowFunctionExpression({
    this.id,
    this.body,
    this.expression: false,
    this.generator,
    this.rest,
    List<Expression> defaults: const [],
    List<FunctionParameter> params: const []
  }) {
    if (defaults != null) this.defaults.addAll(defaults);
    if (params != null) this.params.addAll(params);
  }
}

class AssignmentExpression extends _NodeImpl
    implements Expression, PropertyValue {
  final String type = syntax.AssignmentExpression;
  String operator;
  Expression left;
  Expression right;

  AssignmentExpression({this.operator, this.left, this.right});
}

class AssignmentPattern extends _NodeImpl
    implements ArrayPatternElement, FunctionParameter {
  final String type = syntax.AssignmentPattern;
  dynamic left;
  Expression right;

  AssignmentPattern({this.left, this.right});
}

// Todo: Try to make this into two different classes?
class BinaryExpression extends _NodeImpl implements Expression {
  String _type;
  String get type => _type;
  String operator;
  Expression left;
  Expression right;

  BinaryExpression({this.left, this.operator, this.right}) {
    final logical = (identical(operator, "||") || identical(operator, "&&"));
    _type = logical ? syntax.LogicalExpression : syntax.BinaryExpression;
  }
}

class BlockStatement extends _NodeImpl implements Statement {
  final String type = syntax.BlockStatement;
  List<Statement> body;

  BlockStatement({List<Statement> body: const []}) {
    if (body != null) this.body.addAll(body);
  }
}

class BreakStatement extends _NodeImpl implements Statement {
  final String type = syntax.BreakStatement;
  Identifier label;

  BreakStatement({this.label});
}

class CallExpression extends _NodeImpl implements Expression {
  final String type = syntax.CallExpression;
  Expression callee;
  List<ArgumentListElement> arguments;

  CallExpression({this.callee, List<ArgumentListElement> arguments: const []}) {
    if (arguments != null) this.arguments.addAll(arguments);
  }
}

class CatchClause extends _NodeImpl {
  final String type = syntax.CatchClause;
  dynamic param;
  BlockStatement body;

  CatchClause({this.body, this.param});
}

class ClassBody extends _NodeImpl {
  final String type = syntax.ClassBody;
  List<Property> body;

  ClassBody({List<Property> body: const []}) {
    if (body != null) this.body.addAll(body);
  }
}

class ClassDeclaration extends _NodeImpl implements Declaration {
  final String type = syntax.ClassDeclaration;
  Identifier id;
  Identifier superClass;
  ClassBody body;

  ClassDeclaration({this.id, this.superClass, this.body});
}

class ClassExpression extends _NodeImpl implements Expression {
  final String type = syntax.ClassExpression;
  Identifier id;
  Identifier superClass;
  ClassBody body;

  ClassExpression({this.id, this.superClass, this.body});
}

class ComputedMemberExpression extends _NodeImpl implements Expression {
  final String type = syntax.MemberExpression;
  bool computed;
  Expression object;
  Expression property;

  ComputedMemberExpression({this.object, this.property, this.computed: true});
}

class ConditionalExpression extends _NodeImpl implements Expression {
  final String type = syntax.ConditionalExpression;
  Expression test;
  Expression consequent;
  Expression alternate;

  ConditionalExpression({this.test, this.consequent, this.alternate});
}

class ContinueStatement extends _NodeImpl implements Statement {
  final String type = syntax.ContinueStatement;
  Identifier label;

  ContinueStatement({this.label});
}

class DebuggerStatement extends _NodeImpl implements Statement {
  final String type = syntax.DebuggerStatement;
}

class Directive extends _NodeImpl implements Statement {
  final String type = syntax.ExpressionStatement;
  Expression expression;
  String directive;

  Directive({this.expression, this.directive});
}

class DoWhileStatement extends _NodeImpl implements Statement {
  final String type = syntax.DoWhileStatement;
  Statement body;
  Expression test;

  DoWhileStatement({this.body, this.test});
}

class EmptyStatement extends _NodeImpl implements Statement {
  final String type = syntax.EmptyStatement;
}

class ExportAllDeclaration extends _NodeImpl implements ExportDeclaration {
  final String type = syntax.ExportAllDeclaration;
  Literal source;

  ExportAllDeclaration({this.source});
}

class ExportDefaultDeclaration extends _NodeImpl implements ExportDeclaration {
  final String type = syntax.ExportDefaultDeclaration;
  dynamic declaration;

  ExportDefaultDeclaration({this.declaration});
}

class ExportNamedDeclaration extends _NodeImpl implements ExportDeclaration {
  final String type = syntax.ExportNamedDeclaration;
  dynamic declaration;
  final List<ExportSpecifier> specifiers = [];
  Literal source;

  ExportNamedDeclaration(
      {this.declaration,
      this.source,
      List<ExportSpecifier> specifiers: const []}) {
    if (specifiers != null) this.specifiers.addAll(specifiers);
  }
}

class ExportSpecifier {
  final String type = syntax.ExportSpecifier;
  Identifier exported;
  Identifier local;

  ExportSpecifier({this.local, this.exported});
}

class ExpressionStatement extends _NodeImpl implements Statement {
  final String type = syntax.ExpressionStatement;
  Expression expression;

  ExpressionStatement({this.expression});
}

class ForInStatement extends _NodeImpl implements Statement {
  final String type = syntax.ForInStatement;
  Expression left;
  Expression right;
  Statement body;
  bool each;

  ForInStatement({this.body, this.each: false, this.left, this.right});
}

class ForOfStatement extends _NodeImpl implements Statement {
  final String type = syntax.ForOfStatement;
  Expression left;
  Expression right;
  Statement body;
  ForOfStatement({this.body, this.left, this.right});
}

class ForStatement extends _NodeImpl implements Statement {
  final String type = syntax.ForOfStatement;
  Expression init;
  Expression test;
  Expression update;
  Statement body;

  ForStatement({this.init, this.test, this.update, this.body});
}

// Todo: Change all lower to named params? Actually, change each one as you use it. ;)
class FunctionDeclaration extends _NodeImpl implements Declaration, Statement {
  final String type = syntax.FunctionDeclaration;
  Identifier id;
  final List<FunctionParameter> params = [];
  BlockStatement body;
  final List<Expression> defaults = [];
  bool generator;
  bool expression;
  Identifier rest;

  FunctionDeclaration(
      {this.id,
      this.body,
      this.generator,
      this.expression: true,
      this.rest,
      List<Expression> defaults: const [],
      List<FunctionParameter> params: const []}) {
    if (defaults != null) this.defaults.addAll(defaults);
    if (params != null) this.params.addAll(params);
  }
}

class FunctionExpression extends _NodeImpl
    implements Expression, PropertyValue {
  final String type = syntax.FunctionExpression;
  Identifier id;
  final List<Expression> defaults = [];
  final List<FunctionParameter> params = [];
  BlockStatement body;
  bool generator;
  bool expression;
  Identifier rest;

  FunctionExpression(
      {this.id,
      this.body,
      this.generator,
      this.expression,
      this.rest,
      List<Expression> defaults: const [],
      List<FunctionParameter> params: const []}) {
    if (defaults != null) this.defaults.addAll(defaults);
    if (params != null) this.params.addAll(params);
  }
}

class Identifier extends _NodeImpl
    implements BindingIdentifier, Expression, PropertyKey {
  final String type = syntax.Identifier;
  String name;

  Identifier({this.name});
}

class IfStatement extends _NodeImpl implements Statement {
  final String type = syntax.IfStatement;
  Expression test;
  Statement consequent;
  Statement alternate;

  IfStatement({this.alternate, this.consequent, this.test});
}

class ImportDeclaration extends _NodeImpl implements Declaration {
  final String type = syntax.ImportDeclaration;
  final List<ImportDeclarationSpecifier> specifiers = [];
  Literal source;

  ImportDeclaration(List<ImportDeclarationSpecifier> specifiers, source) {
    this.specifiers.addAll(specifiers);
    this.source = source;
  }
}

class ImportDefaultSpecifier extends _NodeImpl
    implements ImportDeclarationSpecifier {
  final String type = syntax.ImportDefaultSpecifier;
  Identifier local;
  ImportDefaultSpecifier(Identifier local) {
    this.local = local;
  }
}

class ImportNamespaceSpecifier extends _NodeImpl
    implements ImportDeclarationSpecifier {
  final String type = syntax.ImportNamespaceSpecifier;
  Identifier local;
  ImportNamespaceSpecifier(Identifier local) {
    this.local = local;
  }
}

class ImportSpecifier extends _NodeImpl implements ImportDeclarationSpecifier {
  final String type = syntax.ImportSpecifier;
  Identifier local;
  Identifier imported;
  ImportSpecifier(Identifier local, Identifier imported) {
    this.local = local;
    this.imported = imported;
  }
}

class LabeledStatement extends _NodeImpl implements Statement {
  final String type = syntax.LabeledStatement;
  Identifier label;
  Statement body;
  LabeledStatement(Identifier label, Statement body) {
    this.label = label;
    this.body = body;
  }
}

class Literal extends _NodeImpl implements Expression, PropertyKey {
  final String type = syntax.Literal;
  dynamic value;
  String raw;

  Literal({this.value, this.raw});
}

class LetStatement extends _NodeImpl implements Statement {
  final String type = syntax.LetStatement;
  final List<VariableDeclarator> head = [];
  Statement body;

  LetStatement({this.body, List<VariableDeclarator> head: const []}) {
    if (head != null) this.head.addAll(head);
  }
}

class MetaProperty {
  final String type = syntax.MetaProperty;
  Identifier meta;
  Identifier property;
  MetaProperty(Identifier meta, Identifier property) {
    this.meta = meta;
    this.property = property;
  }
}

class MethodDefinition {
  final String type = syntax.MethodDefinition;
  Expression key;
  bool computed;
  FunctionExpression value;
  String kind;
  bool static;
  MethodDefinition(Expression key, bool computed, FunctionExpression value,
      String kind, bool isStatic) {
    this.key = key;
    this.computed = computed;
    this.value = value;
    this.kind = kind;
    this.static = isStatic;
  }
}

class NewExpression extends _NodeImpl implements Expression {
  final String type = syntax.NewExpression;
  Expression callee;
  final List<ArgumentListElement> arguments = [];

  NewExpression({this.callee, List<ArgumentListElement> args: const []}) {
    if (args != null)
      this.arguments.addAll(args);
  }
}

class ObjectExpression extends _NodeImpl implements Expression {
  final String type = syntax.ObjectExpression;
  final List<Property> properties = [];

  ObjectExpression({List<Property> properties: const []}){
    if (properties != null)
      this.properties.addAll(properties);
  }
}

class ObjectPattern extends _NodeImpl implements BindingPattern {
  final String type = syntax.ObjectPattern;
  final List<Property> properties = [];

  ObjectPattern({List<Property> properties: const []}) {
    if (properties != null)
      this.properties.addAll(properties);
  }
}

class Program extends _NodeImpl {
  final String type = syntax.Program;
  final List<StatementListItem> body = [];
  String sourceType;

  Program({this.sourceType, List<StatementListItem> body: const []}) {
    if (body != null) this.body.addAll(body);
  }
}

class Property extends _NodeImpl {
  static const String GET = 'get';
  static const String INIT = 'init';
  static const String SET = 'set';

  final String type = syntax.Property;
  PropertyKey key;
  bool computed;
  PropertyValue value;
  String kind;
  bool method;
  bool shorthand;

  Property({this.key, this.computed, this.value, this.kind, this.method, this.shorthand});
}

class RegexLiteral extends _NodeImpl implements Expression {
  final String type = syntax.Literal;
  String value;
  String raw;
  dynamic regex;
  RegexLiteral(String value, String raw, regex) {
    this.value = value;
    this.raw = raw;
    this.regex = regex;
  }
}

class RestElement extends _NodeImpl implements ArrayPatternElement {
  final String type = syntax.RestElement;
  Identifier argument;
  RestElement(Identifier argument) {
    this.argument = argument;
  }
}

class ReturnStatement extends _NodeImpl implements Statement {
  final String type = syntax.ReturnStatement;
  Expression argument;

  ReturnStatement({this.argument});
}

class SequenceExpression extends _NodeImpl implements Expression {
  final String type = syntax.SequenceExpression;
  final List<Expression> expressions = [];
  SequenceExpression({List<Expression> expressions: const []}) {
    if (expressions != null)
      this.expressions.addAll(expressions);
  }
}

class SpreadElement extends _NodeImpl
    implements ArrayExpressionElement, ArgumentListElement {
  final String type = syntax.SpreadElement;
  final Expression argument;
  SpreadElement({this.argument});
}

class StaticMemberExpression extends _NodeImpl implements Expression {
  final String type = syntax.MemberExpression;
  bool computed;
  Expression object;
  Expression property;

  StaticMemberExpression({this.computed: false, this.object, this.property});
}

class Super extends _NodeImpl {
  final String type = syntax.Super;
  Super();
}

class SwitchCase extends _NodeImpl {
  final String type = syntax.SwitchCase;
  Expression test;
  final List<Statement> consequent = [];

  SwitchCase({this.test, List<Statement> consequent}) {
    if (consequent != null)
      this.consequent.addAll(consequent);
  }
}

class SwitchStatement extends _NodeImpl implements Statement {
  final String type = syntax.SwitchStatement;
  Expression discriminant;
  final List<SwitchCase> cases = [];

  SwitchStatement({this.discriminant, List<SwitchCase> cases: const []}) {
    if (cases != null) this.cases.addAll(cases);
  }
}

class TaggedTemplateExpression extends _NodeImpl implements Expression {
  final String type = syntax.TaggedTemplateExpression;
  Expression tag;
  TemplateLiteral quasi;
  TaggedTemplateExpression(Expression tag, TemplateLiteral quasi) {
    this.tag = tag;
    this.quasi = quasi;
  }
}

class TemplateElement extends _NodeImpl {
  final String type = syntax.TemplateElement;
  ScannedTemplate value;
  bool tail;
  TemplateElement({this.value, this.tail}) {
    this.value = value;
    this.tail = tail;
  }
}

class TemplateLiteral extends _NodeImpl {
  final String type = syntax.TemplateLiteral;
  final List<TemplateElement> quasis = [];
  List<Expression> expressions;
  TemplateLiteral(
      {List<TemplateElement> quasis, List<Expression> expressions}) {
    if (quasis != null) this.quasis.addAll(quasis);

    if (expressions != null) this.expressions.addAll(expressions);
  }
}

class ThisExpression extends _NodeImpl implements Expression {
  final String type = syntax.ThisExpression;
}

class ThrowStatement extends _NodeImpl implements Statement {
  final String type = syntax.ThrowStatement;
  Expression argument;

  ThrowStatement({this.argument});
}

class TryStatement extends _NodeImpl implements Statement {
  final String type = syntax.TryStatement;
  BlockStatement block;
  final List<CatchClause> guardedHandlers = [];
  CatchClause handler;
  BlockStatement finalizer;

  TryStatement(
      {this.block,
      this.handler,
      this.finalizer,
      List<CatchClause> guardedHandlers: const []}) {
    if (guardedHandlers != null) this.guardedHandlers.addAll(guardedHandlers);
  }
}

class UnaryExpression extends _NodeImpl implements Expression {
  final String type = syntax.UnaryExpression;
  String operator;
  Expression argument;
  bool prefix;
  UnaryExpression({this.argument, this.operator, this.prefix: true});
}

class UpdateExpression extends _NodeImpl implements Expression {
  final String type = syntax.UpdateExpression;
  String operator;
  Expression argument;
  bool prefix;
  UpdateExpression({this.argument, this.operator, this.prefix: true});
}

class VariableDeclaration extends _NodeImpl implements Declaration, Statement {
  static const String CONST = 'const';
  static const String LET = 'let';
  static const String VAR = 'var';

  final String type = syntax.VariableDeclaration;
  final List<VariableDeclarator> declarations = [];
  String kind;

  VariableDeclaration({this.kind, List<VariableDeclarator> declarations}) {
    if (declarations != null) this.declarations.addAll(declarations);
  }
}

class VariableDeclarator extends _NodeImpl {
  final String type = syntax.VariableDeclarator;
  BindingPattern id;
  Expression init;
  VariableDeclarator({this.id, this.init});
}

class WhileStatement extends _NodeImpl implements Statement {
  final String type = syntax.WhileStatement;
  Expression test;
  Statement body;

  WhileStatement({this.body, this.test});
}

class WithStatement extends _NodeImpl implements Statement {
  final String type = syntax.WithStatement;
  Expression object;
  Statement body;

  WithStatement({this.body, this.object});
}

// Todo: Default values for all bools
class YieldExpression extends _NodeImpl implements Expression {
  final String type = syntax.YieldExpression;
  Expression argument;
  bool delegate;

  YieldExpression({this.argument, this.delegate: true});
}
