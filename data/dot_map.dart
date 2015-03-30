@MirrorsUsed(symbols: const ["*"])
import "dart:mirrors";

import "decorators.dart";

@proxy
class DotMap<K, V> extends MapDecorator<K, V> {
  DotMap() : this.wrap(<K, V>{});
  DotMap.wrap(Map<K, V> inner) : super(inner);

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.isAccessor && (invocation.isGetter || invocation.isSetter)) {
      var name = MirrorSystem.getName(invocation.memberName);

      if (invocation.isGetter) {
        return this[name];
      } else {
        return this[name.substring(0, name.length - 1)] = invocation.positionalArguments[0];
      }
    } else {
      return noSuchMethod(invocation);
    }
  }
}

void main() {
  var map = new DotMap<String, String>();

  map.name = "Hello World";
  print(map.name);
}
