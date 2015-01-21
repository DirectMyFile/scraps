Future<int> ackAsync(int m, int n, {int pergo: 200}) {
  var stack = <int>[];
  var completer = new Completer<int>();
  
  Function go;
  
  go = () {
    for (var i = 1; i <= pergo; i++) {
      if (m == 0) {
        if (stack.isEmpty) {
          completer.complete(n + 1);
          return;
        } else {
          m = stack.removeLast() - 1;
          n = n + 1;
        }
      } else if (n == 0) {
        m = m - 1;
        n = 1;
      } else {
        stack.add(m);
        n = n - 1;
      }
    }
    
    new Future(go);
  };
  
  new Future(go);
  
  return completer.future;
}
