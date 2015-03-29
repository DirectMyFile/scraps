class PowerRegExp {
  static final RegExp REFERENCE = new RegExp(r"@\{(.+?)\}");

  final Map<String, RegExp> expressions;
  final Map<String, String> lazyExpressions;

  PowerRegExp() : expressions = <String, RegExp>{}, lazyExpressions = <String, String>{};

  void add(String name, String pattern, {bool lazy: true}) {
    pattern = clean(pattern);

    lazyExpressions[name] = pattern;

    if (!lazy) {
      get(name);
    }
  }

  RegExp build(String input) {
    return _build(input);
  }

  RegExp get(String name) {
    if (expressions.containsKey(name)) {
      return expressions[name];
    } else if (lazyExpressions.containsKey(name)) {
      var m = lazyExpressions.remove(name);
      return expressions[name] = _build(m);
    } else {
      throw new Exception("Failed to get reference expression '${name}'. Not Found!");
    }
  }

  String clean(String input) {
    return input
      .replaceAll(new RegExp(r"(\s*)\/\*(.*)\*\/(\s*)"), "")
      .split("\n")
      .map((it) => it.trimLeft())
      .join("");
  }

  RegExp _build(String input) {
    input = clean(input);

    return new RegExp(input.replaceAllMapped(REFERENCE, (match) {
      var name = match[1];
      var regex = get(name);

      return regex.pattern;
    }));
  }
}

void main() {
  var pr = new PowerRegExp();

  pr.add("world", "World");
  pr.add("hello", "Hello");
  var regex = pr.build("@{hello} @{world}");
  print(regex.hasMatch("Hello World"));
}
