import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/max_width.dart';
import 'data_transfer_screen.dart';
import 'product_form_screen.dart';

/// Catálogo completo para el distribuidor: buscar, crear y editar productos.
class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  late final Stream<List<Product>> _products;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _products = context.read<FirestoreService>().getProducts(
      includeInactive: true,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm([Product? product]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Product>>(
      stream: _products,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudo cargar el catálogo.',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          );
        }

        final products = snapshot.data ?? const <Product>[];
        final visible = products.where((p) => p.matches(_query)).toList();

        return MaxWidth(
          child: Column(
            children: [
              _buildToolbar(products.length),
              Expanded(
                child: visible.isEmpty
                    ? EmptyState(
                        icon: products.isEmpty
                            ? Icons.inventory_2_outlined
                            : Icons.search_off,
                        title: products.isEmpty
                            ? 'Aún no hay productos.'
                            : 'Ningún producto coincide con la búsqueda.',
                        subtitle: products.isEmpty
                            ? 'Crea uno o cárgalos desde un Excel.'
                            : null,
                      )
                    // Lista dentro de una tarjeta que ocupa solo el alto de
                    // sus filas; las filas se construyen al desplazarse.
                    : Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          child: Card(
                            child: ListView.separated(
                              shrinkWrap: true,
                              itemCount: visible.length,
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              itemBuilder: (context, index) =>
                                  _buildTile(visible[index]),
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Buscador y botones de acción
  Widget _buildToolbar(int total) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código ($total productos)',
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DataTransferScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.table_view),
                label: const Text('Cargar / descargar Excel'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(Product product) {
    final details = [
      if (product.sku.isNotEmpty) product.sku,
      product.category,
      if (product.material.isNotEmpty) product.material,
      if (product.index != null) product.indexLabel,
    ].join(' · ');

    return ListTile(
      onTap: () => _openForm(product),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: product.active ? AppColors.ink : AppColors.muted,
        ),
      ),
      subtitle: Text(
        product.active ? details : '$details · Inactivo',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13, color: AppColors.muted),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatCurrency(product.price),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            product.stock == null ? 'Sin control' : 'Stock: ${product.stock}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: product.isOutOfStock ? AppColors.danger : AppColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}
