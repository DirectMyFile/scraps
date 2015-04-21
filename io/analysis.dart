import "dart:async";
import "dart:convert";
import "dart:io";
import "package:path/path.dart" as pathlib;

abstract class AnalysisChannel {
  Future initialize();
  void send(Map<String, dynamic> json);
  Stream<Map<String, dynamic>> stream();
}

class AnalysisClientError {
  final String code;
  final String message;
  final String stacktrace;

  AnalysisClientError(this.code, this.message, this.stacktrace);

  @override
  String toString() {
    var msg = "${message}\nError Code: ${code}";
    if (stacktrace != null) {
      msg += "\n\nServer Stack Trace:\n${stacktrace}";
    }

    return msg;
  }
}

Future<String> getExecutablePath() async {
  var name = Platform.executable;
  if (pathlib.isAbsolute(name)) {
    return name;
  }

  var paths = Platform.environment["PATH"].split(Platform.isWindows ? ";" : ":");

  for (var path in paths) {
    var pexe = new File("${path}/dart");
    var exe = new File("${path}/dart.exe");
    if (await pexe.exists()) {
      return pexe.resolveSymbolicLinksSync();
    } else if (await exe.exists()) {
      return exe.resolveSymbolicLinksSync();
    }
  }

  return null;
}

class ProcessAnalysisChannel extends AnalysisChannel {
  Process _process;

  @override
  Future initialize() async {
    var exePath = await getExecutablePath();
    if (exePath == null) {
      throw new Exception("Unable to find Dart SDK.");
    }
    var binDir = new File(exePath).parent;
    var snapshot = new File(pathlib.join(binDir.path, "snapshots", "analysis_server.dart.snapshot"));
    if (!(await snapshot.exists())) {
      throw new Exception("Analysis Server Snapshot not found! ${snapshot.path}");
    }
    _process = await Process.start(Platform.executable, [snapshot.path]);
  }

  @override
  void send(Map<String, dynamic> json) {
    _process.stdin.writeln(JSON.encode(json));
  }

  @override
  Stream<Map<String, dynamic>> stream() {
    return _process.stdout.transform(UTF8.decoder).transform(new LineSplitter()).map((it) => JSON.decode(it));
  }
}

class AnalysisClient {
  final AnalysisChannel channel;

  AnalysisClient(this.channel);

  Future initialize() async {
    await channel.initialize();
    channel.stream().listen((json) {
      if (json.containsKey("error")) {
        var code = json["error"]["code"];
        var message = json["error"]["message"];
        var stacktrace = json["error"]["stackTrace"];

        throw new AnalysisClientError(code, message, stacktrace);
      }

      if (json.containsKey("id")) {
        var rid = int.parse(json["id"]);
        if (_pending.containsKey(rid)) {
          _pending[rid].complete(json["result"]);
        }
      } else if (json.containsKey("event")) {
        if (_events.containsKey(json["event"])) {
          _events[json["event"]].add(json["params"]);
        }
      }
    });

    return await onEvent("server.connected").first;
  }

  Stream<Map<String, dynamic>> onEvent(String name) {
    if (_events.containsKey(name)) {
      return _events[name].stream;
    } else {
      return (_events[name] = new StreamController.broadcast()).stream;
    }
  }

  Stream<AnalysisErrorsNotification> get onAnalysisErrors => onEvent("analysis.errors")
    .map((it) => new AnalysisErrorsNotification.fromJSON(it));

  Stream<AnalysisStatus> get onServerStatus => onEvent("server.status")
    .map((it) => new ServerStatus.fromJSON(it));

  Map<String, StreamController> _events = {};

  Future<AnalysisResponse> send(AnalysisRequest request) async {
    var completer = new Completer();
    var rid = _getRequestId();
    _pending[rid] = completer;
    var json = request.toJSON();
    json["id"] = rid.toString();
    channel.send(json);
    var m = await completer.future;
    return request.getResponse(m);
  }

