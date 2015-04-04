import "dart:io";

String generate(Map<String, String> resources) {
  var c = "const Map<String, String> resources = const {";
  if (resources.isNotEmpty) {
    c += "\n";
  }
  c += resources.keys.map((String name) {
    return '  "${name}": r"""${resources[name]}"""';
  }).join(",\n");
  if (resources.isNotEmpty) {
    c += "\n";
  }
  c += "};";
  return c;
}

String generateDirectory(String path) {
  var dir = new Directory(path);
  var map = {};
  dir.listSync(recursive: true).where((it) => it is File).map((it) {
    return [it.path.replaceAll(dir.path + Platform.pathSeparator, ""), it.readAsStringSync()];
  }).forEach((x) {
    map[x[0]] = x[1];
  });
  return generate(map);
}

void main() {
  print(generateDirectory("../numbers"));
}
