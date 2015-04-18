const List<String> fish = const [
  "><>",
  "<><",
  ">><>",
  "<><<",
  "><>>",
  "<<><",
  "><<<>",
  "<>>><",
  ",<..>,"
];

String fishy(String input) {
  var chars = input.split("");
  if (chars.isEmpty || !chars.every((it) => [">", "<", ",", "."].contains(it))) {
    throw new Exception("Invalid Input");
  }
  
  var result = [];
  var i = 0;
  var buff = "";
  while (i < chars.length) {
    buff += chars[i];
    
    if (fish.contains(buff)) {
      result.add(buff);
      buff = "";
    } else if (chars.length == 6) {
      return "";
    }
    
    i++;
  }
  
  return result.join(" ");
}

void main() {
  print(fishy(",<..>,><<<>,<..>,><>,<..>,<>>><,<..>,><>>,<..>,<<><,<..>,<><,<..>,>><>"));
}