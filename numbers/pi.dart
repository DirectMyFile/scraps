import "dart:async";
import "dart:io";
import "dart:isolate";
import "dart:math";
 
class PiWorker {
  final SendPort port;
  final int id;
  final List<int> numbers;
 
  PiWorker(this.id, this.port, this.numbers);
 
  void work() {
    port.send(new PiMessage(id, "start", true));
    for (var number in numbers) {
      port.send(new PiMessage(id, "result", 4 * pow(-1, number) / ((2 * number) + 1)));
    }
    port.send(new PiMessage(id, "done", true));
  }
}
 
class PiMessage {
  final String instruction;
  final dynamic value;
  final int id;
  
  PiMessage(this.id, this.instruction, this.value);
}
 
void piWorker(PiWorker worker) {
  worker.work();
}
 
double pi = 0.0;
 
int done = 0;
Map<int, int> counts = {};
int isolates = Platform.numberOfProcessors;
int per = 900000;
List<Stopwatch> watches = [];
 
Stopwatch watch = new Stopwatch();
 
void main() {
  var receiver = new ReceivePort();
  receiver.listen((PiMessage p) {
    
    if (!watch.isRunning) {
      watch.start();
    }
    
    if (p.instruction == "start") {
      watches[p.id].start();
    }
    
    if (p.instruction == "result") {
      var number = p.value;
      pi += number;
      counts[p.id] = counts[p.id] + 1;
    }
    
    if (p.instruction == "done") {
      watches[p.id].stop();
    }
  });
  
  new Timer.periodic(new Duration(milliseconds: 1), (timer) {
    var waitingFor = counts.keys.where((it) => counts[it] < per).toList();
    if (waitingFor.isEmpty) {
      watch.stop();
      print("PI: ${pi}");
      print("Total Time: ${watch.elapsedMilliseconds}ms");
      print("Average Isolate Time: ${average(watches.map((it) => it.elapsedMilliseconds).toList())}ms");
      exit(0);
    }
    
    if (watch.elapsedMilliseconds > 60000) {
      print("Timeout. 60 seconds elapsed but we aren't done.");
      print("Waiting for isolates: ${waitingFor.join(", ")}");
    }
  });
  var sender = receiver.sendPort;
  var workers = [];
 
  for (var isolateNumber in range(0, isolates - 1)) {
    workers.add(new PiWorker(isolateNumber, sender, range(isolateNumber * per, per + (per * isolateNumber))));
    watches.add(new Stopwatch());
    counts[isolateNumber] = 0;
  }
 
  for (var worker in workers) {
    Isolate.spawn(piWorker, worker);
  }
}
 
num average(List<num> numbers) {
  return numbers.reduce((a, b) => a + b) / numbers.length;
}
 
List<int> range(int start, int end) {
  var range = [];
 
  var minus = false;
 
  if (end < start) {
    minus = true;
  }
 
  for (int i = start; i <= end; minus ? i-- : i++) {
    range.add(i);
  }
  return range;
}