import "dart:async";
 
typedef O FutureFunction<I, O>(I value);
 
class FutureQueue {
  Future _future;
  
  FutureQueue() : _future = new Future.value();
  
  void add(FutureFunction function) {
    _future = _future.then(function);
  }
  
  Future get done => _future;
}
 
void main() {
  var queue = new FutureQueue();
  
  queue.add((_) {
    print("Hello");
  });
  
  queue.add((_) {
    print("World");
  });
  
  queue.done.then((_) {
    print("Hello World");
  });
}
