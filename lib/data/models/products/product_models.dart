class ProductPage {
  final List<Map<String, dynamic>> items;
  final bool hasNext;
  final int page;
  final int size;

  ProductPage({
    required this.items,
    required this.hasNext,
    required this.page,
    required this.size,
  });
}
