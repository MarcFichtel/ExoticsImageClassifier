import 'package:uuid/uuid.dart';

/// Simple model class representing a member of the collection
class CollectionMember {
  final String uuid = Uuid().v1();
  final String name;
  final String species;
  final int daysSinceLastWater;
  final int daysSinceLastFood;
  final int daysSinceLastMolt;

  CollectionMember(this.name, this.species, this.daysSinceLastWater, this.daysSinceLastFood, this.daysSinceLastMolt);

  /// JSON to Object
  CollectionMember.fromJson(Map<String, dynamic> json) :
        name = json['name'],
        species = json['species'],
        daysSinceLastWater = json['daysSinceLastWater'],
        daysSinceLastFood = json['daysSinceLastFood'],
        daysSinceLastMolt = json['daysSinceLastMolt'];

  /// Object to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'species': species,
    'daysSinceLastWater': daysSinceLastWater,
    'daysSinceLastFood': daysSinceLastFood,
    'daysSinceLastMolt': daysSinceLastMolt,
  };
}