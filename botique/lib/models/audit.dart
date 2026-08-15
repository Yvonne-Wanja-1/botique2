enum InventoryChangeType { add, reduce, adjust, purchase }

class InventoryTransaction {
  const InventoryTransaction({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.previousQuantity,
    required this.newQuantity,
    required this.reason,
    this.staffName,
    required this.createdAt,
  });

  final String id;
  final String productId;
  final String productName;
  final InventoryChangeType type;
  final int previousQuantity;
  final int newQuantity;
  final String reason;
  final String? staffName;
  final DateTime createdAt;

  int get quantityChanged => newQuantity - previousQuantity;
}

enum AuditAction { create, update, delete, approve, reject, adjust, login, logout }

class AuditLog {
  const AuditLog({
    required this.id,
    required this.staffName,
    required this.action,
    required this.resource,
    required this.description,
    this.previousValue,
    this.newValue,
    required this.createdAt,
  });

  final String id;
  final String staffName;
  final AuditAction action;
  final String resource;
  final String description;
  final String? previousValue;
  final String? newValue;
  final DateTime createdAt;
}