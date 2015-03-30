import "dart:collection";

typedef V DefaultCreator<K, V>(K key);

class DefaultMap<K, V> extends MapBase<K, V> {
  final Map<K, V> _map;
  final DefaultCreator<K, V> _createDefault;

  DefaultMap._(this._map, this._createDefault);

  DefaultMap(DefaultCreator<K, V> creator) : this._(<K, V>{}, creator);
  DefaultMap.wrap(Map<K, V> map, DefaultCreator<K, V> creator) : this._(map, creator);

  @override
  V operator [](K key) {
    if (!_map.containsKey(key)) {
      return _map[key] = _createDefault(key);
    } else {
      return _map[key];
    }
  }

  @override
  operator []=(K key, V value) {
    return _map[key] = value;
  }

  @override
  void clear() {
    _map.clear();
  }

  @override
  Iterable get keys => _map.keys;

  @override
  V remove(K key) {
    return _map.remove(key);
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
