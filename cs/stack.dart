class Stack {
  final List<dynamic> _values = [];

  void push(value) {
    _values.add(value);
  }

  pop() => _values.removeLast();

  add() => push(pop() + pop());
  subtract() => push(pop() - pop());
  multiply() => push(pop() * pop());
  divide() => push(pop() / pop());

  peek() {
    duplicate();
    return pop();
  }

  duplicate() {
    var a = pop();
    push(a);
    push(a);
  }

  flip() {
    var a = pop();
    var b = pop();
    push(a);
    push(b);
  }

  int get length => _values.length;
}

final Stack stack = new Stack();

void main() {
  stack.push(1);
  stack.push(2);
  stack.add();
  print(stack.pop());
}