  Future setAnalysisRoots({List<String> included: const [], List<String> excluded: const [], Map<String, String> packageRoots}) {
    return send(new SetAnalysisRootsRequest(included, excluded, packageRoots));
  }

  Future setServerSubscriptions(List<String> subs) {
    return send(new SetServerSubscriptionsRequest(subs));
  }

  Future shutdown() {
    return send(new ServerShutdownRequest());
  }

  Future setPriorityFiles(List<String> files) => send(new SetPriorityFilesRequest(files));

  Future<String> getServerVersion() async {
    return (await send(new ServerVersionRequest()) as ServerVersionResponse).version;
  }

  Future<List<AnalysisError>> getAnalysisErrors(String file) async {
    GetErrorsResponse response = await send(new GetErrorsRequest(file));
    return response.errors;
  }

  Future<Stream<CompletionResults>> getCompletionSuggestions(String file, int offset) async {
    var id = (await send(new GetCompletionSuggestionsRequest(file, offset)) as GetCompletionSuggestionsResponse).id;
    var controller = new StreamController<CompletionResults>.broadcast();
    var sub;
    sub = onEvent("completion.results").where((it) => it["id"] == id).map((it) => new CompletionResults.fromJSON(it)).listen((x) {
      controller.add(x);

      if (x.isLast) {
        controller.close();
        sub.cancel();
      }
    });
    return controller.stream;
  }

  int _rid = 0;
  int _getRequestId() => ++_rid;
  Map<int, Completer> _pending = {};
}

class AnalysisStatus {
  final bool isAnalyzing;
  final String analysisTarget;

  AnalysisStatus(this.isAnalyzing, this.analysisTarget);

  factory AnalysisStatus.fromJSON(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    return new AnalysisStatus(json["isAnalyzing"], json["analysisTarget"]);
  }
}

class PubStatus {
  final bool isListingPackageDirs;

  PubStatus(this.isListingPackageDirs);

  factory PubStatus.fromJSON(Map<String, dynamic> json) {
    if (json == null) {
      return null;
    }
    return new PubStatus(json["isListingPackageDirs"]);
  }
}

class ServerStatus {
  final PubStatus pub;
  final AnalysisStatus analysis;

  ServerStatus(this.pub, this.analysis);

  factory ServerStatus.fromJSON(Map<String, dynamic> json) {
    return new ServerStatus(new PubStatus.fromJSON(json["pub"]), new AnalysisStatus.fromJSON(json["analysis"]));
  }
}

class SetServerSubscriptionsRequest extends AnalysisRequest {
  final List<String> subscriptions;

  SetServerSubscriptionsRequest(this.subscriptions);

  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) =>
    new EmptyResponse();

  @override
  Map<String, dynamic> toJSON() => {
    "method": "server.setSubscriptions",
    "params": {
      "subscriptions": subscriptions
    }
  };
}

class GetCompletionSuggestionsResponse extends AnalysisResponse {
  final String id;

  GetCompletionSuggestionsResponse(this.id);
}

class GetCompletionSuggestionsRequest extends AnalysisRequest {
  final String file;
  final int offset;

  GetCompletionSuggestionsRequest(this.file, this.offset);

  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) =>
    new GetCompletionSuggestionsResponse(result["id"]);

  @override
  Map<String, dynamic> toJSON() => {
    "method": "completion.getSuggestions",
    "params": {
      "file": file,
      "offset": offset
    }
  };
}

