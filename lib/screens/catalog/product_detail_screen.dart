import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../utils/formatters.dart';
import '../../widgets/product_image.dart';

/// Detalle de un producto, con selector de cantidad para añadirlo al carrito.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({required this.product, super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _addToCart(CartProvider cartProvider, int quantity) {
    final added = cartProvider.addItem(widget.product, quantity: quantity);
    if (added == 0) return;

    setState(() => _quantity = 1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$added x ${widget.product.name} en el carrito.'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final cartProvider = context.watch<CartProvider>();
    final inCart = cartProvider.quantityOf(product.id);

    // Unidades que todavía se pueden añadir; null si no hay control de stock.
    final int? available = product.stock == null
        ? null
        : math.max(0, product.stock! - inCart);
    final canAdd = available == null || available > 0;
    final quantity = available == null
        ? _quantity
        : math.max(1, math.min(_quantity, available));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProductImage(
                url: product.imageUrl,
                width: double.infinity,
                height: 250,
                iconSize: 50,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              product.name,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              product.category,
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            const SizedBox(height: 10),
            Text(
              formatCurrency(product.price),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.green.shade700,
              ),
            ),
            if (product.stock != null) ...[
              const SizedBox(height: 4),
              Text(
                product.isOutOfStock
                    ? 'Agotado'
                    : 'Disponibles: ${product.stock}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: product.isOutOfStock
                      ? Colors.red.shade700
                      : Colors.black54,
                ),
              ),
            ],
            if (inCart > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Ya tienes $inCart en el carrito.',
                style: TextStyle(fontSize: 14, color: Colors.blue.shade700),
              ),
            ],
            const Divider(height: 30),
            _buildAttributes(product),
            if (product.description.isNotEmpty) ...[
              const Text(
                'Descripción:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                product.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ],
          ],
        ),
      ),

      // Barra fija con el selector de cantidad y el botón de añadir. Al ir en
      // bottomNavigationBar, los avisos (SnackBar) aparecen encima y no la tapan.
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (canAdd) _buildQuantityControl(quantity, available),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: canAdd
                    ? () => _addToCart(cartProvider, quantity)
                    : null,
                child: Text(
                  canAdd ? 'Añadir al Carrito' : 'Sin unidades disponibles',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: canAdd ? Colors.white : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Código y características de la luna; se omiten las que estén vacías
  Widget _buildAttributes(Product product) {
    final attributes = <(String, String)>[
      ('Código', product.sku),
      ('Material', product.material),
      ('Índice', product.indexLabel),
      ('Tratamiento', product.treatment),
    ].where((attribute) => attribute.$2.isNotEmpty).toList();

    if (attributes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          for (final (label, value) in attributes)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Selector de cantidad, limitado por las unidades disponibles
  Widget _buildQuantityControl(int quantity, int? available) {
    final canIncrement = available == null || quantity < available;

    return Row(
      children: [
        const Text(
          'Cantidad',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline, size: 30),
          color: Colors.blue.shade700,
          tooltip: 'Restar una unidad',
          onPressed: quantity > 1
              ? () => setState(() => _quantity = quantity - 1)
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '$quantity',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 30),
          color: Colors.blue.shade700,
          tooltip: 'Sumar una unidad',
          onPressed: canIncrement
              ? () => setState(() => _quantity = quantity + 1)
              : null,
        ),
      ],
    );
  }
}
