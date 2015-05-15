library dcbot.markov;

import "dart:io";
import "dart:math" as Math;
import "dart:collection";

class MarkovChain {
  Math.Random random = new Math.Random();

  HashMap<String, List<int>> wordTriplesNext = new HashMap<String, List<int>>();
  HashMap<String, List<int>> wordTriplesPrevious = new HashMap<String, List<int>>();

  Map<String, List<int>> wordPairsNext = new Map<String, List<int>>();
  Map<String, List<int>> wordPairsPrevious = new Map<String, List<int>>();

  Map<String, List<int>> wordsNext = new Map<String, List<int>>();
  Map<String, List<int>> wordsPrevious = new Map<String, List<int>>();
  Set<String> globalLines = new Set<String>();

  IntMap<String, Word> words = new IntMap<String, Word>();

  void addLine(String line) {
    {
      var lines = splitMultiple(line, [". ", "\n"]);
      for (var currentLine in lines) {
        if (!globalLines.contains(currentLine)) {
          globalLines.add(currentLine);
        } else {
          continue;
        }
        var currentWords = currentLine.split(" ");
        currentWords.add("");
        var previousWord = "";
        String previousWord2 = "";
        List<int> wordList = null;
        String currentWord;
        String nextWord;
        String nextWord2;
        String pair;
        String triple;

        for (int i = 0; i < currentWords.length - 1; i++) {
          currentWord = _selectivelyLowercase(currentWords[i]);
          nextWord = _selectivelyLowercase(currentWords[i + 1]);
          nextWord2 = i < currentWords.length - 2 ? _selectivelyLowercase(currentWords[i + 2]) : "";
          pair = previousWord + " " + currentWord;
          triple = previousWord2 + " " + pair;
          int wordIndex = words.lookup(nextWord);
          if (wordIndex == null) {
            wordIndex = words.add(new Word(nextWord), nextWord);
          } else {
            words.get(wordIndex).increment();
          }

          wordList = wordTriplesNext[triple];

          if (wordList == null) {
            wordList = new List<int>();
          }
          wordList.add(wordIndex);
          wordTriplesNext[triple] = wordList;

          wordList = wordPairsNext[pair];
          if (wordList == null) {
            wordList = new List<int>();
          }

          wordList.add(wordIndex);
          wordPairsNext[pair] = wordList;

          wordList = wordsNext[currentWord];
          if (wordList == null) wordList = [];
          wordList.add(wordIndex);
          wordsNext[currentWord] = wordList;
          wordIndex = words.lookup(previousWord);
          if (wordIndex == null) wordIndex = words.add(new Word(previousWord), previousWord);
          pair = currentWord + " " + nextWord;

          triple = pair + " " + nextWord2;
          wordList = wordTriplesPrevious[triple];
          if (wordList == null) {
            wordList = new List<int>();
          }
          wordList.add(wordIndex);
          wordTriplesPrevious[triple] = wordList;
          wordList = wordPairsPrevious[pair];
          if (wordList == null) {
            wordList = [];
          }
          wordList.add(wordIndex);
          wordPairsPrevious[pair] = wordList;

          wordList = wordsPrevious[currentWord];
          if (wordList == null) wordList = [];
          wordList.add(wordIndex);
          wordsPrevious[currentWord] = wordList;
          previousWord2 = previousWord;
          previousWord = currentWord;
        }
      }
    }
  }