class CompletionSuggestionKind {
  static const CompletionSuggestionKind ARGUMENT_LIST = const CompletionSuggestionKind("ARGUMENT_LIST");
  static const CompletionSuggestionKind IMPORT = const CompletionSuggestionKind("IMPORT");
  static const CompletionSuggestionKind IDENTIFIER = const CompletionSuggestionKind("IDENTIFIER");
  static const CompletionSuggestionKind INVOCATION = const CompletionSuggestionKind("INVOCATION");
  static const CompletionSuggestionKind KEYWORD = const CompletionSuggestionKind("KEYWORD");
  static const CompletionSuggestionKind NAMED_ARGUMENT = const CompletionSuggestionKind("NAMED_ARGUMENT");
  static const CompletionSuggestionKind OPTIONAL_ARGUMENT = const CompletionSuggestionKind("OPTIONAL_ARGUMENT");
  static const CompletionSuggestionKind PARAMETER = const CompletionSuggestionKind("PARAMETER");

  final String name;

  const CompletionSuggestionKind(this.name);

  static const List<CompletionSuggestionKind> values = const [
    ARGUMENT_LIST,
    IMPORT,
    IDENTIFIER,
    INVOCATION,
    KEYWORD,
    NAMED_ARGUMENT,
    OPTIONAL_ARGUMENT,
    PARAMETER
  ];

  static CompletionSuggestionKind forName(String name) => values.firstWhere((it) => it.name == name);
}

class CompletionResults {
  final String id;
  final int replacementOffset;
  final int replacementLength;
  final List<CompletionSuggestion> results;
  final bool isLast;

  CompletionResults(this.id, this.replacementOffset, this.replacementLength, this.results, this.isLast);

  factory CompletionResults.fromJSON(Map<String, dynamic> json) {
    var i = json["id"];
    var ro = json["replacementOffset"];
    var rl = json["replacementLength"];
    var res = json["results"].map((it) => new CompletionSuggestion.fromJSON(it)).toList();
    var l = json["isLast"];

    return new CompletionResults(i, ro, rl, res, l);
  }
}

class ServerService {
  static const String STATUS = "STATUS";
}

class SourceEdit {
  final int offset;
  final int length;
  final String replacement;
  final String id;

  SourceEdit(this.offset, this.length, this.replacement, this.id);

  factory SourceEdit.fromJSON(Map<String, dynamic> json) {
    return new SourceEdit(json["offset"], json["length"], json["replacement"], json["id"]);
  }

  String apply(String input) {
    var a = input.substring(0, offset);
    var b = input.substring(offset + length);
    return a + replacement + b;
  }
}

class SourceFileEdit {
  final String file;
  final int fileStamp;
  final List<SourceEdit> edits;

  SourceFileEdit(this.file, this.fileStamp, this.edits);

  factory SourceFileEdit.fromJSON(Map<String, dynamic> json) {
    return new SourceFileEdit(json["file"], json["fileStamp"], json["edits"]
      .map((it) => new SourceEdit.fromJSON(it)).toList()
    );
  }

  String apply(String content) {
    for (var edit in edits) {
      content = edit.apply(content);
    }

    return content;
  }
}

class CompletionSuggestion {
  final String id;
  final CompletionSuggestionKind kind;
  final int relevance;
  final String completion;
  final int selectionOffset;
  final int selectionLength;
  final bool isDeprecated;
  final bool isPotential;
  final String docSummary;
  final String docComplete;
  final String declaringType;
  final String returnType;
  final List<String> parameterNames;
  final List<String> parameterTypes;
  final int requiredParameterCount;
  final bool hasNamedParameters;
  final String parameterName;
  final String parameterType;

  CompletionSuggestion(
    this.id,
    this.kind,
    this.relevance,
    this.completion,
    this.selectionOffset,
    this.selectionLength,
    this.isDeprecated,
    this.isPotential,
    this.docSummary,
    this.docComplete,
    this.declaringType,
    this.returnType,
    this.parameterNames,
    this.parameterTypes,
    this.requiredParameterCount,
    this.hasNamedParameters,
    this.parameterName,
    this.parameterType);

