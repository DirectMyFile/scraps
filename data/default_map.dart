import "decorators.dart";

typedef V DefaultCreator<K, V>(K key);

/// A Map which can lazily create mappings on access.
class DefaultMap<K, V> extends MapDecorator<K, V> {
  final DefaultCreator<K, V> _createDefault;

  DefaultMap._(Map<K, V> map, this._createDefault) : super(map);

  DefaultMap(DefaultCreator<K, V> creator) : this._(<K, V>{}, creator);
  DefaultMap.wrap(Map<K, V> map, DefaultCreator<K, V> creator) : this._(map, creator);

  @override
  V operator [](K key) {
    if (!containsKey(key)) {
      return super[key] = _createDefault(key);
    } else {
      return super[key];
    }
  }
}

class Tree<K> extends DefaultMap<K, dynamic> {
  Tree() : super((key) => new Tree<K>());
}

void main() {
  var tree = new Tree<String>();
  tree["hello"]["world"] = [];
  print(tree);
}
