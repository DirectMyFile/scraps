import "dart:async";

Stream<int> range(int start, int end, {bool inclusive: true, int step: 1}) async* {
  var i = start + (inclusive ? 0 : step);

  while (inclusive ? i <= end : i < end) {
    yield i;
    i += step;
  }
}

Iterable<int> rangeSync(int start, int end, {bool inclusive: true, int step: 1}) sync* {
  var i = start + (inclusive ? 0 : step);

  while (inclusive ? i <= end : i < end) {
    yield i;
    i += step;
  }
}

main() async {
  print("= 5-10 Inclusive =");
  await for (var i in range(5, 10)) {
    print(i);
  }

  print("= 5-10 Exclusive =");
  await for (var i in range(5, 10, inclusive: false)) {
    print(i);
  }

  print("= 5-10 Inclusive with step of 2 =");
  await for (var i in range(5, 10, step: 2)) {
    print(i);
  }
}
