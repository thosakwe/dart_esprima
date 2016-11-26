import 'comment_handler.dart' show Comment;
import "syntax.dart" show Syntax;

// Todo: Look through interfaces for shared fields ;)
class Node {
  final List<Comment> leadingComments = [], trailingComments = [];

  List get body => [];

  String get type;
}

abstract class ArgumentListElement extends Node {}

abstract class ArrayExpressionElement extends Node {}

abstract class ArrayPatternElement extends Node {}

abstract class BindingPattern extends Node {}

abstract class BindingIdentifier extends Node {}

abstract class Declaration extends Node {}

abstract class ExportDeclaration extends Node {}

abstract class Expression extends Node implements ArgumentListElement, ArrayExpressionElement {}

abstract class FunctionParameter extends Node {}

abstract class ImportDeclarationSpecifier extends Node {}

abstract class Statement extends Node {}

abstract class PropertyKey extends Node {}

abstract class PropertyValue extends Node {}

abstract class StatementListItem extends Node {}

class ArrayExpression extends Expression {
  final String type = Syntax.ArrayExpression;
  final List<ArrayExpressionElement> elements = [];

  ArrayExpression({List<ArrayExpressionElement> elements: const []}) {
    if (elements != null) this.elements.addAll(elements);
  }
}

class ArrayPattern extends ArrayPatternElement {
  final String type = Syntax.ArrayPattern;
  final List<ArrayPatternElement> elements = [];

  ArrayPattern({List<ArrayPatternElement> elements: const []}) {
    if (elements != null) this.elements.addAll(elements);
  }
}

class ArrowFunctionExpression extends Expression {
  final String type = Syntax.ArrowFunctionExpression;
  Identifier id;
  final List<FunctionParameter> params = [];
  var body;
  bool generator;
  bool expression;

  ArrowFunctionExpression({
    this.id,
    this.body,
    this.expression: false,
    this.generator,
    List<FunctionParameter> params: const [],
  }) {
    if (params != null) this.params.addAll(params);
  }
}

class AssignmentExpression extends Expression {
  final String type = Syntax.AssignmentExpression;
  String operator;
  Expression left;
  Expression right;

  AssignmentExpression({this.operator, this.left, this.right});
}

class AssignmentPattern {
  final String type = Syntax.AssignmentPattern;
  dynamic left;
  Expression right;
  
  AssignmentPattern({this.left, this.right});
}

class BinaryExpression {
  String _type;
  String get type => _type;
  String operator;
  Expression left;
  Expression right;

  BinaryExpression({this.left, this.operator, this.right}) {
    final logical = (identical(operator, "||") || identical(operator, "&&"));
    _type = logical ? Syntax.LogicalExpression : Syntax.BinaryExpression;
  }
}

class BlockStatement {
  final String type = Syntax.BlockStatement;
  List<Statement> body;

  BlockStatement({List<Statement> body: const []}) {
    if (body != null) this.body.addAll(body);
  }
}

class BreakStatement {
  final String type = Syntax.BreakStatement;
  Identifier label;

  BreakStatement({this.label});
}

class CallExpression {
  final String type = Syntax.CallExpression;
  Expression callee;
  List<ArgumentListElement> arguments;

  CallExpression({this.callee, List<ArgumentListElement> arguments: const []}) {
    if (arguments != null)
    this.arguments.addAll(arguments);
  }
}

class CatchClause {
  final String type = Syntax.CatchClause;
  dynamic param;
  BlockStatement body;

  CatchClause({this.body, this.param});
}

class ClassBody {
  final String type = Syntax.ClassBody;
  List<Property> body;

  ClassBody({List<Property> body: const []}) {
    if (body != null)
      this.body.addAll(body);
  }
}

class ClassDeclaration {
  final String type = Syntax.ClassDeclaration;
  Identifier id;
  Identifier superClass;
  ClassBody body;

  ClassDeclaration({this.id, this.superClass, this.body});
}

class ClassExpression {
  final String type = Syntax.ClassExpression;
  Identifier id;
  Identifier superClass;
  ClassBody body;

  ClassExpression({this.id, this.superClass, this.body});
}

class ComputedMemberExpression {
  final String type = Syntax.MemberExpression;
  bool computed;
  Expression object;
  Expression property;

  ComputedMemberExpression({this.object, this.property, this.computed : true});
}

class ConditionalExpression {
  final String type = Syntax.ConditionalExpression;
  Expression test;
  Expression consequent;
  Expression alternate;

  ConditionalExpression({this.test, this.consequent, this.alternate});
}

class ContinueStatement {
  final String type = Syntax.ContinueStatement;
  Identifier label;

  ContinueStatement({this.label});
}

class DebuggerStatement {
  final String type = Syntax.DebuggerStatement;
}

class Directive {
  final String type = Syntax.ExpressionStatement;
  Expression expression;
  String directive;

  Directive({this.expression, this.directive});
}

class DoWhileStatement {
  final String type = Syntax.DoWhileStatement;
  Statement body;
  Expression test;

