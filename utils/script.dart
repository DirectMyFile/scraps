import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:math";

import "collection.dart";

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

Random _random = new Random();

int randomInteger([int max = 100]) {
  return _random.nextInt(max);
}

File file(path) => path is File ? path : new File(path);
Directory folder(path) => path is Directory ? path : new Directory(path);

void cd(String path) {
  Directory.current = folder(path);
}

void pushd(path) {
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
String readFile(path) => file(path).readAsStringSync();
Directory mkdir(path, {bool recursive: false}) {
  var dir = folder(path);
  dir.createSync(recursive: recursive);
  return dir;
}

void rm(path, {bool recursive: false}) =>
  recursive ? folder(path).deleteSync(recursive: true) : file(path).deleteSync();

FileStat fileStats(path) {
  return file(path).statSync();
}

String readLine() => stdin.readLineSync();
String prompt(String msg) {
  stdout.write(msg);
  return readLine();
}

bool yesOrNo(String msg) {
  bool ans;
  
  while (ans == null) {
    var result = prompt(msg).trim().toLowerCase();
    
    if (["yes", "true", "y", "ok", "k"].contains(result)) {
      ans = true;
    } else if (["no", "false", "n", "nope"].contains(result)) {
      ans = false;
    }
  }
  
  return ans;
}

List<FileSystemEntity> ls(path, {bool recursive: false}) =>
    folder(path).listSync(recursive: recursive);

void writeFile(path, out, {bool append: false}) {
  file(path).writeAsStringSync(out, mode: append ? FileMode.APPEND : FileMode.WRITE);
}
 
String encodeJSON(dynamic input, {bool pretty: true}) {
  if (pretty) {
    return new JsonEncoder.withIndent("  ").convert(input);
  } else {
    return JSON.encode(input);
  }
}

dynamic decodeJSON(String input) {
  var out = JSON.decode(input);
  
  if (out is Map) {
    out = new SimpleMap(out);
  } else if (out is List) {
    out = new _ListWrapper.wrap(out);
  }
  
  return out;
}

dynamic readJSON(path) => decodeJSON(readFile(path));
void writeJSON(path, dynamic json, {bool pretty: true, bool append: false}) =>
    writeFile(path, encodeJSON(json, pretty: pretty), append: append);

SimpleMap env = new SimpleMap(Platform.environment);
List<String> executablePaths = env.PATH.split(Platform.isWindows ? ";" : ":");

bool get isWindows => Platform.isWindows;
bool get isOSX => Platform.isMacOS;
bool get isLinux => Platform.isLinux;
String get hostname => Platform.hostname;
bool get isWebScript => Platform.script.scheme != "file";

Directory getSdkDir() {
  return file(Platform.executable).absolute.parent.parent;
}

Future<Socket> connect(address, int port, {bool secure: false, bool acceptInvalidCertificates: false}) async {
  var sock = await Socket.connect(address, port);
  if (secure) {
    sock = await SecureSocket.secure(sock, onBadCertificate: (x) => acceptInvalidCertificates);
  }
  return sock;
}

Future<Process> runProcess(String executable, List<String> args, {String cwd}) {
  return Process.start(executable, args, workingDirectory: cwd);
}

Future<int> execute(String executable, List<String> args, {String cwd}) async {
  var process = await runProcess(executable, args, cwd: cwd);
  inheritIO(process);
  return process.exitCode;
}

Future<int> exec(String cmd, {String cwd}) {
  var parts = cmd.split(" ");
  var executable = parts.removeAt(0);
  return execute(executable, parts, cwd: cwd);
}

void inheritIO(Process process, {String prefix, bool lineBased: true}) {
  if (lineBased) {
    process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).listen((String data) {
      if (prefix != null) {
        stdout.write(prefix);
      }
      stdout.writeln(data);
    });
    
    process.stderr.transform(UTF8.decoder).transform(new LineSplitter()).listen((String data) {
      if (prefix != null) {
        stderr.write(prefix);
      }
      stderr.writeln(data);
    });
  } else {
    process.stdout.listen((data) => stdout.add(data));
    process.stderr.listen((data) => stderr.add(data));
  }
}

@proxy
class SimpleMap extends DelegatingMap<String, dynamic> {
  final Map<String, dynamic> delegate;
  
  SimpleMap(this.delegate);

  Object get(String key, [defaultValue]) {
    if (containsKey(key)) {
      var value = this[key];
      if (value is! SimpleMap && value is Map) {
        value = new SimpleMap(value);
        this[key] = value;
      } else if (value is! _ListWrapper && value is List) {
        value = new _ListWrapper.wrap(value);
        this[key] = value;
      }
      return value;
    } else if (defaultValue != null) {
      return defaultValue;
    }
    return null;
  }

  noSuchMethod(Invocation invocation) {
    var key = MirrorSystem.getName(invocation.memberName);
    if (invocation.isGetter) {
      return get(key);
    } else if (invocation.isSetter) {
      this[key.substring(0, key.length - 1)] =
          invocation.positionalArguments.first;
    } else {
      super.noSuchMethod(invocation);
    }
  }
}

class _ListWrapper extends DelegatingList {
  final List delegate;
  
  _ListWrapper(this.delegate);

  factory _ListWrapper.wrap(List list) {
    list = list.map((e) {
      if (e is Map && e is! SimpleMap) {
        return new SimpleMap(e);
      } else if (e is List && e is! _ListWrapper) {
        return new _ListWrapper.wrap(e);
      }
      return e;
    }).toList();
    return new _ListWrapper(list);
  }
}
