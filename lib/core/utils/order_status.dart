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

/// Merchant workflow, one tap (one backend transition) per stage:
///  new       → "Accept Order"      → CONFIRMED
///  confirmed → "Mark as Preparing" → PREPARING
///  preparing → "Mark as Ready"     → READY
/// Returns the status chain to push for the single action available at
/// [status], or `null` once the order is READY (nothing left to do).
///
/// Each step is a single transition on purpose: jumping two states at once
/// used to skip the "preparing" stage entirely and left the card stuck on a
/// stale status when the second call failed.
List<String>? nextOrderStatuses(String status) {
  switch (merchantStage(status)) {
    case 'new':
      return const ['CONFIRMED'];
    case 'confirmed':
      return const ['PREPARING'];
    case 'preparing':
      return const ['READY'];
    default:
      return null;
  }
}

/// True only while the order is brand-new and waiting to be accepted — the
/// state that triggers the alert popup + sound.
bool isAwaitingAcceptance(String status) => merchantStage(status) == 'new';
