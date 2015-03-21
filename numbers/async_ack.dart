import "dart:async";

Future<int> ack(int m, int n) async {
  var stack = <int>[];
  var i = 0;

  while (true) {
    if (i == 5000) {
      await null;
      i = 0;
    }

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

    i++;
  }
}

main() async {
  print(await ack(4, 1));
}