  String reply(String inputString, [String name = "", String sender = ""]) {
    List<String> currentLines;
    List<String> currentWords = [];
    Queue<String> sentence = new Queue();

    String allSentences = "";
    String replyString = "";

    if (inputString.isEmpty) {
      return "";
    }

    currentLines = inputString.split(". ");
    currentWords.addAll(currentLines[currentLines.length - 1].split(" "));

    if (currentLines.length > 0) {
      for (int i = 0; i < currentLines.length - 1; i++) {
        allSentences += reply(currentLines[i]) + ". ";
      }
    }

    for (int i = 0; i < currentWords.length; i++) {
      currentWords[i] = _selectivelyLowercase(currentWords[i]);
    }

    if (currentWords.isEmpty) {
      return "";
    }

    String previousWord = "";
    String bestWord = currentWords[0];
    String bestWordPair = " " + currentWords[0];

    if (currentWords.length > 1) {
      bestWord = currentWords[random.nextInt(currentWords.length - 1)];
      int pairStart = random.nextInt(currentWords.length - 1);
      bestWordPair = (pairStart == 0 ? "" : currentWords[pairStart - 1]) + " " + currentWords[pairStart];
    }

    for (int i = 0; i < currentWords.length; i++) {
      var currentWord = currentWords[i];
      var pairKey = previousWord + " " + currentWord;
      int bestSize = (wordPairsNext[bestWordPair] != null ? wordPairsNext[bestWordPair].length : 0) + (wordPairsPrevious[bestWordPair] != null ? wordPairsPrevious.length : 0);

      if (bestSize == 0) bestWordPair = pairKey;

      bestSize = (wordsNext[bestWord] != null ? wordsNext[bestWord].length : 0) + (wordsPrevious[bestWord] != null ? wordsPrevious.length : 0);

      if (bestSize == 0) bestWord = currentWord;

      previousWord = currentWord;
    }

    List<int> bestList;
    if ((bestList = wordPairsNext[bestWordPair]) != null && bestList.length > 0 && random.nextDouble() > .05) {
      if (bestWordPair[0] != " ") {
        previousWord = _splitFirst(bestWordPair, " ")[1];
        sentence.addAll(bestWordPair.split(" "));
      } else {
        sentence.add(bestWordPair.substring(1));
        previousWord = "";
      }
    } else {
      bestList = wordsNext[bestWord];
      if (bestList != null) {
        sentence.add(bestWord);
      }
    }

    if (sentence.isEmpty) {
      sentence.add(currentWords[0]);
    }

    var nextWord = sentence.length > 1 ? sentence.last : "";
    String nextWord2 = "";

    var wordPairsTemp = <String, List<int>>{};
    var wordsTemp = <String, List<int>>{};

    for (int size = sentence.length - 1; size < sentence.length; ) {
      size = sentence.length;
      var currentWord = sentence.first;
      var key = currentWord + " " + nextWord;
      var list = wordPairsTemp[key];

      if (list == null) {
        if (wordPairsPrevious[key] != null) {
          wordPairsTemp[key] = new List.from(wordPairsPrevious[key]);
        }
        list = wordPairsTemp[key];
      }

      if (list != null && list.length > 0) {
        String triple = key + " " + nextWord2;
        String word;

        if (wordTriplesPrevious[triple] != null && wordTriplesPrevious[triple].length > 0 && (random.nextInt(50) > 4 / list.length)) {
          list = wordTriplesPrevious[triple];
          int index = random.nextInt(list.length);
          word = words.get(list[index]).toString();
        } else {
          int index = random.nextInt(list.length);
          word = words.get(list[index]).toString();
          list.remove(index);
        }

        if (word.isNotEmpty) {
          sentence.addFirst(word);
        }
      } else {
        key = currentWord;
        list = wordsTemp[key];
        if (sentence.length / currentWords.length > random.nextDouble() && list == null) {
          if (wordsPrevious[key] != null) {
            wordsTemp[key] = new List.from(wordsPrevious[key]);
          }
          list = wordsTemp[key];
        }

        if (list != null && list.length > 0) {
          var index = random.nextInt(list.length);
          var word = words.get(list[index]).toString();
          list.remove(index);
          if (word.isNotEmpty) {
            sentence.addFirst(word);
          }
        }
      }
      nextWord2 = nextWord;
      nextWord = currentWord;

    }

    String previousWord2 = "";
    if (sentence.length > 1) {
      previousWord = sentence.toList()[sentence.length - 2];
      if (sentence.length > 2) {
        previousWord2 = sentence.toList()[sentence.length - 3];
      }
    }

    wordPairsTemp = <String, List<int>>{};
    wordsTemp = <String, List<int>>{};

    for (int size = sentence.length - 1; size < sentence.length; ) {
      size = sentence.length;
      var currentWord = sentence.last;
      var key = previousWord + " " + currentWord;
      var list = wordPairsTemp[key];

      if (list == null) {
        if (wordPairsNext[key] != null) {
          wordPairsTemp[key] = [wordPairsNext[key]];
        }

        list = wordPairsTemp[key];
      }

      if (list != null && list.length > 0) {
        String triple = previousWord2 + " " + key;
        String word;
        if (wordTriplesNext[triple] != null && wordTriplesNext[triple].length > 0 && (random.nextDouble() > 4 / list.length)) {
          list = wordTriplesNext[triple];
          int index = random.nextInt(list.length);
          word = words.get(list[index]).toString();
        } else {
          int index = random.nextInt(list.length);
          word = words.get(list.length).toString();
          list.removeAt(index);
        }
        if (word.isNotEmpty) {
          sentence.add(word);
        }
      } else {
        key = currentWord;
        list = wordsTemp[key];
        if (list == null) {
          if (wordsNext[key] != null) {
            wordsTemp[key] = new List.from(wordsNext[key]);
          }
          list = wordsTemp[key];
        }

        if (list != null && list.length > 0) {
          var index = random.nextInt(list.length);
          var word = words.get(list[index]).toString();

          list.removeAt(index);

          if (word.isNotEmpty) {
            sentence.add(word);
          }
        }
      }
      previousWord2 = previousWord;
      previousWord = currentWord;
    }

    while (replyString.isEmpty) {
      replyString = sentence.isEmpty ? null : sentence.removeFirst();
    }

    if (replyString.isNotEmpty) {
      replyString = replyString.substring(0, 1).toUpperCase() + replyString.substring(1);
    }

    if (replyString.toLowerCase() == name.toLowerCase() && sender.isNotEmpty) {
      replyString = sender;
    }

    for (String replyWord in sentence) {
      if (replyWord.isNotEmpty) {
        replyString += " " + replyWord;
      }
    }

    return allSentences + replyString;
  }

