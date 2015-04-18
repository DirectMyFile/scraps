import "dart:async";
import "dart:io";
import "dart:convert";

HttpClient client = new HttpClient()
  ..maxConnectionsPerHost = 4;

main() async {
  var pkgs = await getAllPackages(onPageFetched: (number, total) {
    print("Fetched Page #${number} (${total} packages)");
  });

  var encoder = new JsonEncoder.withIndent("  ");
  var index = new File("${Platform.environment["HOME"]}/.pub-cache/index.json");
  await index.writeAsString(encoder.convert({
    "packages": pkgs
  }));
  await client.close();
}

Future<List<Map<String, dynamic>>> getAllPackages({void onPageFetched(int number, int total)}) async {
  var pkgs = <Map<String, dynamic>>[];

  var page = {
    "next_url": "https://pub.dartlang.org/api/packages?page=1",
    "packages": []
  };

  var number = 1;

  while ((number == 1 || page["packages"].isNotEmpty) && page["next_url"] != null) {
    page = await fetchPage(page["next_url"]);
    pkgs.addAll(page["packages"]);

    if (onPageFetched != null) {
      onPageFetched(number, pkgs.length);
    }

    number++;
  }

  return pkgs;
}

fetchPage(String url) async {
  var uri = Uri.parse(url);
  var request = await client.getUrl(uri);
  var response = await request.close();
  var data = await response.transform(UTF8.decoder).join();

  return JSON.decode(data);
}
