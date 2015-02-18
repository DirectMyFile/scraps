import "dart:async";
import "dart:convert";
import "dart:io";
 
List<Directory> _directoryStack = [];
typedef void DirectoryVisitor(FileSystemEntity entity);
typedef void Action();
typedef void SingleParameterFunction(a);
typedef void TwoParameterFunction(a, b);
 
void visitDirectory(Directory directory, DirectoryVisitor visitor) {
  directory.listSync(recursive: true).forEach(visitor);
}
 
Future<File> download(String url, String path) async {
  var file = new File(path);
  if (!(await file.exists())) await file.create();
  var stream = file.openWrite();
  var client = new HttpClient();
  var request = await client.getUrl(Uri.parse(url));
  var response = await request.close();
  await response.pipe(stream);
  client.close();
  return file;
}
 
Iterable<int> range(int lower, int upper, {bool inclusive: true, int step: 1}) {
  if (step == 1) {
    if (inclusive) {
      return new Iterable<int>.generate(upper - lower + 1, (i) => lower + i);
    } else {
      return new Iterable<int>.generate(upper - lower - 1, (i) => lower + i + 1);
    }
  } else {
    var list = [];
    for (var i = inclusive ? lower : lower + step; inclusive ? i <= upper : i < upper; i += step) {
      list.add(i);
    }
    return list;
  }
}
 
void multirun(Function func, int times) {
  for (var i in range(1, times)) {
    if (func is Action) {
      func();
    } else {
      func(i);
    }
  }
}
 
File file(String path) => new File(path);
Directory folder(String path) => new Directory(path);
 
void cd(String path) {
  Directory.current = folder(path);
}
 
void pushd(String path) {
  _directoryStack.add(Directory.current);
  cd(path);
}
 
void popd() {
  if (_directoryStack.isEmpty) {
    throw new Exception("Directory Stack Empty");
  }
  cd(_directoryStack.removeAt(_directoryStack.length - 1).path);
}
 
String stripNewlines(String input) => input.replaceAll("\n", "");
String cwd() => Directory.current.path;
String readFile(String path) => file(path).readAsStringSync();
Directory mkdir(String path, {bool recursive: false}) {
  var dir = folder(path);
  dir.createSync(recursive: recursive);
  return dir;
}
 
void rm(String path, {bool recursive: false}) =>
  recursive ? folder(path).deleteSync(recursive: true) : file(path).deleteSync();
  
FileStat fileStats(String path) {
  return file(path).statSync();
}
 
String readLine() => stdin.readLineSync();
String prompt(String msg) {
  stdout.write(msg);
  return readLine();
}
 
List<FileSystemEntity> ls(String path, {bool recursive: false}) =>
    directory(path).listSync(recursive: recursive);
 
void writeFile(String path, {bool append: false}) {
  file(path).writeAsStringSync(path, mode: append ? FileMode.APPEND : FileMode.WRITE);
}
 
String encodeJSON(dynamic input, {bool pretty: true}) {
  if (pretty) {
    return new JsonEncoder.withIndent("  ").convert(input);
  } else {
    return JSON.encode(input);
  }
}
 
dynamic decodeJSON(String input) => JSON.decode(input);
 
dynamic readJSON(String path) => decodeJSON(readFile(path));
void writeJSON(String path, dynamic json, {bool pretty: true, bool append: false}) =>
    writeFile(encodeJSON(json, pretty: pretty), append: append);