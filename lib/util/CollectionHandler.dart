import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:tarantula_classifier/data/CollectionMember.dart';

/// Handle collection data
class CollectionHandler {

  /// Get the collection from memory
  Future<List<CollectionMember>> getCollection() async {
    final file = await _getOrCreateCollectionFile;
    if (await file.length() == 0) return List();

    final String collectionJson = await file.readAsString();
    final List<dynamic> decoded = jsonDecode(collectionJson);
    final List<CollectionMember> collection = List();
    for (var val in decoded) { collection.add(CollectionMember.fromJson(val)); }

    collection.sort((m1, m2) => m1.species.compareTo(m2.species));
    return collection;
  }

  /// Add [member] to the collection
  /// Returns the complete collection after adding the new member
  Future<List<CollectionMember>> addMember(CollectionMember member) async {
    final List<CollectionMember> collection = await getCollection();
    collection.add(member);
    _updateCollectionFile(collection);
    collection.sort((m1, m2) => m1.species.compareTo(m2.species));
    return collection;
  }

  /// Delete all members
  /// Returns true on success
  Future<bool> deleteAllMembers() async {
    final file = await _getOrCreateCollectionFile;
    file.delete();
    return !(await file.exists());
  }

  /// Delete a [member]
  /// Returns the complete collection after removing the [member]
  Future<List<CollectionMember>> deleteMember(CollectionMember member) async {
    final List<CollectionMember> collection = await getCollection();
    collection.remove(member);
    _updateCollectionFile(collection);
    return collection;
  }

  /// Update member
  Future<List<CollectionMember>> updateMember(CollectionMember member) async {
    final List<CollectionMember> collection = await getCollection();

    // get existing entry based on uuid
    final CollectionMember existing = collection.firstWhere((m) => m.uuid == member.uuid);
    collection.remove(existing);
    collection.add(member);

    _updateCollectionFile(collection);
    collection.sort((m1, m2) => m1.species.compareTo(m2.species));
    return collection;
  }

  // private

  /// Get or create the collection file
  Future<File> get _getOrCreateCollectionFile async {
    final directory = await getApplicationDocumentsDirectory();
    final path = directory.path;
    final File file = File('$path/collection.txt');
    if (!(await file.exists())) { file.createSync(); }
    return file;
  }

  /// Update the collection file
  void _updateCollectionFile(List<CollectionMember> collection) async {
    final file = await _getOrCreateCollectionFile;
    final String json = jsonEncode(collection);
    file.writeAsString(json);
  }
}