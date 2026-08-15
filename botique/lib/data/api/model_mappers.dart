DateTime? dateFromJson(Object? value) => value is String ? DateTime.tryParse(value) : null;

double priceFromJson(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int intFromJson(Object? value) {
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool boolFromJson(Object? value) => value is bool ? value : value == 'true';

String? stringOrNull(Object? value) => value?.toString();