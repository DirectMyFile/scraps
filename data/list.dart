/// Tiny List Implementation
class ListEntry<T> {
  T value;
  ListEntry<T> next;

  ListEntry(this.value, [this.next]);
}

class TinyList<T> {
  ListEntry<T> _top;

  TinyList();

  void add(T value) {
    if (_top == null) {
      _top = new ListEntry<T>(value);
    } else {
      var e = _lastEntry();
      e.next = new ListEntry<T>(value);
    }
    _length++;
  }

  ListEntry<T> _lastEntry() {
    if (_top == null) return null;

    var c = _top;
    while (c.next != null) {
      c = c.next;
    }
    return c;
  }

  T operator [](int index) {
    var i = 0;
    var c = _top;
    while (i < index) {
      c = c.next;
    }
    return c;
  }

  int _length = 0;

  int get length => _length;
}

void main() {
  var l = new TinyList<String>();
  l.add("Hello World");
  print(l[0]);
}
