import "dart:io";

import "package:args/args.dart";
import "package:crypto/crypto.dart";

import "process.dart";

/// Snapshot Helpers

main(List<String> args) async {
  var argp = new ArgParser();

  argp.addOption("resource", abbr: "R", help: "Embed a Resource", allowMultiple: true);

  var opts = argp.parse(args);

  if (opts.rest.length != 1) {
    print("Usage: snapshot [opts] <file>");
    print(argp.usage);
    exit(1);
  }

  var resources = <String, List<int>>{};
  for (var x in opts["resource"]) {
    var c = x.split("=");
    resources[c[0]] = new File(c.skip(1).join("=")).readAsBytesSync();
  }

  var file = new File(opts.rest[0]);
  var of = new File("${file.path}.tmp");
  var c = file.readAsStringSync();
  var out = resources.keys.map((it) => '"${it}": const [${resources[it].join(',')}]').join(",\n");
  c = c.replaceAll("const Map<String, List<int>> resources = const {};", "const Map<String, List<int>> resources = const {${out}};");
  of.writeAsStringSync(c);
  var code = (await exec("dart", args: ["--snapshot=${file.path}.snapshot", of.path], inherit: true)).exitCode;
  of.deleteSync();
  exit(code);
}

String hashBytes(List<int> bytes) => CryptoUtils.bytesToHex((new SHA256()..add(bytes)).close());
