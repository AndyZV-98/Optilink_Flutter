import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';

/// Pantalla donde se revisan los productos antes de confirmar el pedido.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _confirmOrder(BuildContext context) async {
    final cartProvider = context.read<CartProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final placed = await cartProvider.placeOrder();
      if (!placed) return;

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Pedido enviado. Puedes seguirlo en "Pedidos".'),
          backgroundColor: Colors.green,
        ),
      );
      navigator.pop();
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo enviar el pedido. Revisa tu conexión e inténtalo de '
            'nuevo.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Pedido (Carrito)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tu carrito está vacío.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back, color: Colors.blue),
                    label: const Text('Volver al Catálogo'),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: items.length,
              itemBuilder: (context, index) => CartItemTile(item: items[index]),
            ),
      // Al ir en bottomNavigationBar, los avisos (SnackBar) aparecen encima del
      // resumen y no tapan el botón de confirmar.
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildOrderSummary(context, cartProvider),
    );
  }

  // Total del pedido y botón de confirmación
  Widget _buildOrderSummary(BuildContext context, CartProvider cartProvider) {
    final isPlacingOrder = cartProvider.isPlacingOrder;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Total (${cartProvider.totalQuantity} '
                    '${cartProvider.totalQuantity == 1 ? 'unidad' : 'unidades'}):',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatCurrency(cartProvider.totalAmount),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isPlacingOrder ? null : () => _confirmOrder(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: isPlacingOrder
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Confirmar Pedido',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de un producto en el carrito, con control de cantidad.
class CartItemTile extends StatelessWidget {
  final CartItem item;

  const CartItemTile({required this.item, super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.read<CartProvider>();
    final canAddMore = item.product.canOrder(item.quantity + 1);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ProductImage(
                url: item.product.imageUrl,
                width: 60,
                height: 60,
                iconSize: 28,
              ),
            ),
            const SizedBox(width: 12),

            // Nombre, precio y subtotal
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatCurrency(item.product.price)} x ${item.quantity}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'Subtotal: ${formatCurrency(item.subtotal)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Control de cantidad
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  tooltip: item.quantity == 1 ? 'Quitar' : 'Restar una unidad',
                  onPressed: () => cartProvider.decrementQuantity(item),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: Colors.green,
                  tooltip: canAddMore
                      ? 'Sumar una unidad'
                      : 'No hay más unidades disponibles',
                  onPressed: canAddMore
                      ? () => cartProvider.incrementQuantity(item)
                      : null,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
