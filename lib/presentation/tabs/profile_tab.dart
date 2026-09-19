import 'package:flutter/material.dart';
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/presentation/screens/restaurant/mobile_login.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/services/orders_poller.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'package:local_basket_business/presentation/screens/terms/terms_and_conditions.dart';
import 'package:local_basket_business/presentation/screens/restaurant/past_orders_screen.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  bool _updatingStore = false;

  bool _isStoreActive() {
    final user = sl<SessionStore>().user;
    final store = (user?['store'] is Map<String, dynamic>)
        ? user!['store'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final active = store['active'];
    if (active is bool) return active;
    return true;
  }

  Future<void> _setStoreActive(bool active) async {
    if (_updatingStore) return;

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
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
    }

    final session = sl<SessionStore>();
    final user = session.user ?? const <String, dynamic>{};
    final store = (user['store'] is Map<String, dynamic>)
        ? user['store'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final storeId = (user['storeId']?.toString().isNotEmpty ?? false)
        ? user['storeId'].toString()
        : store['id']?.toString() ?? '';
    final name = store['name']?.toString() ?? session.businessName;
    final code = store['code']?.toString() ?? '';

    if (storeId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Store ID not found')),
      );
      return;
    }

    setState(() => _updatingStore = true);
    try {
      await sl<BusinessRepository>().setStoreActive(
        storeId: storeId,
        name: name,
        code: code,
        active: active,
      );
      final updatedStore = Map<String, dynamic>.from(store);
      updatedStore['active'] = active;
      final updatedUser = Map<String, dynamic>.from(user);
      updatedUser['store'] = updatedStore;
      session.setUser(updatedUser);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(active ? 'Store activated' : 'Store inactivated')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update store status')),
      );
    } finally {
      if (mounted) setState(() => _updatingStore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF97316).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.restaurant_menu,
                          size: 32,
                          color: Color(0xFFF97316),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AnimatedBuilder(
                          animation: sl<SessionStore>(),
                          builder: (context, _) {
                            final session = sl<SessionStore>();
                            final name = session.businessName;
                            final userName = session.userDisplayName;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Restaurant Partner',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFFED7AA),
                                  ),
                                ),
                                if (userName.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AnimatedBuilder(
                    animation: sl<SessionStore>(),
                    builder: (context, _) {
                      final phone = sl<SessionStore>().primaryContact;
                      final displayPhone = phone.isEmpty
                          ? '—'
                          : (phone.startsWith('+') ? phone : phone);
                      return _InfoRow(icon: Icons.phone, text: displayPhone);
                    },
                  ),
                  const SizedBox(height: 8),
                  // _InfoRow(
                  //   icon: Icons.email,
                  //   text: 'spicegarden@restaurant.com',
                  // ),
                  // const SizedBox(height: 8),
                  // _InfoRow(
                  //   icon: Icons.location_on,
                  //   text: 'Shop No. 12, Sector 18, Noida, UP 201301',
                  // ),
                  // const SizedBox(height: 8),
                  _InfoRow(
                    icon: Icons.access_time,
                    text: '10:00 AM - 11:00 PM',
                  ),
                  const SizedBox(height: 16),
                  // Edit Profile button removed as per request
                  const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Menu Options
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _MenuItem(
                    icon: Icons.store,
                    iconColor: Colors.orange,
                    label: 'Restaurant Details',
                    description: 'Update restaurant information',
                    onTap: () async {
                      final session = sl<SessionStore>();
                      final user = session.user ?? <String, dynamic>{};
                      final b2b = (user['b2bUnit'] is Map<String, dynamic>)
                          ? user['b2bUnit'] as Map<String, dynamic>
                          : const <String, dynamic>{};
                      final store = (user['store'] is Map<String, dynamic>)
                          ? user['store'] as Map<String, dynamic>
                          : const <String, dynamic>{};

                      String readString(Map<String, dynamic> m, String key) {
                        final v = m[key];
                        if (v == null) return '';
                        if (v is String && v.trim().isEmpty) return '';
                        return v.toString();
                      }

                      final items = <MapEntry<String, String>>[];
                      final storeName = readString(store, 'name');
                      final businessName = session.businessName;
                      if (storeName.trim().isNotEmpty) {
                        items.add(MapEntry('Store Name', storeName));
                      } else if (businessName.trim().isNotEmpty) {
                        items.add(MapEntry('Business Name', businessName));
                      }
                      final storeCode = readString(store, 'code');
                      if (storeCode.isNotEmpty) {
                        items.add(MapEntry('Store Code', storeCode));
                      }
                      final storeId = readString(user, 'storeId').isNotEmpty
                          ? readString(user, 'storeId')
                          : readString(store, 'id');
                      if (storeId.isNotEmpty) {
                        items.add(MapEntry('Store ID', storeId));
                      }
                      final userName = session.userDisplayName;
                      if (userName.trim().isNotEmpty) {
                        items.add(MapEntry('User Name', userName));
                      }
                      final phoneRaw = session.primaryContact;
                      if (phoneRaw.trim().isNotEmpty) {
                        items.add(MapEntry('Login Number', phoneRaw));
                      }
                      final email = readString(user, 'email');
                      if (email.isNotEmpty) items.add(MapEntry('Email', email));
                      final username = readString(user, 'username');
                      if (username.isNotEmpty && username != email) {
                        items.add(MapEntry('Username', username));
                      }
                      final storeType = readString(store, 'storeType');
                      if (storeType.isNotEmpty) {
                        items.add(MapEntry('Store Type', storeType));
                      }
                      final storeRole = readString(store, 'storeRole');
                      if (storeRole.isNotEmpty) {
                        items.add(MapEntry('Store Role', storeRole));
                      }
                      final active = store['active'];
                      if (active is bool) {
                        items.add(
                          MapEntry(
                            'Store Status',
                            active ? 'Active' : 'Inactive',
                          ),
                        );
                      }
                      final approvalStatus = readString(
                        store,
                        'approvalStatus',
                      );
                      if (approvalStatus.isNotEmpty) {
                        items.add(MapEntry('Approval Status', approvalStatus));
                      }
                      final b2bUnitId = readString(user, 'b2bUnitId').isNotEmpty
                          ? readString(user, 'b2bUnitId')
                          : readString(store, 'b2bUnitId');
                      if (b2bUnitId.isNotEmpty) {
                        items.add(MapEntry('B2B Unit ID', b2bUnitId));
                      }
                      final latitude = readString(store, 'latitude');
                      final longitude = readString(store, 'longitude');
                      if (latitude.isNotEmpty && longitude.isNotEmpty) {
                        items.add(
                          MapEntry('Location', '$latitude, $longitude'),
                        );
                      }
                      final gst = readString(b2b, 'gstNo');
                      if (gst.isNotEmpty) items.add(MapEntry('GST No', gst));
                      final addr1 = readString(b2b, 'addressLine1');
                      if (addr1.isNotEmpty) {
                        items.add(MapEntry('Address Line 1', addr1));
                      }
                      final addr2 = readString(b2b, 'addressLine2');
                      if (addr2.isNotEmpty) {
                        items.add(MapEntry('Address Line 2', addr2));
                      }
                      final city = readString(b2b, 'city');
                      if (city.isNotEmpty) items.add(MapEntry('City', city));
                      final state = readString(b2b, 'state');
                      if (state.isNotEmpty) items.add(MapEntry('State', state));
                      final pincode = readString(b2b, 'pincode');
                      if (pincode.isNotEmpty) {
                        items.add(MapEntry('Pincode', pincode));
                      }

                      await showDialog(
                        context: context,
                        builder: (dCtx) {
                          return Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 24,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(22),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 30,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ---------- Premium Gradient Header ----------
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 18,
                                      horizontal: 20,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFFEF5F0C),
                                          Color(0xFFEF5F0C),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(22),
                                        topRight: Radius.circular(22),
                                      ),
                                    ),
                                    child: const Text(
                                      "Restaurant Details",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 6),

                                  // ---------- Content Body ----------
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    child: items.isEmpty
                                        ? const Padding(
                                            padding: EdgeInsets.symmetric(
                                              vertical: 30,
                                            ),
                                            child: Text(
                                              "No details available",
                                              style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          )
                                        : SizedBox(
                                            width: double.maxFinite,
                                            child: ListView.separated(
                                              shrinkWrap: true,
                                              itemCount: items.length,
                                              physics:
                                                  const NeverScrollableScrollPhysics(),
                                              separatorBuilder: (_, __) =>
                                                  Divider(
                                                    height: 18,
                                                    thickness: 0.6,
                                                    color: Colors.grey.shade300,
                                                  ),
                                              itemBuilder: (_, i) {
                                                final e = items[i];
                                                return Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    SizedBox(
                                                      width: 130,
                                                      child: Text(
                                                        e.key,
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color: Color(
                                                            0xFF6B7280,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        e.value,
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          color: Color(
                                                            0xFF111827,
                                                          ),
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                );
                                              },
                                            ),
                                          ),
                                  ),

                                  const SizedBox(height: 10),

                                  // ---------- Footer Button ----------
                                  Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: TextButton(
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFEF5F0C),
                                            ),
                                          ),
                                        ),
                                        onPressed: () => Navigator.pop(dCtx),
                                        child: const Text(
                                          'Close',
                                          style: TextStyle(
                                            color: Color(0xFFEF5F0C),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  AnimatedBuilder(
                    animation: sl<SessionStore>(),
                    builder: (context, _) {
                      return _MenuItem(
                        icon: Icons.power_settings_new,
                        iconColor: Colors.green,
                        label: 'Store Status',
                        description: 'Turn store active or inactive',
                        trailing: _updatingStore
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Switch(
                                value: _isStoreActive(),
                                activeThumbColor: const Color(0xFF10B981),
                                onChanged: _setStoreActive,
                              ),
                        onTap: () {
                          if (!_updatingStore) {
                            _setStoreActive(!_isStoreActive());
                          }
                        },
                      );
                    },
                  ),
                  const Divider(height: 1),
                  _MenuItem(
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    label: 'Operating Hours',
                    description: 'Manage opening & closing times',
                    onTap: () async {
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
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                      primary: Colors.orange,
                                                      onPrimary: Colors.white,
                                                      onSurface: Colors.black,
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
                                            fillColor: Colors.grey.shade100,
                                            prefixIcon: const Icon(
                                              Icons.timer_outlined,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                              data: Theme.of(context).copyWith(
                                                colorScheme:
                                                    const ColorScheme.light(
                                                      primary: Colors.orange,
                                                      onPrimary: Colors.white,
                                                      onSurface: Colors.black,
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
                                            fillColor: Colors.grey.shade100,
                                            prefixIcon: const Icon(
                                              Icons.timer_outlined,
                                            ),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
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
                                        borderRadius: BorderRadius.circular(14),
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
                                        final sess = sl<SessionStore>().user;
                                        final b2b =
                                            (sess != null &&
                                                sess['b2bUnit']
                                                    is Map<String, dynamic>)
                                            ? sess['b2bUnit']
                                                  as Map<String, dynamic>
                                            : null;
                                        final bid = (b2b?['id'] as int?) ?? 0;
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
                                        final repo = sl<ProductRepository>();
                                        await repo.updateBusinessTimings(
                                          businessId: bid,
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
                                                'Operating hours updated',
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
                  ),
                  const Divider(height: 1),
                  /*
                  _MenuItem(
                    icon: Icons.credit_card,
                    iconColor: Colors.green,
                    label: 'Payment & Bank Details',
                    description: 'Manage payment methods',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  */
                  /*
                  _MenuItem(
                    icon: Icons.settings,
                    iconColor: Colors.grey,
                    label: 'Settings',
                    description: 'App preferences & notifications',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  */
                  /*
                  _MenuItem(
                    icon: Icons.help_outline,
                    iconColor: Colors.purple,
                    label: 'Help & Support',
                    description: 'Get help or contact support',
                    onTap: () {},
                  ),
                  const Divider(height: 1),
                  */
                  // Store-admin / restaurant-owner only — business admins
                  // manage orders from the admin dashboard's reports instead.
                  AnimatedBuilder(
                    animation: sl<SessionStore>(),
                    builder: (context, _) {
                      if (!sl<SessionStore>().isStoreVendor) {
                        return const SizedBox.shrink();
                      }
                      return Column(
                        children: [
                          _MenuItem(
                            icon: Icons.history,
                            iconColor: Colors.teal,
                            label: 'Past Orders',
                            description: 'View delivered order history',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const PastOrdersScreen(),
                                ),
                              );
                            },
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  ),
                  _MenuItem(
                    icon: Icons.description,
                    iconColor: Colors.indigo,
                    label: 'Terms & Policies',
                    description: 'Read our terms and policies',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const TermsAndConditionsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // App Version
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'App Version',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'v2.4.1',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Logout'),
                      content: const Text(
                        'Are you sure you want to logout from this account?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm != true) return;

                  try {
                    await sl<AppSecureStorage>().clearToken();
                  } catch (_) {}

                  try {
                    sl<SessionStore>().clear();
                  } catch (_) {}

                  try {
                    sl<OrdersPoller>().reset();
                  } catch (_) {}

                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFEE2E2),
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFFFED7AA)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Color(0xFFFED7AA)),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String description;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.description,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}
