int fib(int n) =>
    n == 0 || n == 1 ? n : fib(n - 1) + fib(n - 2);

int fibSafe(int n) {
  if (n == 0 || n == 1) return n;
 
  var prev = 1;
  var current = 1;
  for (var i = 2; i < n; i++) {
    var next = prev + current;
    prev = current;
    current = next;
  }
  return current;
}
