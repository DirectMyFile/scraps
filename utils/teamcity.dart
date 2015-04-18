import "dart:async";
import "dart:io";
import "dart:convert";
import "dart:math";

enum MessageStatus {
  NORMAL, WARNING, FAILURE, ERROR
}

class TeamCityBlock {
  final String name;

  TeamCityBlock(this.name);

  void open() {
    TeamCity.writeServiceMessage("blockOpened", {
      "name": name
    });
  }

  void close() {
    TeamCity.closeBlock(name);
  }
}

String encodeJSON(value) => new JsonEncoder.withIndent("  ").convert(value);
dynamic decodeJSON(input) => JSON.decode(input);

String getFileContent(String path) {
  return new File(path).readAsStringSync();
}

dynamic loadJSONFile(String path) {
  return decodeJSON(getFileContent(path));
}

File getFile(String path) => new File(path);
Directory getDirectory(String path) => new Directory(path);

FileSystemEntity getFileSystemEntity(String path) {
  var type = FileSystemEntity.typeSync(path);

  if (type == FileSystemEntityType.DIRECTORY) {
    return getDirectory(path);
  } else if (type == FileSystemEntityType.FILE) {
    return getFile(path);
  } else {
    return getFile(path);
  }
}

void delete(String path) {
  getFileSystemEntity(path).deleteSync(recursive: true);
}

void rename(String from, String to) {
  getFileSystemEntity(from).renameSync(to);
}

void copy(String from, String to) {
  var ft = FileSystemEntity.typeSync(from);
  if (ft == FileSystemEntityType.DIRECTORY) {
    var dir = getDirectory(from);
    var td = new Directory(to);

    if (!td.existsSync()) {
      td.createSync(recursive: true);
    }

    var alls = dir.listSync(recursive: true).where((it) => it is File);
    for (File x in alls) {
      var p = x.path.replaceAll(dir.path + Platform.pathSeparator, "");
      var ta = new File(p);
      if (!ta.existsSync()) {
        ta.createSync(recursive: true);
      }
      x.copySync(ta.path);
    }
  } else if (ft == FileSystemEntityType.FILE) {
    var f = new File(to).parent;
    f.createSync(recursive: true);
    getFile(from).copySync(to);
  } else {
    throw new FileSystemException("Entity does not exist", from);
  }
}

void writeFile(String path, String content) {
  var file = getFile(path);
  if (!file.existsSync()) {
    file.createSync(recursive: true);
  }
  file.writeAsStringSync(content);
}

void writeJSONFile(String path, dynamic value) {
  writeFile(path, encodeJSON(value));
}

class TeamCity {
  static num _flowId = new Random().nextDouble() * (1e10 - 1e6 + 1) + 1e6;
  static bool autoFlowId = true;

  static String createServiceMessage(String name, value, {DateTime timestamp, String flowId}) {
    var out = new StringBuffer("##teamcity[${name}");

    if (value == null) {
      value = {};
    }

    if (timestamp != null) {
      if (value is Map) {
        var m = new Map.from(value);
        m["timestamp"] = timestamp.toIso8601String();
        value = m;
      } else {
        value = {
          "value": value,
          "timestamp": timestamp.toIso8601String()
        };
      }
    }

    if (flowId != null || autoFlowId) {
      if (flowId == null) {
        flowId = _flowId.toString();
      }

      if (value is Map) {
        var m = new Map.from(value);
        m["flowId"] = flowId;
        value = m;
      } else {
        value = {
          "value": value,
          "flowId": flowId
        };
      }
    }

    if (value is Map) {
      var keys = value.keys.toList();

      if (keys.isNotEmpty) {
        out.write(" ");
      }

      for (var i = 0; i < keys.length; i++) {
        out.write("${keys[i]}='${_escapeValue(value[i].toString())}'");
        if (i != keys.length - 1) {
          out.write(" ");
        }
      }
    } else {
      out.write(" '${_escapeValue(value.toString())}'");
    }
    out.write("]");

    return out.toString();
  }

  static final RegExp _replacer = new RegExp(r"'\n\r\|\[\]\u0100-\uffff]");
  static final RegExp _unicode = new RegExp(r"[^\u0000-\u00ff]");

  static final Map<String, String> _escapeMap = {
    "'": "|'",
    "|": "||",
    "\n": "|n",
    "\r": "|r",
    "[": "|[",
    "]": "|]"
  };

  static String _escapeValue(String value) {
    return value.replaceAllMapped(_replacer, (match) {
      var l = match.group(0);
      if (_escapeMap.containsKey(l)) {
        return _escapeMap[l];
      } else if (_unicode.hasMatch(l)) {
        return "|0x" + l.codeUnitAt(0).toRadixString(16).padLeft(4, "0");
      } else {
        return "";
      }
    });
  }

  static void writeServiceMessage(String name, [value]) {
    print(createServiceMessage(name, value));
  }

  static TeamCityBlock openBlock(String name) {
    writeServiceMessage("blockOpened", {
      "name": name
    });
    return new TeamCityBlock(name);
  }

  static void closeBlock(String name) {
    writeServiceMessage("blockClosed", {
      "name": name
    });
  }

  static void write(String text, {String error, MessageStatus status}) {
    var map = {
      "text": text
    };

    if (error != null) {
      map["errorDetails"] = error;
    }

    if (status != null) {
      map["status"] = status.toString().replaceAll("MessageStatus.", "");
    }

    writeServiceMessage("message", map);
  }

  static void error(String text, {String error}) {
    write(text, error: error, status: MessageStatus.ERROR);
  }

