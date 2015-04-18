void sleep(Duration duration) {
  var ms = duration.inMilliseconds;
  var start = new DateTime.now().millisecondsSinceEpoch;
  while (true) {
    var current = new DateTime.now().millisecondsSinceEpoch;
    if (current - start >= ms) {
      break;
    }
  }
}

void main() {
  print("Begin.");
  sleep(new Duration(seconds: 2));
  print("End.");
}
