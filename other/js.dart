import "package:parsejs/parsejs.dart" hide Scope;

const Undefined undefined = const Undefined();

class Undefined extends JsObject {
  const Undefined();

  @override
  getProperty(String name) {
    throw new Exception("Can't get property ${name} of undefined.");
  }

  @override
  setProperty(String name, value) {
    throw new Exception("Can't set property ${name} of undefined.");
  }
}

abstract class JsObject {
  const JsObject();

  getProperty(String name);
  setProperty(String name, value);
}

class Scope {
  static final Map<String, dynamic> ROOT_VALUES = {
    "undefined": undefined,
    "NaN": double.NAN,
    "Infinity": double.INFINITY
  };

  final Scope parent;
  final Map<String, dynamic> values;

  Scope(this.parent) : values = {};
  Scope.root() : values = new Map<String, dynamic>.from(ROOT_VALUES), parent = null;

  dynamic get(String name) {
    if (values.containsKey(name)) {
      return values[name];
    } else if (parent != null) {
      return parent.get(name);
    } else {
      return undefined;
    }
  }

  Scope fork() {
    return new Scope(this);
  }
}

class EvaluatorVisitor extends RecursiveVisitor {
  Scope currentScope;
  Scope lastScope;
  Scope rootScope;

  EvaluatorVisitor(Scope scope) {
    currentScope = scope;
    rootScope = scope;
  }

  Scope switchScope(Scope scope) {
    lastScope = currentScope;
    currentScope = scope;
    return scope;
  }

  @override
  visitArray(ArrayExpression expr) {
    return expr.expressions.map((it) => visit(it)).toList();
  }

  @override
  visitFunctionNode(FunctionNode node) {
    return new VarargFunction((args) {
      var result = visitBlock(node.body, modify: (Scope scope) {
        var i = 0;
        var map = {};
        var m = node.params.map((it) => it.value).toList();
        while (i < m.length) {
          map[m[i]] = args[i];
          i++;
        }
        scope.values.addAll(map);
      });
      if (result is ReturnValue) {
        return result;
      }
      return null;
    });
  }

  @override
  visitNameExpression(NameExpression expr) {
    return currentScope.get(expr.name.value);
  }

  @override
  visitCall(CallExpression expr) {
    var value = visit(expr.callee);
    var args = expr.arguments.map((it) => visit(it)).toList();

    if (value is VarargFunction) {
      return value(args);
    } else {
      return Function.apply(value, args);
    }
  }

  @override
  visitBlock(BlockStatement block, {void modify(Scope scope)}) {
    switchScope(currentScope.fork());
    if (modify != null) {
      modify(currentScope);
    }

    for (var statement in block.body) {
      var value = visit(statement);
      if (statement is ReturnStatement) {
        switchScope(currentScope.parent);
        return value;
      }
    }

    switchScope(currentScope.parent);
  }

  @override
  visitVariableDeclarator(VariableDeclarator decl) {
    var name = decl.name.value;
    var value = decl.init != null ? visit(decl.init) : null;
    return currentScope.values[name] = value;
  }

  @override
  visitFunctionExpression(FunctionExpression expr) {
    return visit(expr.function);
  }

  @override
  visitAssignment(AssignmentExpression node) {
    var value = visit(node.right);
    if (node.left is NameExpression) {
      currentScope.values[(node.left as NameExpression).name.value] = value;
    } else {
      var left = visit((node.left as MemberExpression).object);

      var name = (node.left as MemberExpression).property.value;
      if (left is JsObject) {
        return left.setProperty(name, value);
      } else if (left is Map) {
        return left[name] = value;
      } else {
        throw new Exception("Invalid Left Hand Side");
      }
    }
  }

  @override
  visitMember(MemberExpression expr) {
    var left = visit(expr.object);

    if (left != null && left is! Undefined && left is! Map && left is! JsObject) {
      throw new Exception("Invalid Left Hand Side");
    }

    if (left is JsObject) {
      return left.getProperty(expr.property.value);
    } else {
      return left[expr.property.value];
    }
  }

  @override
  visitLiteral(LiteralExpression expr) {
    return expr.value;
  }
}

typedef dynamic VarargHandler(List args);

class VarargFunction {
  final VarargHandler handler;

  VarargFunction(this.handler);

  call(List list) => handler(list);
}

class CommonJsObjects {
  static final Map<String, dynamic> CONSOLE = {
    "log": new VarargFunction((args) {
      for (var x in args) {
        print(x);
      }
    })
  };
}

class ReturnValue {
  final dynamic value;

  ReturnValue(this.value);
}


void main() {
  var program = parsejs("""
  var hello = function () {
    console.log("Hello World");
  };

  hello();
  """);

  var scope = new Scope.root();

  scope.values["console"] = CommonJsObjects.CONSOLE;

  var evaluator = new EvaluatorVisitor(scope);
  evaluator.visit(program);
}
