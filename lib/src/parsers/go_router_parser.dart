import 'dart:io';

import 'package:_fe_analyzer_shared/src/scanner/token.dart' show CommentToken;
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../models/route_definition.dart';

/// Parse go_router route definitions
class GoRouterParser {
  /// Extract route definitions from source files
  Future<List<RouteDefinition>> parse(List<String> sourcePaths) async {
    final routes = <RouteDefinition>[];

    for (final path in sourcePaths) {
      final file = File(path);
      if (!file.existsSync()) {
        throw ParserException('File not found: $path');
      }

      final content = await file.readAsString();
      final parseResult = parseString(content: content);
      final unit = parseResult.unit;

      final visitor = _GoRouteVisitor();
      unit.visitChildren(visitor);

      routes.addAll(visitor.routes);
    }

    return routes;
  }
}

class _GoRouteVisitor extends RecursiveAstVisitor<void> {
  final List<RouteDefinition> routes = [];

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'GoRoute' ||
        node.target?.toString() == 'GoRoute') {
      _processGoRoute(node);
    }
    super.visitMethodInvocation(node);
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    final typeName = node.constructorName.type.name2.lexeme;
    if (typeName == 'GoRoute') {
      _processGoRouteInstance(node);
    }
    super.visitInstanceCreationExpression(node);
  }

  void _processGoRoute(MethodInvocation node) {
    final arguments = node.argumentList.arguments;
    _extractRouteFromArguments(arguments, node);
  }

  void _processGoRouteInstance(InstanceCreationExpression node) {
    final arguments = node.argumentList.arguments;
    _extractRouteFromArguments(arguments, node);
  }

  void _extractRouteFromArguments(NodeList<Expression> arguments, AstNode node) {
    String? path;
    String? name;
    String? description;
    String? screenClass;

    // Look for @ga_description comment
    final precedingComments = _findPrecedingComment(node);
    if (precedingComments != null) {
      final descMatch = RegExp(r'@ga_description:\s*(.+)').firstMatch(precedingComments);
      if (descMatch != null) {
        description = descMatch.group(1)?.trim();
      }
    }

    for (final arg in arguments) {
      if (arg is NamedExpression) {
        final argName = arg.name.label.name;
        final value = arg.expression;

        switch (argName) {
          case 'path':
            path = _extractStringValue(value);
            break;
          case 'name':
            name = _extractStringValue(value);
            break;
          case 'builder' || 'pageBuilder':
            screenClass = _extractScreenClass(value);
            break;
        }
      }
    }

    if (path != null) {
      routes.add(RouteDefinition(
        path: path,
        name: name,
        description: description,
        screenClass: screenClass,
        lastUpdated: DateTime.now(),
      ));
    }
  }

  String? _extractStringValue(Expression expr) {
    if (expr is StringLiteral) {
      return expr.stringValue;
    }
    if (expr is SimpleIdentifier) {
      return expr.name;
    }
    return null;
  }

  String? _extractScreenClass(Expression expr) {
    // builder: (context, state) => const HomeScreen()
    // builder: (context, state) => HomeScreen()
    if (expr is FunctionExpression) {
      final body = expr.body;
      if (body is ExpressionFunctionBody) {
        return _extractScreenFromExpression(body.expression);
      } else if (body is BlockFunctionBody) {
        // Look for return statement
        final visitor = _ReturnStatementVisitor();
        body.visitChildren(visitor);
        if (visitor.returnExpression != null) {
          return _extractScreenFromExpression(visitor.returnExpression!);
        }
      }
    }
    return null;
  }

  String? _extractScreenFromExpression(Expression expr) {
    if (expr is InstanceCreationExpression) {
      return expr.constructorName.type.name2.lexeme;
    }
    if (expr is MethodInvocation) {
      return expr.methodName.name;
    }
    return null;
  }

  String? _findPrecedingComment(AstNode node) {
    final token = node.beginToken;
    final comments = <String>[];

    var comment = token.precedingComments;
    while (comment != null) {
      comments.add(comment.lexeme);
      final next = comment.next;
      if (next == null || next is! CommentToken) break;
      comment = next;
    }

    if (comments.isEmpty) return null;
    return comments.join('\n');
  }
}

class _ReturnStatementVisitor extends RecursiveAstVisitor<void> {
  Expression? returnExpression;

  @override
  void visitReturnStatement(ReturnStatement node) {
    returnExpression = node.expression;
  }
}

/// Parser exception
class ParserException implements Exception {
  final String message;

  const ParserException(this.message);

  @override
  String toString() => 'ParserException: $message';
}
