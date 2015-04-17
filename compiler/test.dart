import "dart:convert";

const String input = """
{
  "hello": "world"
}
""";

void main() {
  print(JSON.decode(input));
}
