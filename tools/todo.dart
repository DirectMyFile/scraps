import "dart:io";

class TODO {
  final File file;

  List<String> _list = [];

  TODO(this.file);

  void add(String item) {
    _list.add(item);
  }

  void remove(String item) {
    _list.remove(item);
  }

  void removeAt(int id) {
    _list.removeAt(id - 1);
  }

  List<String> get list => new List<String>.unmodifiable(_list);

  load() async {
    if (!(await file.exists())) {
      return;
    }

    _list = (await file.readAsLines())
      .map((it) => it.trim())
      .where((it) => it.isNotEmpty)
      .toList();
  }

  save() async {
    if (!(await file.exists()))  {
      await file.create(recursive: true);
    }

    await file.writeAsString(_list.join("\n"));
  }
}
