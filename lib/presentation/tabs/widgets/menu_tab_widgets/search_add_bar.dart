import 'package:flutter/material.dart';

class SearchAddBar extends StatelessWidget {
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onAddPressed;
  final VoidCallback? onExportPressed;

  const SearchAddBar({
    super.key,
    required this.onSearchChanged,
    this.onAddPressed,
    this.onExportPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                onChanged: onSearchChanged,
                decoration: const InputDecoration(
                  hintText: 'Search menu items...',
                  prefixIcon: Icon(Icons.search, color: Color(0xFF9CA3AF)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          if (onAddPressed != null)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA05D), Color(0xFFF97316)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onAddPressed,
                icon: const Icon(Icons.add, color: Colors.white),
              ),
            ),
          //
        ],
      ),
    );
  }
}
