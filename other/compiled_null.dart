var __stack__ = [];

__push__(x) {
  __stack__.add(x);
  return x;
}

__pop__() => __stack__.removeLast();

__popm__(x) {
  __pop__();
  return x;
}

void main() {
  say("Hello World");
}

void say(String message) {
  print(__push__(message) != null ? __pop__() : __popm__("NULL"));
  __push__(m) != null ? __pop__() : __popm__(null).codeUnits;
  m = __push__(m) != null ? __pop__() : __popm__(message);
}

String m;
