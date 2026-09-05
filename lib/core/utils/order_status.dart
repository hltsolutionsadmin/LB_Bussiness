/// Single source of truth for the merchant-side order lifecycle.
///
/// Flow: CREATED ──accept──▶ CONFIRMED ──▶ PREPARING ──▶ READY ──▶ (done)
library;

/// Normalises a raw backend status string into a coarse stage.
String orderStage(String status) {
  final s = status.toLowerCase();
  if (s.contains('created') ||
      s.contains('new') ||
      s.contains('place') ||
      s.contains('pending')) {
    return 'new';
  }
  if (s.contains('confirm') || s.contains('accept')) return 'confirmed';
  if (s.contains('prepar')) return 'preparing';
  if (s.contains('ready')) return 'ready';
  if (s.contains('picked')) return 'picked_up';
  if (s.contains('in_delivery') || s.contains('out_for')) return 'in_delivery';
  if (s.contains('delivered')) return 'delivered';
  if (s.contains('cancel') || s.contains('reject')) return 'cancelled';
  return s;
}

/// The stage shown to the merchant. Their workflow only has four steps, so
/// anything the backend reports at or after READY — out for delivery, assigned
/// to a partner, picked up, delivered, … — collapses to `ready`: once the food
/// is ready the merchant is done. Rejected / cancelled stays distinct.
String merchantStage(String status) {
  switch (orderStage(status)) {
    case 'new':
      return 'new';
    case 'confirmed':
      return 'confirmed';
    case 'preparing':
      return 'preparing';
    case 'cancelled':
      return 'cancelled';
    default:
      return 'ready';
  }
}

/// Human label for the merchant stage.
String merchantStatusLabel(String status) {
  switch (merchantStage(status)) {
    case 'new':
      return 'New';
    case 'confirmed':
      return 'Confirmed';
    case 'preparing':
      return 'Preparing';
    case 'cancelled':
      return 'Cancelled';
    default:
      return 'Ready';
  }
}

/// Merchant workflow is two taps only:
///  1. "Accept Order"  → pushes CONFIRMED then PREPARING
///  2. "Mark as Ready" → pushes READY
/// Returns the full status chain to push for the single action available at
/// [status], or `null` when the order is already READY (nothing left to do).
List<String>? nextOrderStatuses(String status) {
  switch (merchantStage(status)) {
    case 'new':
      return const ['CONFIRMED', 'PREPARING'];
    case 'confirmed':
      // Stuck at CONFIRMED (e.g. half-failed accept) — fill the gap too.
      return const ['PREPARING', 'READY'];
    case 'preparing':
      return const ['READY'];
    default:
      return null;
  }
}

/// True only while the order is brand-new and waiting to be accepted — the
/// state that triggers the alert popup + sound.
bool isAwaitingAcceptance(String status) => merchantStage(status) == 'new';
