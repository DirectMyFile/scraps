void main() {
  say("Hello World");
}

void say(String message) {
  print(message ?? "NULL");
  print(m?.codeUnits);
  m ??= message;
}

String m;
