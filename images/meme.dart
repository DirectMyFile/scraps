import "dart:io";
import "package:image/image.dart" as img;
import "utils.dart";

Future<Image> createMeme(String url, String top, [String bottom]) async {
  var image = await fetchImage(url);
  var font = img.arial_24;
  
  void drawLine(String line, bool down) {
    var width = image.width;
    var length = line.length;
    var center = length ~/ 2;
    var x = (width ~/ 2) - (center * (font.size ~/ 2));
  
    image = img.drawString(image, font, x, down ? image.height - (font.size + 5) : 5, line);
  }
  
  drawLine(top, false);
  if (bottom != null) {
    drawLine(bottom, true);
  }
  
  return image;
}

main() async {
  var image = await createMeme("http://cdn.meme.am/images/984.jpg", "I'm Empty", "Please Fill Me In");
  await saveImage("out.jpg", image);
}
