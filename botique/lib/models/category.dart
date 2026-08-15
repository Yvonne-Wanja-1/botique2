class Category {
  const Category({
    required this.id,
    required this.name,
    this.parentId,
    this.description,
    this.imageUrl,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      parentId: json['parentId'] as String?,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      isActive: json['isActive'] != false,
    );
  }

  final String id;
  final String name;
  final String? parentId;
  final String? description;
  final String? imageUrl;
  final bool isActive;

  bool get isSubcategory => parentId != null;
}
