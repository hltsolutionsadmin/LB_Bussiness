class OrdersPage {
  final List<Map<String, dynamic>> items;
  final bool hasNext;
  final int page;
  final int size;

  OrdersPage({
    required this.items,
    required this.hasNext,
    required this.page,
    required this.size,
  });
}
