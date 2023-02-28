import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart' as ast;
import 'package:analyzer/dart/ast/visitor.dart';

class StringLiteralVisitor extends GeneralizingAstVisitor<Map> {
  List<String> result = [];
  final List<String> ignoreStrings = [
    "\u2026",
    "😄",
    "🐛",
    "❗",
    "❌",
    "⬆️",
    "⬇️",
    "🎤",
    "📹",
    "\u{200B}",
    " |[a-zA-Z]|[\u4e00-\u9fa5]|[0-9]",
  ];

  @override
  Map visitNode(ast.AstNode node) {
    // stdout.writeln("${node.runtimeType}<---->${node.toSource()}");
    return super.visitNode(node);
  }

  @override
  Map visitStringInterpolation(ast.StringInterpolation node) {
    if (shouldIgnore(node)) return super.visitStringInterpolation(node);

    const expressionMark = '%s';

    final stringValue = node.elements.map((e) {
      if (e is ast.InterpolationString) {
        return e.value;
      } else {
        return expressionMark;
      }
    }).join();

    if (stringValue.replaceAll(expressionMark, '').trim().isEmpty ||
        isAscii(stringValue)) {
      return super.visitStringInterpolation(node);
    }

    stdout.writeln('Offset: ${node.offset} ${stringValue}');
    result.add(stringValue);
    return super.visitStringInterpolation(node);
  }

  @override
  Map visitSimpleStringLiteral(ast.SimpleStringLiteral node) {
    if (shouldIgnore(node)) return super.visitSimpleStringLiteral(node);

    final stringValue = node.stringValue;
    if (stringValue.trim().isEmpty || isAscii(stringValue)) {
      return super.visitSimpleStringLiteral(node);
    }

    stdout.writeln('Offset: ${node.offset} ${stringValue}');
    result.add(stringValue);
    return super.visitSimpleStringLiteral(node);
  }

  bool isAscii(String stringValue) {
    for (var i = 0; i < stringValue.length; i++) {
      if (stringValue.codeUnitAt(i) > 255) return false;
    }
    return true;
  }

  bool shouldIgnore(ast.AstNode node) {
    if (node.parent is ast.ImportDirective ||
        node.parent is ast.IndexExpression ||
        node.parent is ast.SwitchCase ||
        node.parent is ast.MapLiteralEntry) {
      return true;
    }

    if (node.parent.parent is ast.MethodInvocation) {
      final methodInvocation = node.parent.parent as ast.MethodInvocation;
      final methodName = methodInvocation.methodName.name;
      final targetName = methodInvocation.target.toString();

      /// 过滤logger日志
      if (const ['logger'].contains(targetName)) {
        if (const [
          'finest',
          'finer',
          'fine',
          'config',
          'info',
          'warning',
          'severe',
          'shout',
          'log'
        ].contains(methodName)) {
          return true;
        }
      }

      /// 过滤其他类型日志
      if (const ['debugPrint', 'print', 'log', 'warn', 'error', 'finer', 'info']
          .contains(methodName)) {
        return true;
      }
    }

    /// 处理特殊字符
    if (node is ast.SimpleStringLiteral) {
      for (final string in ignoreStrings) {
        if (node.stringValue == string) {
          return true;
        }
      }
    }

    return false;
  }
}
