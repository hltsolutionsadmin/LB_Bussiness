import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';
import 'package:local_basket_business/widgets/search_bar_widget.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'package:local_basket_business/presentation/screens/admin/restaurant_onboarding.dart'
    show RestaurantOnboardingScreen;

class RestaurantManagementScreen extends StatefulWidget {
  final Function(String) onNavigate;
  const RestaurantManagementScreen({super.key, required this.onNavigate});

  @override
  State<RestaurantManagementScreen> createState() =>
      _RestaurantManagementScreenState();
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionText;
  final VoidCallback onAction;
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange600.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 32, color: AppColors.orange600),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: Text(actionText),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.orange600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RestaurantManagementScreenState
    extends State<RestaurantManagementScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filters = const ['All', 'Active', 'Pending', 'Inactive'];
  final List<_Restaurant> _all = [];
  final Set<String> _deletingStoreIds = {};
  final Set<String> _updatingStoreIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRestaurants();
  }

  Future<void> _loadRestaurants() async {
    setState(() => _loading = true);
    try {
      final b2bUnitId = GetIt.I<SessionStore>().b2bUnitId;
      if (b2bUnitId.isEmpty) {
        throw Exception('B2B unit ID not found');
      }

      final ds = GetIt.I<BusinessRemoteDataSource>();
      final list = await ds.searchStores(b2bUnitId: b2bUnitId);
      final mapped = list.map<_Restaurant>((raw) {
        final m = Map<String, dynamic>.from(raw);
        String str(dynamic v) => v?.toString() ?? '';
        final active = (m['active'] ?? m['enabled'] ?? false) == true;
        final name = str(m['name']).isNotEmpty ? str(m['name']) : 'N/A';
        return _Restaurant(
          id: str(m['id']),
          code: str(m['code']),
          name: name,
          active: active,
          imageUrl: str(m['imageUrl']),
        );
      }).toList();
      if (!mounted) return;
      setState(() {
        _all
          ..clear()
          ..addAll(mapped);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load restaurants')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStoreActive(_Restaurant restaurant, bool active) async {
    if (restaurant.id.isEmpty || _updatingStoreIds.contains(restaurant.id)) {
      return;
    }

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inactive store?'),
          content: const Text('Are you sure you want to inactive the store?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;
    }

    final old = restaurant;
    final optimistic = restaurant.copyWith(active: active);
    setState(() {
      _replaceRestaurant(optimistic);
      _updatingStoreIds.add(restaurant.id);
    });

    try {
      final response = await GetIt.I<BusinessRepository>().setStoreActive(
        storeId: restaurant.id,
        name: restaurant.name,
        code: restaurant.code,
        active: active,
      );
      if (!mounted) return;

      setState(() => _replaceRestaurant(optimistic.mergedWith(response)));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Store activated' : 'Store inactivated'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _replaceRestaurant(old));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update store status')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingStoreIds.remove(restaurant.id));
      }
    }
  }

  void _replaceRestaurant(_Restaurant restaurant) {
    final index = _all.indexWhere((item) => item.id == restaurant.id);
    if (index == -1) return;
    _all[index] = restaurant;
  }

  Future<void> _openOnboarding() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RestaurantOnboardingScreen(
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) {
      _loadRestaurants();
    }
  }

  Future<void> _confirmDeleteStore(_Restaurant restaurant) async {
    if (restaurant.id.isEmpty || _deletingStoreIds.contains(restaurant.id)) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete store?'),
        content: Text(
          'Are you sure you want to delete "${restaurant.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _deletingStoreIds.add(restaurant.id));
    try {
      await GetIt.I<BusinessRemoteDataSource>().deleteStore(
        storeId: restaurant.id,
      );
      if (!mounted) return;
      setState(() => _all.removeWhere((item) => item.id == restaurant.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store deleted successfully')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to delete store')));
    } finally {
      if (mounted) {
        setState(() => _deletingStoreIds.remove(restaurant.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final restaurants = _filtered();
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child:
                    Column(
                          children: [
                            SearchBarWidget(
                              hintText: 'Search restaurants...',
                              onChanged: (v) =>
                                  setState(() => _searchQuery = v),
                            ),
                            const SizedBox(height: 12),
                            _buildFilterChips(),
                          ],
                        )
                        .animate()
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: -0.2, end: 0, duration: 300.ms),
              ),
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : restaurants.isEmpty
                    ? _EmptyState(
                        icon: Icons.restaurant,
                        title: 'No Restaurants Found',
                        message: _searchQuery.isNotEmpty
                            ? 'No restaurants match your search'
                            : 'Add your first restaurant to get started',
                        actionText: 'Add Restaurant',
                        onAction: _openOnboarding,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: restaurants.length,
                        itemBuilder: (context, index) {
                          final restaurant = restaurants[index];
                          return _RestaurantCard(
                            data: restaurant,
                            index: index,
                            isDeleting: _deletingStoreIds.contains(
                              restaurant.id,
                            ),
                            isUpdating: _updatingStoreIds.contains(
                              restaurant.id,
                            ),
                            onActiveChanged: (active) =>
                                _setStoreActive(restaurant, active),
                            onDelete: () => _confirmDeleteStore(restaurant),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<_Restaurant> _filtered() {
    var list = List<_Restaurant>.from(_all);
    if (_searchQuery.isNotEmpty) {
      list = list
          .where(
            (r) =>
                r.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                r.code.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }
    if (_selectedFilter != 'All') {
      list = list.where((r) => r.status == _selectedFilter).toList();
    }
    return list;
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter),
              selected: isSelected,
              onSelected: (_) => setState(() => _selectedFilter = filter),
              backgroundColor: AppColors.glass,
              selectedColor: AppColors.orange600,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isSelected ? AppColors.orange600 : AppColors.glassBorder,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final _Restaurant data;
  final int index;
  final bool isDeleting;
  final bool isUpdating;
  final ValueChanged<bool> onActiveChanged;
  final VoidCallback onDelete;
  const _RestaurantCard({
    required this.data,
    required this.index,
    required this.isDeleting,
    required this.isUpdating,
    required this.onActiveChanged,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
          margin: const EdgeInsets.only(bottom: 12),
          onTap: () => _showDetails(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      data.imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.orange600.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.restaurant,
                          color: AppColors.orange600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                data.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            SizedBox(
                              width: 112,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: _StoreStatusToggle(
                                  active: data.active,
                                  busy: isUpdating,
                                  onChanged: onActiveChanged,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 40,
                              height: 40,
                              child: isDeleting
                                  ? const Center(
                                      child: SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    )
                                  : IconButton(
                                      tooltip: 'Delete store',
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                      ),
                                      color: AppColors.error,
                                      onPressed: onDelete,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.code.isEmpty ? 'Store' : 'Code: ${data.code}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 14,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to view products',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(color: Color(0x33FFFFFF), height: 1),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Stat(
                    label: 'Code',
                    value: data.code.isEmpty ? '—' : data.code,
                  ),
                  Container(width: 1, height: 30, color: AppColors.glassBorder),
                  _StatusStat(active: data.active),
                  Container(width: 1, height: 30, color: AppColors.glassBorder),
                  _Stat(label: 'Store ID', value: _shortId(data.id)),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(delay: (index * 50).ms, duration: 300.ms)
        .slideX(begin: 0.2, end: 0, duration: 300.ms);
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DetailsSheet(data: data),
    );
  }
}

class _DetailsSheet extends StatefulWidget {
  final _Restaurant data;

  const _DetailsSheet({required this.data});

  @override
  State<_DetailsSheet> createState() => _DetailsSheetState();
}

class _DetailsSheetState extends State<_DetailsSheet> {
  static const int _pageSize = 20;

  final List<Map<String, dynamic>> _products = [];
  final Set<String> _updatingProductIds = {};
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasNext = true;
  int _page = 0;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _errorText = null;
      _page = 0;
      _hasNext = true;
    });

    try {
      final page = await GetIt.I<ProductRepository>().getProductsByStoreId(
        storeId: widget.data.id,
        page: 0,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _products
          ..clear()
          ..addAll(page.items);
        _hasNext = page.hasNext;
        _page = page.page + 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _errorText = 'Failed to load products');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_loading || _loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);

    try {
      final page = await GetIt.I<ProductRepository>().getProductsByStoreId(
        storeId: widget.data.id,
        page: _page,
        size: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _products.addAll(page.items);
        _hasNext = page.hasNext;
        _page = page.page + 1;
      });
    } catch (_) {
      // Silently ignore load-more failures; user can retry by scrolling again.
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _productId(Map<String, dynamic> product) =>
      product['id']?.toString() ?? '';

  Future<void> _setProductActive(
    Map<String, dynamic> product,
    bool active,
  ) async {
    final productId = _productId(product);
    if (productId.isEmpty || _updatingProductIds.contains(productId)) {
      return;
    }

    final old = product['available'] == true;
    if (old == active) return;

    if (!active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Inactive product?'),
          content: const Text('Are you sure you want to inactive the product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    setState(() {
      product['available'] = active;
      _updatingProductIds.add(productId);
    });

    try {
      await GetIt.I<ProductRepository>().setProductActive(
        productId: productId,
        active: active,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(active ? 'Product activated' : 'Product inactivated'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => product['available'] = old);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update product status')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingProductIds.remove(productId));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.red950, AppColors.orange950],
          ),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (_hasNext &&
                !_loading &&
                !_loadingMore &&
                notification.metrics.pixels >=
                    notification.metrics.maxScrollExtent - 200) {
              _loadMoreProducts();
            }
            return false;
          },
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.data.imageUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.orange600.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.restaurant,
                                  color: AppColors.orange600,
                                  size: 40,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.data.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.data.code.isEmpty
                                    ? 'Store'
                                    : 'Code: ${widget.data.code}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _StoreStatusText(active: widget.data.active),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _DetailRow(
                      icon: Icons.badge_outlined,
                      label: 'Store ID',
                      value: widget.data.id,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.qr_code_2,
                      label: 'Store Code',
                      value: widget.data.code.isEmpty ? '—' : widget.data.code,
                    ),
                    const SizedBox(height: 12),
                    _DetailRow(
                      icon: Icons.toggle_on_outlined,
                      label: 'Status',
                      value: widget.data.status,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Products',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!_loading)
                          Text(
                            '${_products.length}',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        IconButton(
                          onPressed: _loading ? null : _loadProducts,
                          icon: const Icon(Icons.refresh),
                          color: AppColors.orange600,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_loading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_errorText != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _errorText!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      )
                    else if (_products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'No products found for this restaurant',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    else
                      ..._products.map(
                        (product) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ProductSummaryCard(
                            product: product,
                            isUpdating: _updatingProductIds.contains(
                              _productId(product),
                            ),
                            onActiveChanged: (active) =>
                                _setProductActive(product, active),
                          ),
                        ),
                      ),
                    if (_loadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductSummaryCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final bool isUpdating;
  final ValueChanged<bool> onActiveChanged;

  const _ProductSummaryCard({
    required this.product,
    required this.isUpdating,
    required this.onActiveChanged,
  });

  @override
  Widget build(BuildContext context) {
    final name = product['name']?.toString() ?? 'Item';
    final code = product['code']?.toString() ?? '';
    final price = (product['price'] is num)
        ? (product['price'] as num).toDouble()
        : double.tryParse(product['price']?.toString() ?? '') ?? 0.0;
    final available = product['available'] == true;
    final approvalStatus = product['approvalStatus']?.toString() ?? '';
    final cardColor = available
        ? Colors.white.withOpacity(0.08)
        : const Color(0xFFE5E7EB).withOpacity(0.72);
    final borderColor = available
        ? AppColors.glassBorder
        : const Color(0xFFD1D5DB);
    final iconColor = available ? AppColors.orange600 : AppColors.textMuted;
    final iconBg = available
        ? AppColors.orange600.withOpacity(0.2)
        : const Color(0xFFD1D5DB);
    final titleColor = available
        ? AppColors.textPrimary
        : const Color(0xFF6B7280);
    final bodyColor = available
        ? AppColors.textSecondary
        : const Color(0xFF9CA3AF);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.restaurant_menu, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  code.isEmpty ? 'Product' : 'Code: $code',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: bodyColor),
                ),
                if (approvalStatus.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    approvalStatus,
                    style: TextStyle(
                      fontSize: 11,
                      color: bodyColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                ),
              ),
              const SizedBox(height: 6),
              _ProductStatusToggle(
                active: available,
                busy: isUpdating,
                onChanged: onActiveChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProductStatusToggle extends StatelessWidget {
  final bool active;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _ProductStatusToggle({
    required this.active,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
        ],
        Text(
          active ? 'Active' : 'Inactive',
          style: TextStyle(
            fontSize: 11,
            color: active ? AppColors.info : AppColors.error,
            fontWeight: FontWeight.w700,
          ),
        ),
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: active,
            onChanged: busy ? null : onChanged,
            activeColor: AppColors.info,
            activeTrackColor: AppColors.info.withOpacity(0.35),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _StoreStatusToggle extends StatelessWidget {
  final bool active;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _StoreStatusToggle({
    required this.active,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy) ...[
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 4),
        ],
        _StoreStatusText(active: active),
        Transform.scale(
          scale: 0.72,
          child: Switch(
            value: active,
            onChanged: busy ? null : onChanged,
            activeColor: AppColors.info,
            activeTrackColor: AppColors.info.withOpacity(0.35),
            inactiveThumbColor: AppColors.textMuted,
            inactiveTrackColor: const Color(0xFFE5E7EB),
          ),
        ),
      ],
    );
  }
}

class _StoreStatusText extends StatelessWidget {
  final bool active;
  const _StoreStatusText({required this.active});

  @override
  Widget build(BuildContext context) {
    return Text(
      active ? 'Active' : 'Inactive',
      style: TextStyle(
        fontSize: 11,
        color: active ? AppColors.info : AppColors.error,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _StatusStat extends StatelessWidget {
  final bool active;
  const _StatusStat({required this.active});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Status',
          style: TextStyle(fontSize: 11, color: AppColors.textMuted),
        ),
        const SizedBox(height: 4),
        _StoreStatusText(active: active),
      ],
    );
  }
}

class _Restaurant {
  final String id;
  final String code;
  final String name;
  final bool active;
  final String imageUrl;

  _Restaurant({
    required this.id,
    required this.code,
    required this.name,
    required this.active,
    required this.imageUrl,
  });

  String get status => active ? 'Active' : 'Inactive';

  _Restaurant copyWith({
    String? id,
    String? code,
    String? name,
    bool? active,
    String? imageUrl,
  }) {
    return _Restaurant(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      active: active ?? this.active,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  _Restaurant mergedWith(Map<String, dynamic> data) {
    String str(dynamic v) => v?.toString() ?? '';
    bool boolValue(dynamic v, bool fallback) {
      if (v is bool) return v;
      if (v is num) return v != 0;
      final text = v?.toString().toLowerCase();
      if (text == 'true') return true;
      if (text == 'false') return false;
      return fallback;
    }

    final nextId = str(data['id']);
    final nextCode = str(data['code']);
    final nextName = str(data['name']);
    final nextImageUrl = str(data['imageUrl']);
    return copyWith(
      id: nextId.isEmpty ? id : nextId,
      code: nextCode.isEmpty ? code : nextCode,
      name: nextName.isEmpty ? name : nextName,
      active: boolValue(data['active'] ?? data['enabled'], active),
      imageUrl: nextImageUrl.isEmpty ? imageUrl : nextImageUrl,
    );
  }
}

String _shortId(String value) {
  if (value.length <= 8) return value;
  return value.substring(0, 8);
}
