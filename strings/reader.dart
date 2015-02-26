class Section {
  final int start;
  final int end;
  
  Section(this.start, this.end);
  
  bool operator ==(other) => other.start == start && other.end == end;
  int get hashCode => start * end;
  String toString() => "Section(${start}, ${end})";
}

class CharacterReader {
  final String input;
  int _pos = -1;
  
  CharacterReader(this.input);
  
  String next() {
    _pos++;
    return current;
  }
  
  String previous() {
    _pos--;
    return current;
  }
  
  String peek([int ahead = 1]) {
    for (var i = 1; i <= ahead; i++) {
      next();
    }
    
    var c = current;
    
    for (var i = 1; i <= ahead; i++) {
      previous();
    }
    
    return c;
  }
  
  String get current {
    if (_pos < 0) {
      throw new StateError("reader position is less than zero.");
    }
    
    if (_pos == input.length) {
      throw new StateError("reader position is greater than the length of the input string.");
    }
    
    return input[_pos];
  }
  
  int get position => _pos;
  
  int _marker;
  
  void mark() {
    _marker = _pos;
  }
  
  void reset() {
    if (_marker == null) {
      throw new StateError("Marker never set.");
    }
    
    _pos = _marker;
  }
  
  void capture() {
    _captures.add(position == -1 ? 0 : position);
  }
  
  Section stopCapture() {
    if (_captures.isEmpty) {
      throw new StateError("No captures have been set.");
    }
    
    return new Section(_captures.removeLast(), position);
  }
  
  bool hasNext() => position + 1 < input.length;
  
  List<int> _captures = [];
}

void main() {
  var reader = new CharacterReader("Hello World");
  reader.capture();
  while (reader.hasNext()) {
    print(reader.next());
  }
  var section = reader.stopCapture();
  print(section);
}
