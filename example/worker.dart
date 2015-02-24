import "../utils/worker.dart";

echoWorker(Worker worker) async {
  var socket = await worker.createSocket().init();
  
  await for (var e in socket) {
    print(e);
  }
}

helloWorker(Worker worker) async {
  var socket = await worker.createSocket().init();
  
  socket.addMethod("print", (_) => print("Hello"));
}

worldWorker(Worker worker) async {
  var socket = await worker.createSocket().init();
  
  socket.addMethod("print", (_) => print("World"));
}

runPoolExample() async {
  print("== Pool Example ==");
  var pool = await createWorkerPool(20, echoWorker).init();
  
  pool.send("Hello World");
  
  await pool.stop();
  
  print("==================");
}

runMultiWorkerExample() async {
  print("== Multi-Worker Example ==");
  var hello = await createWorker(helloWorker).init();
  var world = await createWorker(worldWorker).init();
  
  await hello.callMethod("print");
  await world.callMethod("print");
  
  await hello.stop();
  await world.stop();
  
  print("==================");
}

main() async {
  await runPoolExample();
  await runMultiWorkerExample();
}
