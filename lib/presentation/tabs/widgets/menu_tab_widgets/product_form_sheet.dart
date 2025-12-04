import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'premium_fields.dart';

Future<bool?> showProductFormSheet(
  BuildContext context, {
  Map<String, dynamic>? existing,
}) async {
  final session = sl<SessionStore>();
  final b2b = session.user?['b2bUnit'] as Map<String, dynamic>?;
  final businessId = (b2b?['id'] as int?) ?? 0;

  final nameCtrl = TextEditingController(
    text: existing?['name']?.toString() ?? '',
  );
  final codeCtrl = TextEditingController(
    text: existing?['shortCode']?.toString() ?? '',
  );
  final priceCtrl = TextEditingController(
    text: existing?['price']?.toString() ?? '',
  );
  final descCtrl = TextEditingController(
    text: existing?['description']?.toString() ?? '',
  );
  final categoryIdCtrl = TextEditingController(
    text: existing?['categoryId']?.toString() ?? '',
  );

  bool available = (existing?['available'] ?? true) == true;
  bool ignoreTax = false;
  bool discount = false;

  String productType = 'FOOD';
  String orderType = 'Online';
  String itemType = 'Veg';

  final ImagePicker picker = ImagePicker();
  XFile? pickedImage;

  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return DraggableScrollableSheet(
        initialChildSize: 0.92,
        maxChildSize: 0.95,
        minChildSize: 0.6,
        builder: (_, controller) {
          return Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: StatefulBuilder(
              builder: (ctx, setSheetState) {
                return SingleChildScrollView(
                  controller: controller,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 45,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            existing == null ? 'Add Product' : 'Edit Product',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 26),
                            onPressed: () => Navigator.pop(ctx, false),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      PremiumInput(label: 'Product Name', controller: nameCtrl),
                      const SizedBox(height: 14),
                      PremiumInput(label: 'Short Code', controller: codeCtrl),
                      const SizedBox(height: 14),
                      PremiumInput(
                        label: 'Price',
                        controller: priceCtrl,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      PremiumInput(
                        label: 'Category ID',
                        controller: categoryIdCtrl,
                        inputType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      PremiumInput(
                        label: 'Description',
                        controller: descCtrl,
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: PremiumDropdown(
                              label: 'Order Type',
                              value: orderType,
                              items: const ['Online', 'Offline'],
                              onChanged: (v) => setSheetState(
                                () => orderType = v ?? orderType,
                              ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: PremiumDropdown(
                              label: 'Item Type',
                              value: itemType,
                              items: const ['Veg', 'Non-Veg'],
                              onChanged: (v) =>
                                  setSheetState(() => itemType = v ?? itemType),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 10,
                        children: [
                          PremiumChip(
                            label: 'Available',
                            selected: available,
                            onTap: () =>
                                setSheetState(() => available = !available),
                          ),
                          PremiumChip(
                            label: 'Ignore Tax',
                            selected: ignoreTax,
                            onTap: () =>
                                setSheetState(() => ignoreTax = !ignoreTax),
                          ),
                          PremiumChip(
                            label: 'Discount',
                            selected: discount,
                            onTap: () =>
                                setSheetState(() => discount = !discount),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () async {
                          final x = await picker.pickImage(
                            source: ImageSource.gallery,
                          );
                          setSheetState(() => pickedImage = x);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.image, size: 28),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  pickedImage == null
                                      ? 'Pick Image'
                                      : pickedImage!.name,
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      Container(
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: const LinearGradient(
                            colors: [Color(0xffFF7A00), Color(0xffFF4500)],
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              if (businessId == 0) {
                                throw 'Business ID missing';
                              }
                              if (nameCtrl.text.trim().isEmpty) {
                                throw 'Name required';
                              }
                              if (priceCtrl.text.trim().isEmpty) {
                                throw 'Price required';
                              }

                              final repo = sl<ProductRepository>();
                              final parsedCategoryId =
                                  int.tryParse(categoryIdCtrl.text.trim()) ?? 0;
                              if (parsedCategoryId == 0) {
                                throw 'Valid Category ID required';
                              }
                              final attrs = [
                                {
                                  'attributeName': 'orderType',
                                  'attributeValue': orderType,
                                },
                                {
                                  'attributeName': 'type',
                                  'attributeValue': itemType,
                                },
                              ];

                              if (existing == null) {
                                await repo.createProduct(
                                  name: nameCtrl.text.trim(),
                                  shortCode: codeCtrl.text.trim(),
                                  ignoreTax: ignoreTax,
                                  discount: discount,
                                  description: descCtrl.text.trim(),
                                  price: priceCtrl.text.trim(),
                                  available: available,
                                  productType: productType,
                                  businessId: businessId,
                                  categoryId: parsedCategoryId,
                                  attributes: attrs,
                                  imageFilePath: pickedImage?.path,
                                );
                              } else {
                                await repo.updateProduct(
                                  id: existing['id'] as int,
                                  name: nameCtrl.text.trim(),
                                  shortCode: codeCtrl.text.trim(),
                                  ignoreTax: ignoreTax,
                                  discount: discount,
                                  description: descCtrl.text.trim(),
                                  price: priceCtrl.text.trim(),
                                  available: available,
                                  productType: productType,
                                  businessId: businessId,
                                  categoryId: parsedCategoryId,
                                  attributes: attrs,
                                  imageFilePath: pickedImage?.path,
                                );
                              }

                              if (!ctx.mounted) return;
                              Navigator.pop(ctx, true);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    existing == null
                                        ? 'Product created'
                                        : 'Product updated',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(
                                ctx,
                              ).showSnackBar(SnackBar(content: Text('$e')));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                          ),
                          child: Text(
                            existing == null ? 'Create' : 'Update',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}
