import "package:analyzer/src/generated/source.dart";
import "package:analyzer/src/generated/parser.dart";
import "package:analyzer/src/string_source.dart";
import "package:analyzer/src/generated/scanner.dart";
import "package:analyzer/src/generated/ast.dart";
import "package:analyzer/src/error.dart";
import "package:analyzer/src/generated/error.dart";

void main() {
  var cu = parseCompilationUnit("""
  void main() {
    print("Hi" ?? "Google");
  }
  """);

  cu = new NullOperatorVisitor().visitCompilationUnit(cu);

  print(cu.toSource());
}

class NullOperatorVisitor extends AstCloner {
  @override
  visitBinaryExpression(BinaryExpression node) {
    if (node.operator.type == TokenType.QUESTION_QUESTION) {
      return new ConditionalExpression(
        new BinaryExpression(
          node.leftOperand,
          new Token(TokenType.BANG_EQ, 0),
          new NullLiteral(new Token(TokenType.KEYWORD, 0))
        ),
        new Token(TokenType.QUESTION, 0),
        node.leftOperand,
        new Token(TokenType.COLON, 0),
        node.rightOperand
      );
    } else {
      return node;
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
