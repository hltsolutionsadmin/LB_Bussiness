import 'package:flutter/material.dart';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'widgets/menu_tab_widgets/search_add_bar.dart';
import 'widgets/menu_tab_widgets/category_filter.dart';
import 'widgets/menu_tab_widgets/menu_item_card.dart';
import 'widgets/menu_tab_widgets/product_form_sheet.dart';

class MenuTab extends StatefulWidget {
  const MenuTab({super.key});

  @override
  State<MenuTab> createState() => _MenuTabState();
}

class _MenuTabState extends State<MenuTab> {
  String _searchQuery = '';
  String _selectedCategory = 'all';
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _items = [];
  bool _isLoading = false;
  bool _hasNext = true;
  int _page = 0;
  final int _size = 10;

  final List<String> _categories = [
    'all',
    'starters',
    'main course',
    'breads',
    'beverages',
    'desserts',
  ];

  void _exportMoved() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export moved to Analytics tab')),
    );
  }

  Future<void> _openProductForm({Map<String, dynamic>? existing}) async {
    final result = await showProductFormSheet(context, existing: existing);
    if (result == true) {
      await _loadPage(refresh: true);
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_isLoading) return;
    final user = sl<SessionStore>().user;
    final businessId = (user != null && user['b2bUnit'] is Map<String, dynamic>)
        ? (user['b2bUnit']['id'] as int?)
        : null;
    if (businessId == null) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Business ID not found')),
          );
        });
      }
      return;
    }
    setState(() => _isLoading = true);
    try {
      if (refresh) {
        _page = 0;
        _hasNext = true;
        _items.clear();
      }
      if (!_hasNext) return;
      final repo = sl<ProductRepository>();
      final pageData = await repo.getProducts(
        restaurantId: businessId,
        page: _page,
        size: _size,
      );
      setState(() {
        _items.addAll(pageData.items);
        _hasNext = pageData.hasNext;
        _page = pageData.page + 1;
      });
    } catch (e) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load products: $e')),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPage();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasNext) {
        _loadPage();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final matchesSearch = item['name'].toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'all' || item['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Container(
      color: Colors.grey[50], // subtle background
      child: Column(
        children: [
          // Search Bar & Add Button
          SearchAddBar(
            onSearchChanged: (value) => setState(() => _searchQuery = value),
            onAddPressed: () => _openProductForm(),
            onExportPressed: _exportMoved,
          ),

          // Category Filter
          CategoryFilter(
            categories: _categories,
            selected: _selectedCategory,
            onSelected: (c) => setState(() => _selectedCategory = c),
          ),

          const SizedBox(height: 16),

          // Menu Items List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _loadPage(refresh: true),
              child: filteredItems.isEmpty && !_isLoading
                  ? ListView(
                      padding: const EdgeInsets.all(32),
                      children: const [
                        Center(
                          child: Text(
                            'No menu items found',
                            style: TextStyle(color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: Responsive.horizontalPadding(context),
                      ),
                      itemCount: filteredItems.length + (_hasNext ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= filteredItems.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final item = filteredItems[index];
                        return MenuItemCard(
                          item: item,
                          onEdit: () => _openProductForm(existing: item),
                          onToggle: () async {
                            final current = item['available'] == true;
                            try {
                              final repo = sl<ProductRepository>();
                              await repo.toggleAvailability(
                                id: (item['id'] as int),
                              );
                              if (!mounted) return;
                              setState(() {
                                item['available'] = !current;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    !current
                                        ? 'Marked available'
                                        : 'Marked unavailable',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to toggle: $e')),
                              );
                            }
                          },
                          onTimings: () async {
                            final startCtrl = TextEditingController();
                            final endCtrl = TextEditingController();
                            await showDialog(
                              context: context,
                              builder: (dCtx) {
                                return StatefulBuilder(
                                  builder: (context, setState) {
                                    return AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Colors.white,
                                      title: const Text(
                                        'Update Operating Hours',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          GestureDetector(
                                            onTap: () async {
                                              final TimeOfDay?
                                              picked = await showTimePicker(
                                                context: dCtx,
                                                initialTime: TimeOfDay.now(),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                          colorScheme:
                                                              const ColorScheme.light(
                                                                primary: Colors
                                                                    .orange,
                                                                onPrimary:
                                                                    Colors
                                                                        .white,
                                                                onSurface:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  startCtrl.text =
                                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                });
                                              }
                                            },
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: startCtrl,
                                                decoration: InputDecoration(
                                                  labelText: 'Start Time',
                                                  filled: true,
                                                  fillColor:
                                                      Colors.grey.shade100,
                                                  prefixIcon: const Icon(
                                                    Icons.timer_outlined,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          GestureDetector(
                                            onTap: () async {
                                              final TimeOfDay?
                                              picked = await showTimePicker(
                                                context: dCtx,
                                                initialTime: TimeOfDay.now(),
                                                builder: (context, child) {
                                                  return Theme(
                                                    data: Theme.of(context)
                                                        .copyWith(
                                                          colorScheme:
                                                              const ColorScheme.light(
                                                                primary: Colors
                                                                    .orange,
                                                                onPrimary:
                                                                    Colors
                                                                        .white,
                                                                onSurface:
                                                                    Colors
                                                                        .black,
                                                              ),
                                                        ),
                                                    child: child!,
                                                  );
                                                },
                                              );
                                              if (picked != null) {
                                                setState(() {
                                                  endCtrl.text =
                                                      '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                                });
                                              }
                                            },
                                            child: AbsorbPointer(
                                              child: TextField(
                                                controller: endCtrl,
                                                decoration: InputDecoration(
                                                  labelText: 'End Time',
                                                  filled: true,
                                                  fillColor:
                                                      Colors.grey.shade100,
                                                  prefixIcon: const Icon(
                                                    Icons.timer_outlined,
                                                  ),
                                                  border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      actionsPadding: const EdgeInsets.only(
                                        bottom: 12,
                                        right: 12,
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(dCtx),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(fontSize: 16),
                                          ),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                          ),
                                          onPressed: () async {
                                            final start = startCtrl.text.trim();
                                            final end = endCtrl.text.trim();
                                            if (start.isEmpty || end.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Start and End times are required',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            try {
                                              final sess =
                                                  sl<SessionStore>().user;
                                              final b2b =
                                                  (sess != null &&
                                                      sess['b2bUnit']
                                                          is Map<
                                                            String,
                                                            dynamic
                                                          >)
                                                  ? sess['b2bUnit']
                                                        as Map<String, dynamic>
                                                  : null;
                                              final bid =
                                                  (b2b?['id'] as int?) ?? 0;
                                              if (bid == 0) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Business ID not found',
                                                    ),
                                                  ),
                                                );
                                                return;
                                              }
                                              final repo =
                                                  sl<ProductRepository>();
                                              await repo.updateProductTimings(
                                                id: (item['id'] as int),
                                                startTime: start,
                                                endTime: end,
                                              );
                                              if (context.mounted) {
                                                Navigator.pop(dCtx);
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Product timings updated',
                                                    ),
                                                  ),
                                                );
                                              }
                                            } catch (e) {
                                              if (context.mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Failed: $e'),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text(
                                            'Save',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
                          onDelete: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (dCtx) => AlertDialog(
                                title: const Text('Delete product?'),
                                content: const Text(
                                  'This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(dCtx, true),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              try {
                                final repo = sl<ProductRepository>();
                                await repo.deleteProduct(
                                  id: (item['id'] as int),
                                );
                                if (!mounted) return;
                                await _loadPage(refresh: true);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Product deleted'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Delete failed: $e')),
                                );
                              }
                            }
                          },
                          onSwitchToggle: (value) async {
                            final old = item['available'] == true;
                            setState(() {
                              item['available'] = value;
                            });
                            try {
                              final repo = sl<ProductRepository>();
                              await repo.toggleAvailability(
                                id: (item['id'] as int),
                              );
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value
                                        ? 'Marked available'
                                        : 'Marked unavailable',
                                  ),
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() {
                                item['available'] = old;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to toggle: $e')),
                              );
                            }
                          },
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
