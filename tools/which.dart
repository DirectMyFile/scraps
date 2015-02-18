import "dart:io";
import "../script.dart";

void main(List<String> args) {
  if (args.length != 1) {
    print("usage: which <command>");
    exit(1);
  }
  
  var cmd = args[0];
  
  for (var path in executablePaths) {
    var dir = new Directory(path);
    if (!dir.existsSync()) continue;
    var executable = new File("${dir.path}/${cmd}");
    if (!executable.existsSync()) continue;
    print(executable.path);
    exit(0);
  }
  
  print("${cmd} was not found on your path.");
  exit(1);
}