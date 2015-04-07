import "dart:async";
import "dart:convert";
import "dart:io";

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

main() async {
  await exec("cat", inherit: true);
}