  static void warning(String text, {String error}) {
    write(text, error: error, status: MessageStatus.WARNING);
  }

  static void failure(String text, {String error}) {
    write(text, error: error, status: MessageStatus.FAILURE);
  }

  static void beginCompilation(String name) {
    writeServiceMessage("compilationStarted", {
      "compiler": name
    });
  }

  static void endCompilation(String name) {
    writeServiceMessage("compilationFinished", {
      "compiler": name
    });
  }

  static void publishArtifact(String path) {
    writeServiceMessage("publishArtifacts", path);
  }

  static void progress(String message) {
    writeServiceMessage("progressMessage", message);
  }

  static void testSuiteStarted(String name) {
    writeServiceMessage("testSuiteStarted", {
      "name": name
    });
  }

  static void testSuiteFinished(String name) {
    writeServiceMessage("testSuiteFinished", {
      "name": name
    });
  }

  static void testStarted(String name, {bool captureStandardOutput: false}) {
    writeServiceMessage("testStarted", {
      "name": name,
      "catureStandardOutput": captureStandardOutput
    });
  }

  static void testFinished(String name, {int duration}) {
    var map = {
      "name": name
    };

    if (duration != null) {
      map["duration"] = duration;
    }

    writeServiceMessage("testFinished", map);
  }

  static void testIgnored(String name, String message) {
    writeServiceMessage("testIgnored", {
      "name": name,
      "message": message
    });
  }

  static void testFailed(String name, String message, String details, {String type, String expected, String actual}) {
    var map = {
      "name": name,
      "message": message,
      "details": details
    };

    if (type != null) {
      map["type"] = type;
    }

    if (expected != null) {
      map["expected"] = expected;
    }

    if (actual != null) {
      map["actual"] = actual;
    }

    writeServiceMessage("testFailed", map);
  }

  static void testStdOut(String name, String out) {
    writeServiceMessage("testStdOut", {
      "name": name,
      "out": out
    });
  }

  static void testStdErr(String name, String out) {
    writeServiceMessage("testStdErr", {
      "name": name,
      "out": out
    });
  }

  static void progressStart(String message) {
    writeServiceMessage("progressStart", message);
  }

  static void progressFinish(String message) {
    writeServiceMessage("progressFinish", message);
  }

  static void buildProblem(String description, [String identity]) {
    var map = {
      "description": description
    };

    if (identity != null) {
      map["identity"] = identity;
    }

    writeServiceMessage("buildProblem", map);
  }

  static void setBuildStatus(String text, {String status}) {
    var map = {
      "text": text
    };

    if (status != null) {
      map["status"] = status;
    }

    writeServiceMessage("buildStatus", map);
  }

  static setBuildNumber(String number) {
    writeServiceMessage("buildNumber", number);
  }

  static void setBuildParameter(String key, String value) {
    writeServiceMessage("setParameter", {
      "name": key,
      "value": value
    });
  }

  static void disableServiceMessages() {
    writeServiceMessage("disableServiceMessages");
  }

  static void enableServiceMessages() {
    writeServiceMessage("enableServiceMessages");
  }

  static void setBuildStatistic(String key, String value) {
    writeServiceMessage("buildStatisticValue", {
      "key": key,
      "value": value
    });
  }

  static void importXmlReport(String type, String path) {
    writeServiceMessage("importData", {
      "type": type,
      "path": path
    });
  }
}

typedef void ProcessHandler(Process process);
typedef void OutputHandler(String str);

Stdin get _stdin => stdin;

class BetterProcessResult extends ProcessResult {
  final String output;

  BetterProcessResult(int pid, int exitCode, stdout, stderr, this.output) :
    super(pid, exitCode, stdout, stderr);
}

Future<BetterProcessResult> exec(
  String executable,
  {
    List<String> args: const [],
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    stdin,
    ProcessHandler handler,
    OutputHandler stdoutHandler,
    OutputHandler stderrHandler,
    OutputHandler outputHandler,
    bool inherit: false
  }) async {
  Process process = await Process.start(
    executable,
    args,
    workingDirectory: workingDirectory,
    environment: environment,
    includeParentEnvironment: includeParentEnvironment,
    runInShell: runInShell
  );

  var buff = new StringBuffer();
  var ob = new StringBuffer();
  var eb = new StringBuffer();

  process.stdout.transform(UTF8.decoder).listen((str) {
    ob.write(str);
    buff.write(str);

    if (stdoutHandler != null) {
      stdoutHandler(str);
    }

    if (outputHandler != null) {
      outputHandler(str);
    }

    if (inherit) {
      stdout.write(str);
    }
  });

  process.stderr.transform(UTF8.decoder).listen((str) {
    eb.write(str);
    buff.write(str);

    if (stderrHandler != null) {
      stderrHandler(str);
    }

    if (outputHandler != null) {
      outputHandler(str);
    }

    if (inherit) {
      stderr.write(str);
    }
  });

  if (handler != null) {
    handler(process);
  }

  if (stdin != null) {
    if (stdin is Stream) {
      stdin.listen(process.stdin.add, onDone: process.stdin.close);
    } else if (stdin is List) {
      process.stdin.add(stdin);
    } else {
      process.stdin.write(stdin);
      await process.stdin.close();
    }
  } else if (inherit) {
    _stdin.listen(process.stdin.add, onDone: process.stdin.close);
  }

  var code = await process.exitCode;
  var pid = process.pid;

  return new BetterProcessResult(
    pid,
    code,
    ob.toString(),
    eb.toString(),
    buff.toString()
  );
}
