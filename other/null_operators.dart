import "dart:io";

import "package:analyzer/src/generated/source.dart";
import "package:analyzer/src/generated/parser.dart";
import "package:analyzer/src/string_source.dart";
import "package:analyzer/src/generated/scanner.dart";
import "package:analyzer/src/generated/ast.dart";
import "package:analyzer/src/error.dart";
import "package:analyzer/src/generated/error.dart";
import "package:analyzer/src/generated/java_core.dart";

void main(List<String> args) {
  if (args.isEmpty) {
    print("Usage: null_operators <files>");
    exit(1);
  }

  for (var path in args) {
    var file = new File(path);
    var cu = parseCompilationUnit(file.readAsStringSync());
    var writer = new PrintStringWriter();
    cu.accept(new NullOperatorVisitor(writer));
    new File("${file.parent.path}/compiled_${new Uri.file(file.path).pathSegments.last}")
      .writeAsStringSync(writer.toString());
  }
}

class NullOperatorVisitor extends ToSourceVisitor {
  PrintWriter writer;

  NullOperatorVisitor(PrintWriter w) : super(w) {
    writer = w;
  }

  @override
  visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      writer.print("__push__(");
      node.leftOperand.accept(this);
      writer.print(") != null ? __pop__() : __popm__(");
      node.rightOperand.accept(this);
      writer.print(")");
    } else {
      super.visitBinaryExpression(node);
    }
  }

  @override
  visitAssignmentExpression(AssignmentExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION_EQ) {
      _visitNode(node.leftHandSide);
      writer.print(' ');
      writer.print('=');
      writer.print(' ');
      writer.print("__push__(");
      node.leftHandSide.accept(this);
      writer.print(") != null ? __pop__() : __popm__(");
      node.rightHandSide.accept(this);
      writer.print(")");
    } else {
      _visitNode(node.leftHandSide);
      writer.print(' ');
      writer.print(node.operator.lexeme);
      writer.print(' ');
      _visitNode(node.rightHandSide);
    }
  }

  @override
  visitPropertyAccess(PropertyAccess node) {
    if (node.isCascaded) {
      writer.print("..");
    } else {
      if (node.operator.type == TokenType.QUESTION_PERIOD) {
        writer.print("__push__(");
        _visitNode(node.target);
        writer.print(") != null ? __pop__() : ");
        writer.print("__popm__(null).");
      } else {
        writer.print(node.operator.lexeme);
      }
    }
    _visitNode(node.propertyName);
    return null;
  }

  @override
  visitCompilationUnit(CompilationUnit node) {
    ScriptTag scriptTag = node.scriptTag;
    NodeList<Directive> directives = node.directives;
    _visitNode(scriptTag);
    String prefix = scriptTag == null ? "" : " ";
    _visitNodeListWithSeparatorAndPrefix(prefix, directives, " ");
    prefix = scriptTag == null && directives.isEmpty ? "" : " ";
    [
      "var __stack__=[];",
      "__push__(x){__stack__.add(x);return x;}",
      "__pop__()=>__stack__.removeLast();",
      "__popm__(x){__pop__();return x;}"
    ].forEach(writer.print);
    _visitNodeListWithSeparatorAndPrefix(prefix, node.declarations, " ");
    return null;
  }

  void _visitNode(AstNode node) {
    if (node != null) {
      node.accept(this);
    }
  }

  void _visitNodeListWithSeparatorAndPrefix(String prefix, NodeList<AstNode> nodes, String separator) {
    if (nodes != null) {
      int size = nodes.length;
      if (size > 0) {
        writer.print(prefix);
        for (int i = 0; i < size; i++) {
          if (i > 0) {
            writer.print(separator);
          }
          nodes[i].accept(this);
        }
      }
    }
  }
}

CompilationUnit parseCompilationUnit(String contents,
                                     {String name, bool suppressErrors: false}) {
  if (name == null) name = '<unknown source>';
  var source = new StringSource(contents, name);
  var errorCollector = new _ErrorCollector();
  var reader = new CharSequenceReader(contents);
  var scanner = new Scanner(source, reader, errorCollector);
  scanner.enableNullAwareOperators = true;
  var token = scanner.tokenize();
  var parser = new Parser(source, errorCollector);
  var unit = parser.parseCompilationUnit(token);
  unit.lineInfo = new LineInfo(scanner.lineStarts);

  if (errorCollector.hasErrors && !suppressErrors) throw errorCollector.group;

  return unit;
}

/// A simple error listener that collects errors into an [AnalysisErrorGroup].
class _ErrorCollector extends AnalysisErrorListener {
  final _errors = <AnalysisError>[];

  _ErrorCollector();

  /// The group of errors collected.
  AnalyzerErrorGroup get group =>
  new AnalyzerErrorGroup.fromAnalysisErrors(_errors);

  /// Whether any errors where collected.
  bool get hasErrors => !_errors.isEmpty;

  void onError(AnalysisError error) => _errors.add(error);
}
