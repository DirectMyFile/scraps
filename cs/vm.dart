const int PSH = 1;
const int ADD = 2;
const int POP = 3;
const int SET = 4;
const int HLT = 5;

const List<int> INPUT_PROGRAM = const [
  PSH,
  5,
  PSH,
  6,
  ADD,
  POP,
  HLT
];

class VM {
  final List<int> program;
  int ip = 0;
  bool running = false;

  List<int> stack = [];

  VM(this.program);

  void run() {
    running = true;
    while (running) {
      evaluate(fetch());
      ip++;
    }
  }

  void evaluate(int inst) {
    switch (inst) {
      case HLT:
        running = false;
        break;
      case PSH:
        var d = program[ip++];
        break;
    }
  }

  int fetch() => program[ip];
}
