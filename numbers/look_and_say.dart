int lookAndSay(int a) {
  var d = digits(a);

  var n = [];

  int digit = d[0];
  int count = 0;
  int x = 0;

  while (x < d.length) {
    var m = d[x];

    if (digit != null && m != digit) {
      n.add(count);
      n.add(digit);
      count = 0;
      digit = m;
    }

    count++;

    x++;
  }

  n.add(count);
  n.add(digit);

  return int.parse(n.join());
}

List<int> digits(int input) => new List<int>.generate(input.toString().length, (i) => int.parse(input.toString()[i]));
