import "dart:mirrors" show MirrorSystem;

/// Mimics a function so that you can provide dynamic functions.

typedef InterceptionHandler(List<dynamic> positional, Map<Symbol, dynamic> named);

class Interceptor {
  final InterceptionHandler handler;

  Interceptor(this.handler);

  @override
  noSuchMethod(inv) {
    if (!inv.isAccessor && inv.memberName == #call) {
      var positional = inv.positionalArguments;
      var named = inv.namedArguments;

      return handler(positional, named);
    } else {
      return super.noSuchMethod(inv);
    }
  }
}

dynamic map = new Interceptor((positional, named) {
  if (positional.isNotEmpty) {
    throw new ArgumentError("ERROR: Positional Arguments are not supported.");
  }

  var map = {};

  for (var key in named.keys) {
    map[MirrorSystem.getName(key)] = named[key];
  }

  return map;
});

void main() {
  print(map(a: "Hello", b: "World"));
}
