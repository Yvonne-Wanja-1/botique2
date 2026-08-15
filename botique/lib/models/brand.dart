class Brand {
  const Brand({
    required this.id,
    required this.name,
    this.logoUrl,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String? logoUrl;
  final bool isActive;
}