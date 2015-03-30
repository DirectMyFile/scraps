/// Collections that delegate operations to another map.
import "dart:collection";

abstract class MapDecorator<K, V> extends MapBase<K, V> {
  final Map<K, V> _inner;

  MapDecorator(Map<K, V> inner) : _inner = inner;

  @override
  V operator [](Object key) {
    return _inner[key];
  }

  @override
  operator []=(K key, V value) {
    return _inner[key] = value;
  }

  @override
  void clear() {
    _inner.clear();
  }

  @override
  Iterable<K> get keys => _inner.keys;

  @override
  V remove(Object key) {
    return _inner.remove(key);
  }
}
