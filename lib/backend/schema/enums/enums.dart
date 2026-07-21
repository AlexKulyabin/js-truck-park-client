import 'package:collection/collection.dart';

enum TabsToggle {
  info,
  review,
  photo,
}

enum MainImpression {
  level5,
  level4,
  level3,
  level2,
  level1,
}

enum ConvenienceOfTruckArrival {
  level5,
  level4,
  level3,
  level2,
  level1,
}

enum SecurityLevel {
  level5,
  level4,
  level3,
  level2,
  level1,
}

enum ComfortForRelaxation {
  level5,
  level4,
  level3,
  level2,
  level1,
}

enum Infrastructure {
  level5,
  level4,
  level3,
  level2,
  level1,
}

enum StatusParking {
  approved,
  pending,
  rejected,
}

enum Report {
  Report1,
  Report2,
  Report3,
}

extension FFEnumExtensions<T extends Enum> on T {
  String serialize() => name;
}

extension FFEnumListExtensions<T extends Enum> on Iterable<T> {
  T? deserialize(String? value) =>
      firstWhereOrNull((e) => e.serialize() == value);
}

T? deserializeEnum<T>(String? value) {
  switch (T) {
    case (TabsToggle):
      return TabsToggle.values.deserialize(value) as T?;
    case (MainImpression):
      return MainImpression.values.deserialize(value) as T?;
    case (ConvenienceOfTruckArrival):
      return ConvenienceOfTruckArrival.values.deserialize(value) as T?;
    case (SecurityLevel):
      return SecurityLevel.values.deserialize(value) as T?;
    case (ComfortForRelaxation):
      return ComfortForRelaxation.values.deserialize(value) as T?;
    case (Infrastructure):
      return Infrastructure.values.deserialize(value) as T?;
    case (StatusParking):
      return StatusParking.values.deserialize(value) as T?;
    case (Report):
      return Report.values.deserialize(value) as T?;
    default:
      return null;
  }
}
