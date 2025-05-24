import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/cart_provider.dart';
// import '../models/cart_item.dart'; // CartItem is implicitly used via cartProvider

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);

    double calculateTotalPrice() {
      double total = 0;
      for (var item in cartItems) {
        total += item.price * item.quantity;
      }
      return total;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
      ),
      body: Column(
        children: [
          Expanded(
            child: cartItems.isEmpty
                ? const Center(child: Text('Your cart is empty.'))
                : ListView.builder(
                    itemCount: cartItems.length,
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return ListTile(
                        title: Text(item.name),
                        subtitle: Text('Price: \$${item.price.toStringAsFixed(2)} - Quantity: ${item.quantity}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () {
                                ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity - 1);
                              },
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () {
                                // For simplicity, adding one more of the same item.
                                // In a real app, you might have a different way to add quantity or distinct items.
                                ref.read(cartProvider.notifier).updateQuantity(item.productId, item.quantity + 1);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () {
                                ref.read(cartProvider.notifier).removeItem(item.productId);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (cartItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total: \$${calculateTotalPrice().toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(cartProvider.notifier).clearCart();
                    },
                    child: const Text('Clear Cart'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
