import "dart:io";
import "package:image/image.dart" as img;

Future<List<int>> readUrl(String url) async {
  var bytes = [];
  var client = new HttpClient();
  var request = await client.getUrl(Uri.parse(url));
  var response = await request.close();
  await for (var buff in response) {
    bytes.addAll(buff);
  }
  client.close();
  return bytes;
}

Future<Image> fetchImage(String url) async {
  var bytes = await readUrl(url);
  return img.decodeImage(bytes);
}

Future<File> saveImage(String path, Image image) async {
  var file = new File(path);
  if (!await file.exists()) await file.create(recursive: true);
  await file.writeAsBytes(img.encodeNamedImage(image, path.split(Platform.pathSeparator).last));
  return file;
}
