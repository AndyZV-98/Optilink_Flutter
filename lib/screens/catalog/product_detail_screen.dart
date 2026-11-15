import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/bottom_action_bar.dart';
import '../../widgets/detail_row.dart';
import '../../widgets/max_width.dart';
import '../../widgets/pill.dart';
import '../../widgets/product_image.dart';
import '../../widgets/quantity_stepper.dart';

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
        backgroundColor: AppColors.success,
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
      appBar: AppBar(title: const Text('Detalle')),
      body: MaxWidth(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: ProductImage(
                  url: product.imageUrl,
                  width: double.infinity,
                  height: 220,
                  iconSize: 56,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Pill(
                    text: product.category,
                    color: AppColors.primary,
                    background: AppColors.primarySoft,
                  ),
                  if (product.stock != null)
                    product.isOutOfStock
                        ? const Pill(
                            text: 'Agotado',
                            color: AppColors.danger,
                            background: AppColors.dangerSoft,
                          )
                        : Pill(
                            text: 'Disponibles: ${product.stock}',
                            color: AppColors.success,
                            background: AppColors.successSoft,
                          ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                formatCurrency(product.price),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.8,
                ),
              ),
              if (inCart > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'Ya tienes $inCart en el carrito.',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              _buildAttributes(product),
              if (product.description.isNotEmpty) ...[
                const Text(
                  'Descripción:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  product.description,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),

      // Barra fija con el selector de cantidad y el botón de añadir.
      bottomNavigationBar: BottomActionBar(
        child: canAdd
            ? Row(
                children: [
                  QuantityStepper(
                    quantity: quantity,
                    onDecrement: quantity > 1
                        ? () => setState(() => _quantity = quantity - 1)
                        : null,
                    onIncrement: available == null || quantity < available
                        ? () => setState(() => _quantity = quantity + 1)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addToCart(cartProvider, quantity),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: const Text('Añadir al Carrito'),
                    ),
                  ),
                ],
              )
            : const SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: null,
                  child: Text('Sin unidades disponibles'),
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
      padding: const EdgeInsets.only(bottom: 20),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (var i = 0; i < attributes.length; i++) ...[
                if (i > 0) const Divider(),
                DetailRow.text(
                  label: attributes[i].$1,
                  value: attributes[i].$2,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
