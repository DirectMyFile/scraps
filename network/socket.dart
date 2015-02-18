import "dart:async";
import "dart:convert";
import "dart:io";

main() async {
  var socket = await Socket.connect("google.com", 80);
  
  socket.transform(UTF8.decoder).transform(new LineSplitter()).listen(print);
  socket.writeln("GET /foo");
  new Future.delayed(new Duration(seconds: 1), () {
    return socket.close();
  });
}
