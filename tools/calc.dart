import "dart:io";

add(a, b) => a + b;
subtract(a, b) => a - b;
multiply(a, b) => a * b;
divide(a, b) => a / b;
modulo(a, b) => a % b;

const operators = const {
  "+": add,
  "-": subtract,
  "*": multiply,
  "/": divide,
  "%": modulo
};

String handleRegExp(String input) {
  return input
    .replaceAll(new RegExp(r"(\s*)\/\*(.*)\*\/(\s*)"), "")
    .split("\n")
    .map((it) => it.trimLeft())
    .join("");
}

final RegExp expression = new RegExp(handleRegExp(r"""
(\d+\.\d+|\d+|ans) /* Left Number */

(?:\s*) /* Whitespace */
(\+|\-|\*|\/|\%) /* Operator */
(?:\s*) /* Whitespace */

(\d+\.\d+|\d+|ans) /* Right Number */
"""));
final RegExp parens = new RegExp(r"\((.*)\)");

String lastAnswer = "-1";

calculate(String input) {
  if (!expression.hasMatch(input)) {
    throw "Invalid Input";
  }

  var expr = input;

  expr = expr.replaceAllMapped(parens, (match) => calculate(match[1]));

  while (expression.hasMatch(expr) && num.parse(expr, (s) => null) == null) {
    var match = expression.firstMatch(expr);
    var leftStr = match[1];
    var op = match[2];
    var rightStr = match[3];

    if (leftStr == "ans") {
      leftStr = lastAnswer;
    }

    if (rightStr == "ans") {
      rightStr = lastAnswer;
    }

    var left = num.parse(leftStr);
    var right = num.parse(rightStr);

    expr = expr.replaceAll(match[0], operators[op](left, right).toString());
  }

  return lastAnswer = expr;
}

main() {
  while (true) {
    try {
      stdout.write("> ");
      print(calculate(stdin.readLineSync()));
    } catch (e) {
      print("ERROR: ${e}");
    }
  }
}
