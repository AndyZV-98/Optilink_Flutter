import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
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

        if (products.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
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
                  ? const Center(
                      child: Text('Ningún producto coincide con la búsqueda.'),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(12.0),
                      // Dos columnas en un teléfono; más en tablet o web.
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 240,
                            crossAxisSpacing: 10.0,
                            mainAxisSpacing: 10.0,
                            childAspectRatio: 0.7,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
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
                  icon: const Icon(Icons.clear),
                  tooltip: 'Borrar búsqueda',
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
          isDense: true,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildTypeFilter(List<String> types, String? selected) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
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
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
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
            Expanded(child: ProductImage(url: product.imageUrl)),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (product.sku.isNotEmpty)
                    Text(
                      product.sku,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatCurrency(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.green.shade700,
                    ),
                  ),
                  if (product.isOutOfStock)
                    Text(
                      'Agotado',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
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
