import "dart:async";
import "dart:io";
 
Future<File> download(String url, String path) async {
  var file = new File(path);
  if (!(await file.exists())) await file.create();
  var stream = file.openWrite();
  var client = new HttpClient();
  var request = await client.getUrl(Uri.parse(url));
  var response = await request.close();
  await response.pipe(stream);
  client.close();
  return file;
}
