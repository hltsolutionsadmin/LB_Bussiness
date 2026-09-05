import 'dart:async';

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
  Timer? _searchDebounce;
  int _searchToken = 0;

  final List<Map<String, dynamic>> _items = [];
  final Set<String> _updatingProductIds = {};
  bool _isLoading = false;
  bool _hasNext = true;
  int _page = 0;
  final int _size = 20;

  final List<String> _categories = [
    'all',
    'Starters',
    'Main-Course',
    'Noodles',
    'Tandori',
    'Breads',
    'Curries',
    'Soups',
    'Biryanis',
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
      if (existing != null) {
        await _updateSingleItem(existing['id']);
      } else {
        await _loadPage(refresh: true);
      }
    }
  }

  Future<void> _prefetchAllPagesForSearch(int token) async {
    if (token != _searchToken) return;
    // Only load next 2 pages for search to avoid performance issues
    int pagesToLoad = 2;
    while (mounted &&
        _hasNext &&
        _searchQuery.trim().isNotEmpty &&
        pagesToLoad > 0) {
      if (token != _searchToken) return;
      await _loadPage();
      if (token != _searchToken) return;
      pagesToLoad--;
    }
  }

  Future<void> _updateSingleItem(dynamic itemId) async {
    final storeId = sl<SessionStore>().storeId;
    final b2bUnitId = sl<SessionStore>().b2bUnitId;
    if (storeId.isEmpty || b2bUnitId.isEmpty) return;

    try {
      final repo = sl<ProductRepository>();
      Map<String, dynamic>? updatedItem;
      for (int page = 0; page < _page; page++) {
        final pageData = await repo.getProductsByB2bUnit(
          b2bUnitId: b2bUnitId,
          storeId: storeId,
          page: page,
          size: _size,
        );
        final itemIndex = pageData.items.indexWhere(
          (item) => item['id']?.toString() == itemId.toString(),
        );
        if (itemIndex != -1) {
          updatedItem = pageData.items[itemIndex];
          break;
        }
      }
      if (updatedItem != null && mounted) {
        setState(() {
          // Update the item in the list
          final itemIndex = _items.indexWhere((item) => item['id'] == itemId);
          if (itemIndex != -1) {
            _items[itemIndex] = updatedItem!;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
      }
    }
  }

  Future<void> _loadPage({bool refresh = false}) async {
    if (_isLoading) return;
    final storeId = sl<SessionStore>().storeId;
    final b2bUnitId = sl<SessionStore>().b2bUnitId;
    if (storeId.isEmpty || b2bUnitId.isEmpty) {
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Store ID not found')),
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
      final pageData = await repo.getProductsByB2bUnit(
        b2bUnitId: b2bUnitId,
        storeId: storeId,
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

  String _productId(Map<String, dynamic> item) => item['id']?.toString() ?? '';

  Future<void> _setProductActive(Map<String, dynamic> item, bool active) async {
    final productId = _productId(item);
    if (productId.isEmpty || _updatingProductIds.contains(productId)) {
      return;
    }

    final old = item['available'] == true;
    if (old == active) return;

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dCtx) => AlertDialog(
          title: const Text('Inactive product?'),
          content: const Text('Are you sure you want to inactive the product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dCtx, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      item['available'] = active;
      _updatingProductIds.add(productId);
    });

    try {
      final repo = sl<ProductRepository>();
      await repo.setProductActive(productId: productId, active: active);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Product activated' : 'Product inactivated'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => item['available'] = old);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
    } finally {
      if (mounted) {
        setState(() => _updatingProductIds.remove(productId));
      }
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
    _searchDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _items.where((item) {
      final name = (item['name'] ?? '').toString();
      final matchesSearch = name.toLowerCase().contains(
        _searchQuery.toLowerCase(),
      );
      final matchesCategory =
          _selectedCategory == 'all' ||
          item['categoryName'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Container(
      color: Colors.grey[50], // subtle background
      child: Column(
        children: [
          // Search Bar & Add Button
          SearchAddBar(
            onSearchChanged: (value) {
              setState(() => _searchQuery = value);
              _searchDebounce?.cancel();
              _searchToken++;
              final token = _searchToken;
              _searchDebounce = Timer(const Duration(milliseconds: 300), () {
                if (!mounted) return;
                if (_searchQuery.trim().isEmpty) return;
                _prefetchAllPagesForSearch(token);
              });
            },
            onAddPressed: () => _openProductForm(),
            onExportPressed: _exportMoved,
          ),

          // Category Filter
          CategoryFilter(
            categories: _categories,
            selected: _selectedCategory,
            onSelected: (c) {
              setState(() => _selectedCategory = c);
              debugPrint(
                'CategoryFilter - Selected category: $c--> $_selectedCategory',
              );
              setState(() => _selectedCategory = c);
            },
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
                          isUpdating: _updatingProductIds.contains(
                            _productId(item),
                          ),
                          onEdit: () => _openProductForm(existing: item),
                          onToggle: () async {
                            final current = item['available'] == true;
                            await _setProductActive(item, !current);
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
                                                id: item['id'],
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
                                  id: item['id'],
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
                            await _setProductActive(item, value);
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
