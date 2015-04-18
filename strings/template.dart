RegExp splitter = new RegExp(r"\.");

dynamic getValue(dynamic data, String expr) {
  var parts = expr.split(splitter);
  var current = data;
  for (var p in parts) {
    if (p[0] == "[") { // Indexed
      var inner = p.substring(1, p.length - 1);
      var n = int.parse(inner, onError: (source) => null);
      if (n != null) {
        current = current[n];
      } else {
        current = current[inner];
      }
    } else if (p.contains("[")) { // ID with Index
      var section = p.substring(0, p.indexOf("["));
      current = current[section];
      var inner = p.substring(section.length + 1, p.length - 1);
      var n = int.parse(inner, onError: (source) => null);
      if (n != null) {
        current = current[n];
      } else {
        current = current[inner];
      }
    } else if (p == "@") { // Keys
      current = current is List ? new List<int>.generate(current.length, (i) => i) : current.keys;
    } else if (p == "!") { // Length
      current = current.length;
    } else if (p == "#") { // Last Element
      current = current.last;
    } else { // ID
      current = current[p];
    }
  }
  return current;
}

void main() {
  var data = {
    "hello": {
      "world": [
        "A",
        "B"
      ]
    }
  };
  
  var result = getValue(data, "hello.world.!");
  print(result);
}