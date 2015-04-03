import "dart:math";
import "package:petitparser/petitparser.dart";

class MathGrammarDefinition extends GrammarDefinition {
  @override
  start() => ref(equation) | ref(expression);

  equation() => ref(expression) &
    whitespace().star() &
    char("=") &
    whitespace().star() &
    ref(expression);

  expression() => ref(operation) | ref(expressionItem);

  functionCall() => ref(identifier) & char("(") & ref(expressions) & char(")");

  identifier() => pattern("A-Za-z").plus().flatten();
  expressions() => ref(expression).separatedBy(
    whitespace().star() &
    char(",") &
    whitespace().star(),
    includeSeparators: false
  );

  expressionItem() => ref(parens) | ref(functionCall) | ref(number) | ref(reference);

  number() => (
    anyOf("+-").optional() &
    digit().plus() & (
      char(".") & digit().plus()
    ).optional()
  ).flatten();

  operation() => ref(expressionItem) & ref(operator) & ref(expressionItem);
  reference() => ref(identifier);
  operator() => (whitespace().star() & anyOf("+-/*%^") & whitespace().star()).pick(1);

  parens() => char("(") & ref(expression) & char(")");
}

class Equation {
  final Expression left;
  final Expression right;

  Equation(this.left, this.right);
}

class MathGrammar extends GrammarParser {
  MathGrammar() : super(new MathGrammarDefinition());
}

class MathParserDefinition extends MathGrammarDefinition {
  @override
  functionCall() => super.functionCall().map((it) {
    return new FunctionCall(it[0], it[2]);
  });

  @override
  parens() => super.parens().map((it) {
    return new Parentheses(it[1]);
  });

  @override
  number() => super.number().map((it) {
    return new Number(num.parse(it));
  });

  @override
  operation() => super.operation().map((it) {
    return new Operation(it[0], it[1], it[2]);
  });

  @override
  reference() => super.reference().map((it) {
    return new Reference(it);
  });

  @override
  equation() => super.equation().map((it) {
    return new Equation(it[0], it[3]);
  });
}

class MathParser extends GrammarParser {
  MathParser() : super(new MathParserDefinition());
}

abstract class Expression {}

class FunctionCall extends Expression {
  final String name;
  final List<Expression> args;

  FunctionCall(this.name, this.args);
}

class Number extends Expression {
  final num value;

  Number(this.value);
}

class Parentheses {
  final Expression inner;

  Parentheses(this.inner);
}

class Reference extends Expression {
  final String name;

  Reference(this.name);
}

class Operation {
  final Expression left;
  final String op;
  final Expression right;

  Operation(this.left, this.op, this.right);
}

final Map<String, Function> FUNCTIONS = {
  "sqrt": sqrt,
  "sin": sin,
  "cos": cos,
  "tan": tan,
  "acos": acos,
  "abs": (num i) => i.abs(),
  "asin": asin,
  "atan": atan,
  "atan2": atan2,
  "min": min,
  "max": max,
  "log": log,
  "expr": exp
};

class MathContext {
  Map<String, Function> functions = {
    "sqrt": sqrt,
    "sin": sin,
    "cos": cos,
    "tan": tan,
    "acos": acos,
    "abs": (num i) => i.abs(),
    "asin": asin,
    "atan": atan,
    "atan2": atan2,
    "min": min,
    "max": max,
    "log": log,
    "exp": exp
  };

  Map<String, dynamic> variables = {
    "PI": PI
  };

  dynamic eval(String input) => evaluate(new MathParser().parse(input).value);

  dynamic evaluate(input) {
    var value;

    if (input is Expression) {
      value = _evaluateExpression(input);
    } else if (input is Equation) {
      value = _evaluateEquation(input);
    } else {
      throw new Exception("Unknown Input Type");
    }

    variables["ans"] = value;
    return value;
  }

  dynamic _evaluateEquation(Equation equation) {
    if (equation.left is! Reference && equation.right is! Reference) {
      throw new Exception("Complex Equations are not yet supported.");
    }

    var id = _evaluateExpression(equation.right is Reference ? equation.right : equation.left);
    var result = _evaluateExpression(equation.left is Reference ? equation.right : equation.left);

    return id == result;
  }

  dynamic _evaluateExpression(Expression expr) {
    if (expr is Number) {
      return expr.value;
    } else if (expr is Parentheses) {
      return evaluate((expr as Parentheses).inner);
    } else if (expr is Operation) {
      var oper = expr as Operation;
      var left = evaluate(oper.left);
      var right = evaluate(oper.right);

      if (oper.op == "+") {
        return left + right;
      } else if (oper.op == "-") {
        return left - right;
      } else if (oper.op == "/") {
        return left / right;
      } else if (oper.op == "*") {
        return left * right;
      } else if (oper.op == "%") {
        return left % right;
      } else if (oper.op == "^") {
        return pow(left, right);
      } else {
        throw new Exception("Unknown Operation");
      }
    } else if (expr is FunctionCall) {
      var call = expr;

      if (FUNCTIONS.containsKey(call.name)) {
        var args = call.args.map((it) => evaluate(it)).toList();
        return Function.apply(FUNCTIONS[call.name], args);
      } else {
        throw new Exception("Unknown Function: ${call.name}");
      }
    } else if (expr is Reference) {
      if (variables.containsKey(expr.name)) {
        return variables[expr.name];
      } else {
        throw new Exception("Unknown Variable: ${expr.name}");
      }
    } else {
      throw new Exception("Unknown Expression Type");
    }
  }
}

void main() {
  var ctx = new MathContext();

  print(ctx.eval("sqrt(5) + 1"));
  print(ctx.eval("5 ^ 2"));
}