  factory CompletionSuggestion.fromJSON(Map<String, dynamic> json) {
    var i = json["id"];
    var kind = CompletionSuggestionKind.forName(json["kind"]);
    var rel = json["relevance"];
    var com = json["completion"];
    var so = json["selectionOffset"];
    var sl = json["selectionLength"];
    var isDep = json["isDeprecated"];
    var po = json["isPotential"];
    var ds = json["docSummary"];
    var dc = json["docComplete"];
    var dt = json["declaringType"];
    var rt = json["returnType"];
    var pns = json["parameterNames"];
    var pts = json["parameterTypes"];
    var rpc = json["requiredParameterCount"];
    var hnp = json["hasNamedParameters"];
    var pn = json["parameterName"];
    var pt = json["parameterType"];
    return new CompletionSuggestion(i, kind, rel, com, so, sl, isDep, po, ds, dc, dt, rt, pns, pts, rpc, hnp, pn, pt);
  }
}

class AnalysisErrorsNotification {
  final String file;
  final List<AnalysisError> errors;

  AnalysisErrorsNotification(this.file, this.errors);

  factory AnalysisErrorsNotification.fromJSON(Map<String, dynamic> json) {
    return new AnalysisErrorsNotification(json["file"], json["errors"].map((it) => new AnalysisError.fromJSON(it)).toList());
  }
}

abstract class AnalysisRequest {
  Map<String, dynamic> toJSON();
  AnalysisResponse getResponse(Map<String, dynamic> result);
}

abstract class AnalysisResponse {
}

class ServerVersionRequest extends AnalysisRequest {
  @override
  Map<String, dynamic> toJSON() => {
    "method": "server.getVersion"
  };

  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) =>
    new ServerVersionResponse.fromJSON(result);
}

class ServerVersionResponse extends AnalysisResponse {
  final String version;

  ServerVersionResponse(this.version);
  ServerVersionResponse.fromJSON(Map<String, dynamic> json) :
    this(json["version"]);
}

class EmptyResponse extends AnalysisResponse {
}

class ServerShutdownRequest extends AnalysisRequest {
  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) => new EmptyResponse();

  @override
  Map<String, dynamic> toJSON() => {
    "method": "server.shutdown"
  };
}

class Location {
  final String file;
  final int offset;
  final int length;
  final int startLine;
  final int startColumn;

  Location(this.file, this.offset, this.length, this.startLine, this.startColumn);

  factory Location.fromJSON(Map<String, dynamic> json) {
    var f = json["file"];
    var os = json["offset"];
    var len = json["length"];
    var line = json["startLine"];
    var col = json["startColumn"];

    return new Location(f, os, len, line, col);
  }

  @override
  String toString() => "Location(file: ${file}, offset: ${offset}, length: ${length}, line: ${startLine}, column: ${startColumn})";
}

class AnalysisError {
  final AnalysisErrorSeverity severity;
  final AnalysisErrorType type;
  final Location location;
  final String message;
  final String correction;

  AnalysisError(this.severity, this.type, this.location, this.message, this.correction);

  factory AnalysisError.fromJSON(Map<String, dynamic> json) {
    var s = AnalysisErrorSeverity.forName(json["severity"]);
    var t = AnalysisErrorType.forName(json["type"]);
    var loc = new Location.fromJSON(json["location"]);
    var m = json["message"];
    var c = json["correction"];

    return new AnalysisError(s, t, loc, m, c);
  }
}

class AnalysisErrorType {
  static const AnalysisErrorType CHECKED_MODE_COMPILE_TIME_ERROR = const AnalysisErrorType("CHECKED_MODE_COMPILE_TIME_ERROR");
  static const AnalysisErrorType COMPILE_TIME_ERROR = const AnalysisErrorType("COMPILE_TIME_ERROR");
  static const AnalysisErrorType HINT = const AnalysisErrorType("HINT");
  static const AnalysisErrorType LINT = const AnalysisErrorType("LINT");
  static const AnalysisErrorType STATIC_TYPE_WARNING = const AnalysisErrorType("STATIC_TYPE_WARNING");
  static const AnalysisErrorType STATIC_WARNING = const AnalysisErrorType("STATIC_WARNING");
  static const AnalysisErrorType SYNTACTIC_ERROR = const AnalysisErrorType("SYNTACTIC_ERROR");
  static const AnalysisErrorType TODO = const AnalysisErrorType("TODO");

