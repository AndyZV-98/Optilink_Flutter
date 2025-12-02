import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';

// Pantalla donde se revisan los productos antes de confirmar el pedido.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escucha el CartProvider para re-renderizar cuando los ítems cambien
    final cartProvider = Provider.of<CartProvider>(context);
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Mi Pedido (Carrito)',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: cartProvider.items.isEmpty
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
                    onPressed: () =>
                        Navigator.pop(context), // Regresar al catálogo
                    icon: const Icon(Icons.arrow_back, color: Colors.blue),
                    label: const Text('Volver al Catálogo'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(top: 8.0),
                    itemCount: cartProvider.items.length,
                    itemBuilder: (context, index) {
                      final item = cartProvider.items[index];
                      return CartItemTile(
                        item: item,
                        currencyFormatter: currencyFormatter,
                      );
                    },
                  ),
                ),
                _buildOrderSummary(context, cartProvider, currencyFormatter),
              ],
            ),
    );
  }

  // Widget para el resumen del pedido y botón de confirmación
  Widget _buildOrderSummary(
    BuildContext context,
    CartProvider cartProvider,
    NumberFormat currencyFormatter,
  ) {
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total del Pedido:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              Text(
                currencyFormatter.format(cartProvider.totalAmount),
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
            onPressed: () async {
              // Lógica de confirmación
              // Usamos el método `placeOrder` corregido en el proveedor.
              final success = await cartProvider.placeOrder();
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('¡Pedido confirmado con éxito!'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Navegar de vuelta al catálogo o a la pantalla de pedidos
                Navigator.pop(context);
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Error al procesar el pedido. Inténtalo de nuevo.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
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
    );
  }
}

// Widget para cada artículo en el carrito
class CartItemTile extends StatelessWidget {
  final CartItem item;
  final NumberFormat currencyFormatter;

  const CartItemTile({
    required this.item,
    required this.currencyFormatter,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Escuchamos el carrito usando listen: false porque solo modificaremos el estado
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            // Imagen del Producto
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.product.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 60,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.broken_image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Detalles del Producto
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
                    '${currencyFormatter.format(item.product.price)} x ${item.quantity}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  Text(
                    'Total: ${currencyFormatter.format(item.subtotal)}', // Usamos item.subtotal
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),

            // Control de Cantidad
            Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.red,
                  ),
                  onPressed: () {
                    // LLama al método existente `decrementQuantity`
                    cartProvider.decrementQuantity(item);
                  },
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.green,
                  ),
                  onPressed: () {
                    // Se podría agregar una validación de stock aquí:
                    // if (item.quantity < item.product.stock)
                    // LLama al método existente `incrementQuantity`
                    cartProvider.incrementQuantity(item);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
