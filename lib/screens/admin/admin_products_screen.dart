import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/max_width.dart';
import 'product_form_screen.dart';

/// Catálogo completo para el distribuidor: buscar, crear y editar productos.
class AdminProductsScreen extends StatefulWidget {
  /// Botones adicionales junto al de "Nuevo" (p. ej. carga desde Excel).
  final List<Widget> actions;

  const AdminProductsScreen({this.actions = const [], super.key});

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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No se pudo cargar el catálogo. Revisa tu conexión e '
                'inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
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
                    ? Center(
                        child: Text(
                          products.isEmpty
                              ? 'Aún no hay productos. Crea uno o cárgalos '
                                    'desde un Excel.'
                              : 'Ningún producto coincide con la búsqueda.',
                          style: const TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: visible.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) =>
                            _buildTile(visible[index]),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Buscar por nombre o código ($total productos)',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: _openForm,
                icon: const Icon(Icons.add),
                label: const Text('Nuevo producto'),
              ),
              ...widget.actions,
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
      title: Text(
        product.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: product.active ? null : Colors.grey,
        ),
      ),
      subtitle: Text(
        product.active ? details : '$details · Inactivo',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            formatCurrency(product.price),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(
            product.stock == null ? 'Sin control' : 'Stock: ${product.stock}',
            style: TextStyle(
              fontSize: 12,
              color: product.isOutOfStock ? Colors.red.shade700 : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
