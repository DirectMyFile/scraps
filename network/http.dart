import "dart:io";
import "dart:isolate";
 
const int workers = 2;
const UNSPECIFIED = const Object();

class ServerWorker {
  final int id;
  final SendPort port;
  
  ServerWorker(this.id, this.port);
  
  ReceivePort recv;
  Stream receiver;
  
  init() async {
    recv = new ReceivePort();
    receiver = recv.asBroadcastStream();
    sleep(new Duration(milliseconds: 500));
    port.send(recv.sendPort);
  }
  
  get(String key) async {
    send(new DatabaseRequest(key));
    
    return (await receiver
        .where((it) => it is DatabaseResponse && it.isGetResponse && it.key == key)
        .first).value;
  }
  
  set(String key, value) async {
    send(new DatabaseRequest(key, value));
    
    return (await receiver
        .where((it) => it is DatabaseResponse && it.isSetResponse && it.key == key)
        .first).value;
  }
  
  void send(value) => port.send(new WorkerMessage(id, value));
}

worker(ServerWorker w) async {
  await w.init();
  
  var server = await HttpServer.bind("0.0.0.0", 8080, shared: true);
  
  await for (var request in server) {
    print("[Worker ${w.id}] ${request.method} ${request.uri.path} (${request.connectionInfo.remoteAddress.address})");
    
    if (request.uri.path == "/") {
      var number = await w.get("test");
      number++;
      await w.set("test", number);
      request.response
        ..writeln("Worker ${w.id} says hello! (${number})")
        ..close();
    } else {
      request.response
        ..statusCode = 404
        ..writeln("Not Found")
        ..close();
    }
  }
}

main() async {
  var recv = new ReceivePort();
  var receiver = recv.asBroadcastStream();
  var senders = <int, SendPort>{};
  
  for (var i = 1; i <= workers; i++) {
    var isolate = await Isolate.spawn(worker, new ServerWorker(i, recv.sendPort));
    print("[Worker ${i}] Spawned.");
    senders[i] = await receiver.first;
  }
  
  runDatabase(receiver, senders);
}

class DatabaseRequest {
  final String key;
  final dynamic value;
  
  DatabaseRequest(this.key, [this.value = UNSPECIFIED]);
  
  bool get isGetRequest => value == UNSPECIFIED;
  bool get isSetRequest => value != UNSPECIFIED;
}

class DatabaseResponse {
  final String key;
  final dynamic value;
  
  DatabaseResponse(this.key, [this.value = UNSPECIFIED]);
  
  bool get isGetResponse => value != UNSPECIFIED;
  bool get isSetResponse => value == UNSPECIFIED;
}

class WorkerMessage {
  final int id;
  final dynamic value;
  
  WorkerMessage(this.id, this.value);
}

runDatabase(ReceivePort receiver, Map<int, SendPort> senders) async {
  var storage = <String, dynamic>{
    "test": 1
  };
  
  await for (var m in receiver) {
    var port = senders[m.id];
    var message = m.value;
    
    if (message is DatabaseRequest) {
      if (message.isGetRequest) {
        port.send(new DatabaseResponse(message.key, storage[message.key])); 
      } else if (message.isSetRequest) {
        storage[message.key] = message.value;
        port.send(new DatabaseResponse(message.key));
      }
    }
  }
}