  DoWhileStatement({this.body, this.test});
}

class EmptyStatement {
  final String type = Syntax.EmptyStatement;
}

class ExportAllDeclaration {
  final String type = Syntax.ExportAllDeclaration;
  Literal source;

  ExportAllDeclaration({this.source});
}

class ExportDefaultDeclaration {
  final String type = Syntax.ExportDefaultDeclaration;
  dynamic declaration;

  ExportDefaultDeclaration({this.declaration});
}

class ExportNamedDeclaration {
  final String type = Syntax.ExportNamedDeclaration;
  dynamic declaration;
  final List<ExportSpecifier> specifiers = [];
  Literal source;

  ExportNamedDeclaration({this.declaration, this.source, List<ExportSpecifier> specifiers: const []}) {
    if (specifiers != null)
      this.specifiers.addAll(specifiers);
  }
}

class ExportSpecifier {
  final String type = Syntax.ExportSpecifier;
  Identifier exported;
  Identifier local;

  ExportSpecifier({this.local, this.exported});
}

class ExpressionStatement {
  final String type = Syntax.ExpressionStatement;
  Expression expression;

  ExpressionStatement({this.expression});
}

class ForInStatement {
  final String type = Syntax.ForInStatement;
  Expression left;
  Expression right;
  Statement body;
  bool each;

  ForInStatement({this.body, this.each : false, this.left, this.right});
}

class ForOfStatement {
  final String type = Syntax.ForOfStatement;
  Expression left;
  Expression right;
  Statement body;
  ForOfStatement({this.body, this.left, this.right});
}

class ForStatement {
  final String type = Syntax.ForOfStatement;
  Expression init;
  Expression test;
  Expression update;
  Statement body;

  ForStatement({this.init, this.test, this.update, this.body});
}

class FunctionDeclaration {
  final String type;
  Identifier id;
  List<FunctionParameter> params;
  BlockStatement body;
  bool generator;
  bool expression;
  FunctionDeclaration(Identifier id, List<FunctionParameter> params,
      BlockStatement body, bool generator) {
    
    this.id = id;
    this.params = params;
    this.body = body;
    this.generator = generator;
    this.expression = false;
  }
}

class FunctionExpression {
  final String type;
  Identifier id;
  List<FunctionParameter> params;
  BlockStatement body;
  bool generator;
  bool expression;
  FunctionExpression(Identifier id, List<FunctionParameter> params,
      BlockStatement body, bool generator) {
    
    this.id = id;
    this.params = params;
    this.body = body;
    this.generator = generator;
    this.expression = false;
  }
}

class Identifier {
  final String type;
  String name;
  Identifier(name) {
    
    this.name = name;
  }
}

class IfStatement {
  final String type;
  Expression test;
  Statement consequent;
  Statement alternate;
  IfStatement(Expression test, Statement consequent, Statement alternate) {
    
    this.test = test;
    this.consequent = consequent;
    this.alternate = alternate;
  }
}

class ImportDeclaration {
  final String type;
  List<ImportDeclarationSpecifier> specifiers;
  Literal source;
  ImportDeclaration(specifiers, source) {
    
    this.specifiers = specifiers;
    this.source = source;
  }
}

class ImportDefaultSpecifier {
  final String type;
  Identifier local;
  ImportDefaultSpecifier(Identifier local) {
    
    this.local = local;
  }
}

class ImportNamespaceSpecifier {
  final String type;
  Identifier local;
  ImportNamespaceSpecifier(Identifier local) {
    
    this.local = local;
  }
}

class ImportSpecifier {
  final String type;
  Identifier local;
  Identifier imported;
  ImportSpecifier(Identifier local, Identifier imported) {
    
    this.local = local;
    this.imported = imported;
  }
}

class LabeledStatement {
  final String type;
  Identifier label;
  Statement body;
  LabeledStatement(Identifier label, Statement body) {
    
    this.label = label;
    this.body = body;
  }
}

class Literal {
  final String type;
  dynamic value;
  String raw;
  Literal(dynamic value, String raw) {
    
    this.value = value;
    this.raw = raw;
  }
}

class MetaProperty {
  final String type;
  Identifier meta;
  Identifier property;
  MetaProperty(Identifier meta, Identifier property) {
    
    this.meta = meta;
    this.property = property;
  }
}

