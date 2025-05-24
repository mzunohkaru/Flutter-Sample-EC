import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';

class CartNotifier extends StateNotifier<List<CartItem>> {
  final CartService _cartService;

  CartNotifier(this._cartService) : super([]) {
    _loadCartItems();
  }

  void _loadCartItems() {
    // Assuming _cartService.openCartBox() has been called elsewhere (e.g. main.dart)
    // and is synchronous or handled appropriately if async.
    // If openCartBox is async and must complete before getCartItems,
    // this loading logic would need to be async and potentially handled
    // differently, perhaps by initializing the state after an async load.
    state = _cartService.getCartItems();
  }

  Future<void> addItem(CartItem item) async {
    final existingItemIndex = state.indexWhere((i) => i.productId == item.productId);

    if (existingItemIndex != -1) {
      // Item exists, update its quantity
      final existingItem = state[existingItemIndex];
      final updatedItem = existingItem.copyWith(quantity: existingItem.quantity + item.quantity);
      await _cartService.addItem(updatedItem); // addItem in service handles update
      final newState = List<CartItem>.from(state);
      newState[existingItemIndex] = updatedItem;
      state = newState;
    } else {
      // Item does not exist, add new item
      await _cartService.addItem(item);
      state = [...state, item];
    }
  }

  Future<void> removeItem(String productId) async {
    await _cartService.removeItem(productId);
    state = state.where((item) => item.productId != productId).toList();
  }

  Future<void> updateQuantity(String productId, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(productId);
    } else {
      final itemIndex = state.indexWhere((i) => i.productId == productId);
      if (itemIndex != -1) {
        final updatedItem = state[itemIndex].copyWith(quantity: newQuantity);
        // Use the service's addItem method which also handles updates
        await _cartService.addItem(updatedItem);
        final newState = List<CartItem>.from(state);
        newState[itemIndex] = updatedItem;
        state = newState;
      }
      // If item not found, it's a no-op for update, or you could choose to add it.
      // Current requirement implies updating existing, so no action if not found.
    }
  }

  Future<void> clearCart() async {
    await _cartService.clearCart();
    state = [];
  }
}

// Provider for CartService itself, in case other parts of the app need it directly
// or if we want to manage its lifecycle with Riverpod.
final cartServiceProvider = Provider<CartService>((ref) {
  // If CartService required async setup (like opening a box that must be awaited here),
  // this provider might need to be a FutureProvider, or the async setup handled differently.
  return CartService();
});

// Provider for CartNotifier
final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  final cartService = ref.watch(cartServiceProvider);
  // Crucial: cartService.openCartBox() must have been called before this notifier is
  // actively used if _loadCartItems relies on it being open.
  // We are currently assuming openCartBox() is called in main.dart or similar
  // global setup phase of the app.
  return CartNotifier(cartService);
});
