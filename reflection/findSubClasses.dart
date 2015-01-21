import "dart:mirrors";
 
List<Type> findSubClasses(Symbol libraryName, Type type) {
  var library = currentMirrorSystem().libraries.values.firstWhere((lib) {
    return lib.qualifiedName == libraryName;
  });
 
  ClassMirror toolClass = reflectClass(type);
 
  return library.declarations.values.where((it) {
    return it is ClassMirror && it.reflectedType != type && it.isSubclassOf(toolClass);
  }).toList();
}
