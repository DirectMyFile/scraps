import "dart:async";
import "dart:convert";
import "dart:io";
import "dart:isolate";

const int workers = 3;
const UNSPECIFIED = const Object();
const String LISTING = """
<!DOCTYPE html>
<html>
  <title>Directory listing for {path}</title>
  <body>
    <h2>Directory listing for {path}</h2>
    <hr>
      <ul>{files}</ul>
    <hr>
  </body>
</html>
""";

const Map<String, String> MIMES = const {
  ".html": "text/html",
  ".txt": "text/plain",
  ".css": "text/css",
  ".js": "application/js",
  ".dart": "application/dart",
  ".json": "application/json",
  ".xml": "text/xml"
};

class ServerWorker {
  final int id;
  final SendPort port;

  ServerWorker(this.id, this.port);

  ReceivePort recv;
  Stream receiver;

  init() async {
    recv = new ReceivePort();
    receiver = recv.asBroadcastStream();
    sleep(new Duration(milliseconds: 2));
    port.send(recv.sendPort);
  }

  void send(value) => port.send(new WorkerMessage(id, value));
}

class WorkerMessage {
  final int id;
  final dynamic value;

  WorkerMessage(this.id, this.value);
}

runWorker(ServerWorker worker) async {
  await worker.init();

  var server = await HttpServer.bind("0.0.0.0", 8080, shared: true);

  await for (var request in server) {
    print("[Worker ${worker.id}] ${request.method} ${request.uri.path} (${request.connectionInfo.remoteAddress.address})");
    
    await serveFile(request, request.response);
  }
}

main() async {
  var recv = new ReceivePort();
  var receiver = recv.asBroadcastStream();
  var senders = <int, SendPort>{};

  for (var i = 1; i <= workers; i++) {
    await Isolate.spawn(runWorker, new ServerWorker(i, recv.sendPort));
    print("[Worker ${i}] Spawned.");
    senders[i] = await receiver.first;
  }
}

serveFile(HttpRequest request, HttpResponse response) async {
  var path = request.uri.path;

  var mpath = path == "/" ? "." : path.substring(1);
  var type = await FileSystemEntity.type(mpath);
  
  if (type == FileSystemEntityType.FILE) {
    var file = new File(mpath);
    
    for (var ext in MIMES.keys) {
      if (file.path.endsWith(ext)) {
        response.headers.contentType = ContentType.parse(MIMES[ext]);
      }
    }

    await file.openRead().pipe(response);
    await response.close();
  } else if (type == FileSystemEntityType.DIRECTORY) {
    var query = request.uri.queryParameters;
    var format = query.containsKey("format") ? query["format"].toLowerCase() : "html";
    
    if (format == "html") {
      var list = await generateDirectoryList(request.uri.path);

      response
        ..headers.contentType = ContentType.HTML
        ..writeln(list)
        ..close();
    } else if (format == "json") {
      var list = await generateDirectoryListJSON(request.uri.path);

      response
        ..headers.contentType = ContentType.JSON
        ..writeln(list)
        ..close();
    } else {
      response
        ..statusCode = 400
        ..writeln("Invalid Response Format: ${format}")
        ..close();
    }
  } else if (type == FileSystemEntityType.NOT_FOUND) {
    response
      ..statusCode = 404
      ..writeln("Not Found")
      ..close();
  } else {
    response
      ..statusCode = 500
      ..writeln("Unknown File System Entity Type")
      ..close();
  }
}

Future<String> generateDirectoryList(String path) async {
  var relative = path.substring(1);
  var dir = new Directory(relative).absolute;
  
  var children = dir.list();
  var buff = new StringBuffer();
  var out = LISTING;
  
  void addEntry(String entryPath) {
    buff.writeln('<li><a href="${entryPath}">${entryPath}</a></li>');
  }
  
  if (path != "/") {
    addEntry("../");
  }
  
  await for (var child in children) {
    var p = child.path.replaceAll(dir.path, "");
    
    if (child is Directory) {
      p += "/";
    }
    
    addEntry(p);
  }
  
  return out.replaceAll("{path}", path).replaceAll("{files}", buff.toString());
}

JsonEncoder jsonEncoder = new JsonEncoder.withIndent("  ");

Future<String> generateDirectoryListJSON(String path) async {
  var relative = path.substring(1);
  var dir = new Directory(relative).absolute;
  var children = await dir.list().asyncMap((it) async {
    var stat = await it.stat();
    
    return {
      "name": it.path.replaceAll(dir.path, ""),
      "type": it is Directory ? "directory" : "file",
      "size": stat.size,
      "modified": stat.modified.millisecondsSinceEpoch
    };
  }).toList();
  return jsonEncoder.convert(children);
}