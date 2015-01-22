String toPigLatin(String input) {
  var words = input.split(" ");
  return words.map((it) => it.trim()).map((word) {
    word = word.toLowerCase();
    if (!VOWELS.any((it) => word.contains(it))) {
      return word;
    }
    var consonant = firstConsonant(word);
    return word.replaceFirst(consonant, "") + consonant + "ay";
  }).toList().join(" ");
}

const List<String> VOWELS = const ["a", "e", "i", "o", "u"];
