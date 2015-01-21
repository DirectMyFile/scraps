int ack(int m, int n) {
  var stack = <int>[];
  
  while (true) {
    if (m == 0) {
      if (stack.isEmpty) {
        return n + 1;
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
}