  final String name;

  const AnalysisErrorType(this.name);

  static const List<AnalysisErrorType> values = const [
    CHECKED_MODE_COMPILE_TIME_ERROR,
    COMPILE_TIME_ERROR,
    HINT,
    LINT,
    STATIC_TYPE_WARNING,
    STATIC_WARNING,
    SYNTACTIC_ERROR,
    TODO
  ];

  static AnalysisErrorType forName(String name) => values.firstWhere((it) => it.name == name);
}

class GetErrorsRequest extends AnalysisRequest {
  final String file;

  GetErrorsRequest(this.file);


  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) =>
    new GetErrorsResponse.fromJSON(result);

  @override
  Map<String, dynamic> toJSON() => {
    "method": "analysis.getErrors",
    "params": {
      "file": file
    }
  };
}

class GetErrorsResponse extends AnalysisResponse {
  final List<AnalysisError> errors;

  GetErrorsResponse(this.errors);

  factory GetErrorsResponse.fromJSON(Map<String, dynamic> json) {
    var e = json["errors"].map((it) => new AnalysisError.fromJSON(it)).toList();
    return new GetErrorsResponse(e);
  }
}

class SetPriorityFilesRequest extends AnalysisRequest {
  final List<String> files;

  SetPriorityFilesRequest(this.files);

  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) =>
    new EmptyResponse();

  @override
  Map<String, dynamic> toJSON() => {
    "method": "analysis.setPriorityFiles",
    "params": {
      "files": files
    }
  };
}

class SetAnalysisRootsRequest extends AnalysisRequest {
  final List<String> included;
  final List<String> excluded;
  final Map<String, String> packageRoots;

  SetAnalysisRootsRequest(this.included, this.excluded, [this.packageRoots]);

  @override
  AnalysisResponse getResponse(Map<String, dynamic> result) => new EmptyResponse();

  @override
  Map<String, dynamic> toJSON() {
    var result = {
      "method": "analysis.setAnalysisRoots",
      "params": {}
    };

    var map = result["params"];

    map["included"] = included;
    map["excluded"] = excluded;
    if (packageRoots != null) {
      map["packageRoots"] = packageRoots;
    }

    return result;
  }
}

class AnalysisErrorSeverity {
  static const AnalysisErrorSeverity INFO = const AnalysisErrorSeverity("INFO");
  static const AnalysisErrorSeverity WARNING = const AnalysisErrorSeverity("WARNING");
  static const AnalysisErrorSeverity ERROR = const AnalysisErrorSeverity("ERROR");

  final String name;

  const AnalysisErrorSeverity(this.name);

  static const List<AnalysisErrorSeverity> values = const [
    INFO,
    WARNING,
    ERROR
  ];

  static AnalysisErrorSeverity forName(String name) => values.firstWhere((it) => it.name == name);
}

main(List<String> args) async {
  if (args.length != 1) {
    print("Usage: analysis <project>");
    exit(1);
  }

  var client = new AnalysisClient(new ProcessAnalysisChannel());

  await client.initialize();

  var version = await client.getServerVersion();

  print("Server Version: ${version}");

  var root = new Directory(args[0]);

  await client.setAnalysisRoots(included: [root.path]);

  client.onAnalysisErrors.listen((AnalysisErrorsNotification e) {
    if (e.errors.isEmpty) return;

    print("In file ${e.file}:");
    for (var error in e.errors) {
      print("- at ${error.location.startLine}:${error.location.startColumn}");
      print("  - Type: ${error.type.name}");
      print("  - Message: ${error.message}");
    }
  });
}
