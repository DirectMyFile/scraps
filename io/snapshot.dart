import "package:fixnum/fixnum.dart";

import "dart:io";

void main() {
  var bytes = new File("/Users/alex/Dart/Hacks/hello.snapshot").readAsBytesSync();
  var header = bytes.take(16);
  var l = header.take(8).toList();
  var q = header.skip(8).toList();
  var x = new Int64.fromBytes(l);
  var y = new Int64.fromBytes(q);
  print(x);
  print(y);
}
