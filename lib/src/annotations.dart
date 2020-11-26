// Annotations
// Annotation for defining Primary Key
class PK {
  // Defined if PK is autoincremented or not
  final bool ai;
  const PK({this.ai});
}

// Annotation for parsing HiveType
class HiveType {
  final int typeId;
  const HiveType({this.typeId});
}

// Annotation for parsing HiveField
class HiveField {
  final int id;
  const HiveField(this.id);
}

class NullableMoor {
  const NullableMoor();
}

class DefaultValue {
  final value;
  const DefaultValue({this.value});
}
