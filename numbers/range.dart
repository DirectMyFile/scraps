Iterable<int> range(int lower, int upper, {bool inclusive: true, int step: 1}) {
  if (step == 1) {
    if (inclusive) {
      return new Iterable<int>.generate(upper - lower + 1, (i) => lower + i);
    } else {
      return new Iterable<int>.generate(upper - lower - 1, (i) => lower + i + 1);
    }
  } else {
    var list = [];
    for (var i = inclusive ? lower : lower + step; inclusive ? i <= upper : i < upper; i += step) {
      list.add(i);
    }
    return list;
  }
}
