import 'package:hive/hive.dart';
import '../models/cart_item.dart'; // Adjust path as necessary

const String _cartBoxName = 'cartBox';

class CartService {
  Future<void> openCartBox() async {
    await Hive.openBox<CartItem>(_cartBoxName);
  }

  Box<CartItem> _getCartBox() {
    return Hive.box<CartItem>(_cartBoxName);
  }

  Future<void> addItem(CartItem item) async {
    final box = _getCartBox();
    await box.put(item.productId, item);
  }

  Future<void> removeItem(String productId) async {
    final box = _getCartBox();
    await box.delete(productId);
  }

  // updateItem is effectively the same as addItem if using productID as key
  Future<void> updateItem(CartItem item) async {
    final box = _getCartBox();
    await box.put(item.productId, item);
  }

  List<CartItem> getCartItems() {
    final box = _getCartBox();
    return box.values.toList();
  }

  Future<void> clearCart() async {
    final box = _getCartBox();
    await box.clear();
  }

  Future<void> close() async {
    // Optional: Good practice to offer a way to close boxes if needed,
    // though Hive manages this fairly well automatically in many Flutter apps.
    final box = _getCartBox();
    await box.close();
  }
}
