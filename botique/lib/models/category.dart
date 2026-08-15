class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  bool get isSubcategory => parentId != null;
}
