import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cart_item.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/max_width.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';

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
          backgroundColor: AppColors.success,
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
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = context.watch<CartProvider>();
    final items = cartProvider.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Mi Pedido (Carrito)')),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Tu carrito está vacío.',
              subtitle: 'Añade productos desde el catálogo.',
              action: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Volver al Catálogo'),
              ),
            )
          : MaxWidth(
              child: ListView.separated(
                padding: const EdgeInsets.all(16.0),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    CartItemTile(item: items[index]),
              ),
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : _buildOrderSummary(context, cartProvider),
    );
  }

  // Total del pedido y botón de confirmación
  Widget _buildOrderSummary(BuildContext context, CartProvider cartProvider) {
    final isPlacingOrder = cartProvider.isPlacingOrder;
    final units = cartProvider.totalQuantity;

    return BottomActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  'Total ($units ${units == 1 ? 'unidad' : 'unidades'}):',
                  style: const TextStyle(fontSize: 15, color: AppColors.muted),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                formatCurrency(cartProvider.totalAmount),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: isPlacingOrder ? null : () => _confirmOrder(context),
            child: isPlacingOrder
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Confirmar Pedido'),
          ),
        ],
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
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ProductImage(
                url: item.product.imageUrl,
                width: 64,
                height: 64,
                iconSize: 26,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatCurrency(item.product.price)} x ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      QuantityStepper(
                        compact: true,
                        quantity: item.quantity,
                        decrementTooltip: item.quantity == 1
                            ? 'Quitar'
                            : 'Restar una unidad',
                        incrementTooltip: canAddMore
                            ? 'Sumar una unidad'
                            : 'No hay más unidades disponibles',
                        onDecrement: () => cartProvider.decrementQuantity(item),
                        onIncrement: canAddMore
                            ? () => cartProvider.incrementQuantity(item)
                            : null,
                      ),
                      const Spacer(),
                      Text(
                        formatCurrency(item.subtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
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