class MethodDefinition {
  final String type;
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

class NewExpression {
  final String type;
  Expression callee;
  List<ArgumentListElement> arguments;
  NewExpression(Expression callee, List<ArgumentListElement> args) {
    
    this.callee = callee;
    this.arguments = args;
  }
}

class ObjectExpression {
  final String type;
  List<Property> properties;
  ObjectExpression(List<Property> properties) {
    
    this.properties = properties;
  }
}

class ObjectPattern {
  final String type;
  List<Property> properties;
  ObjectPattern(List<Property> properties) {
    
    this.properties = properties;
  }
}

class Program {
  final String type;
  List<StatementListItem> body;
  String sourceType;
  Program(List<StatementListItem> body, String sourceType) {
    
    this.body = body;
    this.sourceType = sourceType;
  }
}

class Property {
  final String type;
  PropertyKey key;
  bool computed;
  PropertyValue value;
  String kind;
  bool method;
  bool shorthand;
  Property(String kind, PropertyKey key, bool computed, PropertyValue value,
      bool method, bool shorthand) {
    
    this.key = key;
    this.computed = computed;
    this.value = value;
    this.kind = kind;
    this.method = method;
    this.shorthand = shorthand;
  }
}

class RegexLiteral {
  final String type;
  String value;
  String raw;
  dynamic regex;
  RegexLiteral(String value, String raw, regex) {
    
    this.value = value;
    this.raw = raw;
    this.regex = regex;
  }
}

class RestElement {
  final String type;
  Identifier argument;
  RestElement(Identifier argument) {
    
    this.argument = argument;
  }
}

class ReturnStatement {
  final String type;
  Expression argument;
  ReturnStatement(Expression argument) {
    
    this.argument = argument;
  }
}

class SequenceExpression {
  final String type;
  List<Expression> expressions;
  SequenceExpression(List<Expression> expressions) {
    
    this.expressions = expressions;
  }
}

class SpreadElement extends ArrayExpressionElement, ArgumentListElement {
  final String type;
  final Expression argument;
  SpreadElement({this.argument});
}

class StaticMemberExpression {
  final String type;
  bool computed;
  Expression object;
  Expression property;
  StaticMemberExpression(Expression object, Expression property) {
    
    this.computed = false;
    this.object = object;
    this.property = property;
  }
}

class Super {
  final String type;
  Super() {
    
  }
}

class SwitchCase {
  final String type;
  Expression test;
  List<Statement> consequent;
  SwitchCase(Expression test, List<Statement> consequent) {
    
    this.test = test;
    this.consequent = consequent;
  }
}

class SwitchStatement {
  final String type;
  Expression discriminant;
  List<SwitchCase> cases;
  SwitchStatement(Expression discriminant, List<SwitchCase> cases) {
    
    this.discriminant = discriminant;
    this.cases = cases;
  }
}

class TaggedTemplateExpression {
  final String type;
  Expression tag;
  TemplateLiteral quasi;
  TaggedTemplateExpression(Expression tag, TemplateLiteral quasi) {
    
    this.tag = tag;
    this.quasi = quasi;
  }
}

class TemplateElementValue extends Node {
  String cooked;
  String raw;
}

class TemplateElement {
  final String type;
  TemplateElementValue value;
  bool tail;
  TemplateElement(TemplateElementValue value, bool tail) {
    
    this.value = value;
    this.tail = tail;
  }
}

class TemplateLiteral {
  final String type;
  List<TemplateElement> quasis;
  List<Expression> expressions;
  TemplateLiteral(List<TemplateElement> quasis, List<Expression> expressions) {
    
    this.quasis = quasis;
    this.expressions = expressions;
  }
}

class ThisExpression {
  final String type;
  ThisExpression() {
    
  }
}

class ThrowStatement {
  final String type;
  Expression argument;
  ThrowStatement(Expression argument) {
    
    this.argument = argument;
  }
}

class TryStatement {
  final String type;
  BlockStatement block;
  CatchClause handler;
  BlockStatement finalizer;
  TryStatement(
      BlockStatement block, CatchClause handler, BlockStatement finalizer) {
    
    this.block = block;
    this.handler = handler;
    this.finalizer = finalizer;
  }
}

class UnaryExpression {
  final String type;
  String operator;
  Expression argument;
  bool prefix;
  UnaryExpression(operator, argument) {
    
    this.operator = operator;
    this.argument = argument;
    this.prefix = true;
  }
}

class UpdateExpression {
  final String type;
  String operator;
  Expression argument;
  bool prefix;
  UpdateExpression(operator, argument, prefix) {
    
    this.operator = operator;
    this.argument = argument;
    this.prefix = prefix;
  }
}

class VariableDeclaration {
  final String type;
  List<VariableDeclarator> declarations;
  String kind;
  VariableDeclaration(List<VariableDeclarator> declarations, String kind) {
    
    this.declarations = declarations;
    this.kind = kind;
  }
}

class VariableDeclarator {
  final String type;
  dynamic id;
  Expression init;
  VariableDeclarator(
      dynamic id, Expression init) {
    
    this.id = id;
    this.init = init;
  }
}

class WhileStatement {
  final String type;
  Expression test;
  Statement body;
  WhileStatement(Expression test, Statement body) {
    
    this.test = test;
    this.body = body;
  }
}

class WithStatement {
  final String type;
  Expression object;
  Statement body;
  WithStatement(Expression object, Statement body) {
    
    this.object = object;
    this.body = body;
  }
}

class YieldExpression {
  final String type;
  Expression argument;
  bool delegate;
  YieldExpression(Expression argument, bool delegate) {
    
    this.argument = argument;
    this.delegate = delegate;
  }
}