  String randomSentence() {
    String firstWord;
    List<int> list;
    do {
      firstWord = words.get(random.nextInt(words.size)).toString();
      list = wordsNext[firstWord];
    } while (list == null);
    String secondWord = words.get(list[random.nextInt(list.length)]).toString();
    return reply(firstWord + " " + secondWord);
  }

  List<String> _splitFirst(String string, String splitter) {
    int splitIndex = string.indexOf(splitter);
    if (splitIndex != -1) {
      return [string.substring(0, splitIndex), string.substring(splitIndex + 1)];
    } else {
      return [string, ""];
    }
  }

  String _selectivelyLowercase(String it) {
    var lowered = it.toLowerCase();
    if (lowered.startsWith("http:") || lowered.startsWith("https:")) {
      return it;
    } else {
      return lowered;
    }
  }

  void load() {
    var stopwatch = new Stopwatch();
    stopwatch.start();
    File file = new File("lines.txt");
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    file.readAsLinesSync().forEach((line) {
      addLine(line);
    });
    stopwatch.stop();
    print("Loaded Lines in ${stopwatch.elapsedMicroseconds} milliseconds");
  }

  void save() {
    var file = new File("lines.txt");
    var stopwatch = new Stopwatch();
    stopwatch.start();

    file.writeAsStringSync(globalLines.join("\n"));

    stopwatch.stop();
    print("Saved Lines in ${stopwatch.elapsedMicroseconds} milliseconds");
  }

  List<String> splitMultiple(String input, List<String> by) {
    List<String> strings = [];
    List<String> oldStrings = [];
    oldStrings.add(input);

    for (String sep in by) {
      strings = [];
      for (String current in oldStrings) strings.addAll(current.split(sep));
      oldStrings = strings;
    }

    return strings;
  }

