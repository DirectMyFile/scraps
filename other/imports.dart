import "package:analyzer/analyzer.dart";
import "package:analyzer/src/generated/scanner.dart";

void rewriteImports(CompilationUnit cu, String rewrite(String uri)) {
  List<ImportDirective> imports = cu.directives.where((it) => it is ImportDirective).toList();

  for (var import in imports) {
    var v = rewrite(import.uri.stringValue);
    import.uri = new SimpleStringLiteral(new StringToken(TokenType.STRING, '"' + v + '"', 0), v);
  }
}

const String INPUT = """
import "github:DirectMyFile/scraps/tools/which.dart" as which;

void main() {
  which.main(["dart"]);
}
""";

void main() {
  var unit = parseCompilationUnit(INPUT);
  rewriteImports(unit, (url) {
    if (url.startsWith("github:")) {
      var uri = Uri.parse(url);

      if (uri.pathSegments.length < 3) {
        throw new Exception("Failed to rewrite GitHub Import. Invalid!");
      }

      var slug = uri.pathSegments.take(2).join("/");
      var path = uri.pathSegments.skip(2).join("/");
      var ref = "HEAD";
      if (uri.hasFragment && uri.fragment.isNotEmpty) {
        ref = uri.fragment;
      }
      return "https://raw.githubusercontent.com/${slug}/${ref}/${path}";
    }

    return url;
  });
  print(unit.toSource());
}
