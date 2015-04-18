import "dart:io";
import "dart:convert";

main() async {
  var index = new File("${Platform.environment["HOME"]}/.pub-cache/index.json");
  var json = JSON.decode(await index.readAsString());
  print("There are ${json['packages'].length} packages.");
}