  String generateStatistics() {
    return "Word triples next: " + wordTriplesNext.length.toString() + ", Word pairs next: " + wordPairsNext.length.toString() + ", words next: " + wordsNext.length.toString() + ", word triples previous: " + wordTriplesPrevious.length.toString() + ", word pairs previous: " + wordPairsPrevious.length.toString() + ", words previous: " + wordsPrevious.length.toString() + ", words: " + words.size.toString() + ", lines: " + globalLines.length.toString();
  }

  String generateWordStats(List<String> parts) {
    if (parts.isEmpty) {
      return "usage: wordstats <string>";
    }

    String wordString = _selectivelyLowercase(parts.join(" "));
    if (parts.length > 1) {
      String argumentString = parts.join(" ");
      int wordNum = argumentString.length - argumentString.replaceAll(" ", "").length;
      if (words.lookup(wordString) != null) {
        Word word = words.get(words.lookup(wordString));
        int empty = words.lookup("");
        String nextWordString = "";
        int nextWordCount = 0;
        String previousWordString = "";
        int previousWordCount = 0;
        List<List<int>> nextWords = new List<List<int>>();
        List<List<int>> previousWords = new List<List<int>>();
        Map<String, List<int>> next = wordNum == 0 ? wordsNext : wordNum == 1 ? wordPairsNext : wordTriplesNext;
        Map<String, List<int>> previous = wordNum == 0 ? wordsPrevious : wordNum == 1 ? wordPairsPrevious : wordTriplesPrevious;
        if ((next[argumentString.toLowerCase()]) != null) for (int index in next[argumentString.toLowerCase()]) {
          if (index == empty) continue;
          bool notFound = true;
          for (int i = 0; i < nextWords.length; i++) if (nextWords[i][0] == index) {
            nextWords[i][1]++;
            if (nextWords[i][1] > nextWordCount) {
              nextWordCount = nextWords[i][1];
              nextWordString = words.get(nextWords[i][0]).toString();
            }
            notFound = false;
            break;
          }
          if (notFound) nextWords.add([index, 1]);
        }

        if (previous[argumentString.toLowerCase()] != null) for (int index in previous[argumentString.toLowerCase()]) {
          if (index == empty) continue;
          bool notFound = true;
          for (int i = 0; i < previousWords.length; i++) if (previousWords[i][0] == index) {
            previousWords[i][1]++;
            if (previousWords[i][1] > previousWordCount) {
              previousWordCount = previousWords[i][1];
              previousWordString = words.get(previousWords[i][0]).toString();
            }
            notFound = false;
            break;
          }
          if (notFound) previousWords.add([index, 1]);
        }

        if (next[argumentString.toLowerCase()] == null) return argumentString + " is not known";
        return "\"" + argumentString.toLowerCase() + "\" has a count of " + (parts.length == 2 ? "" + word.count.toString() + ", an index of " + words.lookup(wordString).toString() : next[argumentString.toLowerCase()].length) + ", with a most common next word of \"" + nextWordString + "\" (" + nextWordCount.toString() + " times) and a most common previous word of \"" + previousWordString + "\" (" + previousWordCount.toString() + ")";
      } else {
        return wordString + " is not known";
      }
    } else {
      return wordString + " is not known";
    }
  }
}

class IntMap<L, S> {
  List<S> list = <S>[];
  Map<L, int> map = new Map<L, int>();

  S get(int index) {
    if (index == null) return null;
    return list[index];
  }

  int lookup(L key) {
    return map[key];
  }

  int add(S value, L key) {
    if (map[value] != null) return map[value];
    list.add(value);
    map[key] = list.length - 1;
    return list.length - 1;
  }

  int get size => list.length;
}

class Word {
  String string;
  int count = 1;

  Word(this.string);


  int increment() => count += 1;

  @override
  String toString() => string;
}

void main() {
  var chain = new MarkovChain();
  chain.load();

  void test(String line) {
    var reply = chain.reply(line, "Alex", "DirectCodeBot");
    print("${line} => ${reply}");
  }

  test("i have");
  test("died");
  test("go");
  test("make");
}
