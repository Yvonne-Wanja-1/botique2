class Brand {
  const Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isActive = true,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      logoUrl: json['logoUrl'] as String?,
      isActive: json['isActive'] != false,
    );
  }

  final String id;
  final String name;
  final String? logoUrl;
  final bool isActive;
}