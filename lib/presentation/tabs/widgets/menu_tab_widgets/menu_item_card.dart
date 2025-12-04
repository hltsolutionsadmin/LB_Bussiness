import 'package:flutter/material.dart';

class MenuItemCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onEdit;
  final Future<void> Function() onToggle;
  final Future<void> Function() onTimings;
  final Future<void> Function() onDelete;
  final Future<void> Function(bool value) onSwitchToggle;

  const MenuItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onToggle,
    required this.onTimings,
    required this.onDelete,
    required this.onSwitchToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  (item['imageUrl'] != null &&
                      (item['imageUrl'] as String).isNotEmpty)
                  ? Image.network(
                      item['imageUrl'] as String,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => const Icon(
                        Icons.restaurant_menu,
                        size: 36,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  : const Icon(
                      Icons.restaurant_menu,
                      size: 36,
                      color: Color(0xFF9CA3AF),
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        color: Colors.white,
                        icon: const Icon(
                          Icons.more_vert,
                          color: Color(0xFF6B7280),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        onSelected: (value) async {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'timings') {
                            await onTimings();
                          } else if (value == 'delete') {
                            await onDelete();
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Color(0xFF374151),
                                ),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 'timings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 18,
                                  color: Color(0xFF374151),
                                ),
                                SizedBox(width: 8),
                                Text('Timings'),
                              ],
                            ),
                          ),

                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    item['category'].toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['description'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₹${item['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            item['available'] ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              fontSize: 12,
                              color: item['available']
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Switch(
                            value: item['available'] == true,
                            onChanged: (v) => onSwitchToggle(v),
                            activeThumbColor: Colors.green,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
