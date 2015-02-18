import "dart:async";
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
    
    var path = request.uri.path;
    
    if (path == "/") {
      path = "/index.html";
    }
    
    path = path.substring(1);
    
    var file = new File(path).absolute;
    var dir = new Directory(path).absolute;
    
    if (await dir.exists() || (file.path.endsWith("/index.html") && !(await file.exists()))) {
      dir = new Directory(dir.path.replaceAll("index.html", ""));
      
      path = path.replaceAll("index.html", "/");
      
      if (path[0] != "/") {
        path = "/" + path;
      }
      
      var list = LISTING.replaceAll("{path}", path).replaceAll("{files}", (await dir.list().toList()).map((entity) {
        var m = entity.path.replaceAll(dir.path, "");
        
        if (entity is Directory) {
          m += "/";
        }
        
        var out = '<li><a href="${m}">${m}</a></li>';
        
        return out;
      }).join());
      request.response.headers.contentType = ContentType.HTML;
      request.response
        ..writeln(list)
        ..close();
      continue;
    }
    
    if (!(await file.exists())) {
      request.response
              ..statusCode = 404
              ..writeln("Not Found")
              ..close();
      continue;
    }
    
    for (var ext in MIMES.keys) {
      if (file.path.endsWith(ext)) {
        request.response.headers.contentType = ContentType.parse(MIMES[ext]);
      }
    }
    
    file.openRead().pipe(request.response).then((_) => request.response.close());
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
