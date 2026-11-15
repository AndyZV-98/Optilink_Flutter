import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/pill.dart';
import '../../widgets/product_image.dart';
import 'product_detail_screen.dart';

/// Catálogo de productos del distribuidor, en tiempo real, con buscador y
/// filtro por tipo de luna.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final Stream<List<Product>> _products;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  /// Tipo de luna elegido; `null` muestra todos.
  String? _type;

  @override
  void initState() {
    super.initState();
    _products = context.read<FirestoreService>().getProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

        if (products.isEmpty) {
          return const EmptyState(
            icon: Icons.grid_view_outlined,
            title: 'No hay productos disponibles.',
          );
        }

        final types = products.map((p) => p.category).toSet().toList()..sort();
        // Si el tipo elegido ya no existe en el catálogo, se ignora.
        final type = types.contains(_type) ? _type : null;
        final visible = products
            .where((p) => type == null || p.category == type)
            .where((p) => p.matches(_query))
            .toList();

        return Column(
          children: [
            _buildSearchBar(),
            if (types.length > 1) _buildTypeFilter(types, type),
            Expanded(
              child: visible.isEmpty
                  ? const EmptyState(
                      icon: Icons.search_off,
                      title: 'Ningún producto coincide con la búsqueda.',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      // Dos columnas en un teléfono; más en tablet o web.
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 230,
                            crossAxisSpacing: 12.0,
                            mainAxisSpacing: 12.0,
                            childAspectRatio: 0.76,
                          ),
                      itemCount: visible.length,
                      itemBuilder: (context, index) =>
                          ProductCard(product: visible[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _query = value),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: 'Borrar búsqueda',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(List<String> types, String? selected) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final type in <String?>[null, ...types])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ChoiceChip(
                  label: Text(type ?? 'Todos'),
                  selected: selected == type,
                  onSelected: (_) => setState(() => _type = type),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de un producto en el catálogo.
class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ProductImage(url: product.imageUrl),
                  if (product.isOutOfStock)
                    const Positioned(
                      top: 10,
                      left: 10,
                      child: Pill(
                        text: 'Agotado',
                        color: AppColors.danger,
                        background: AppColors.dangerSoft,
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    [
                      if (product.sku.isNotEmpty) product.sku,
                      product.category,
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Alto fijo de dos líneas, para que todas las tarjetas
                  // queden alineadas.
                  SizedBox(
                    height: 36,
                    child: Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatCurrency(product.price),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
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
