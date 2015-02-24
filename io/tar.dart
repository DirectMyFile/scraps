import "dart:convert";
import "dart:io";

class TarFile {
  final String name;
  final String mode;
  final String owner;
  final String group;
  final int size;
  final int modified;
  final String checksum;
  final TarFileType type;
  final String linkedFile;
  final List<int> data;
  
  TarFile(this.name, this.mode, this.owner, this.group, this.size, this.modified, this.checksum, this.type, this.linkedFile, this.data);
}

enum TarFileType {
  FILE,
  HARD_LINK,
  SYMBOLIC_LINK
}

class TarReader {
  final List<int> bytes;
  
  TarReader(this.bytes);
  
  List<TarFile> read() {
    var files = [];
    
    TarFile file;
    while ((file = readFile()) != null) {
      files.add(file);
    }
    
    return files;
  }
  
  TarFile readFile() {
    if (_position + 512 >= bytes.length || bytes.sublist(_position, bytes.length).every((x) => x == 0)) {
      return null;
    }
    
    var header = bytes.sublist(_position, _position + 512);
    var name = _decode(header.sublist(0, 99));
    var mode = _decode(header.sublist(100, 107));
    var owner = _decode(header.sublist(108, 115));
    var group = _decode(header.sublist(116, 123));
    var size = int.parse(_decode(header.sublist(124, 135)), radix: 8);
    var modified = int.parse(_decode(header.sublist(136, 147)), radix: 8);
    var checksum = _decode(header.sublist(148, 155));
    var typestr = _decode([header[156]]);
    var type;
    
    if (typestr == " ") {
      type = TarFileType.FILE;
    } else if (typestr == "0") {
      type = TarFileType.HARD_LINK;
    } else {
      type = TarFileType.SYMBOLIC_LINK;
    }
    
    var linkedFile = _decode(header.sublist(157, 166));
    var dataStart = _position + 512;
    var dataEnd = _position + 512 + size;
    var data = bytes.sublist(_position + 512, dataEnd);
    
    _position = dataEnd;
    
    return new TarFile(name, mode, owner, group, size, modified, checksum, type, linkedFile, data);
  }
  
  String _decode(List<int> input) {
    return ASCII.decode(input);
  }
  
  int _position = 0;
}

void main() {
  var reader = new TarReader(GZIP.decode(new File("io/hello.tar.gz").readAsBytesSync()));
  
  TarFile file;
  
  while ((file = reader.readFile())  != null) {
    print(file.name);
  }
}