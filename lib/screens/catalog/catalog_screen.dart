import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Asegúrate de tener esta importación
import '../../models/product.dart';
import '../../services/firestore_service.dart';
import 'product_detail_screen.dart'; // Importamos la pantalla de detalle

// Pantalla principal que muestra el listado de productos
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el servicio de Firestore para acceder a los productos
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    return StreamBuilder<List<Product>>(
      stream: firestoreService.getProducts(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar productos: ${snapshot.error}'),
          );
        }

        final products = snapshot.data;

        if (products == null || products.isEmpty) {
          return const Center(child: Text('No hay productos disponibles.'));
        }

        // Si hay productos, los mostramos en un GridView
        return GridView.builder(
          padding: const EdgeInsets.all(12.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 columnas
            crossAxisSpacing: 10.0,
            mainAxisSpacing: 10.0,
            childAspectRatio:
                0.7, // Relación de aspecto para que las tarjetas no sean demasiado cuadradas
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return ProductCard(product: product);
          },
        );
      },
    );
  }
}

// Widget para la tarjeta individual de un producto
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    // Definimos el formato de moneda (ej: $1.234)
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
    );

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        // Lógica de navegación: al tocar la tarjeta, vamos a la pantalla de detalle
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del Producto
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey.shade300,
                    child: const Center(
                      child: Icon(
                        Icons.image_not_supported,
                        size: 40,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Detalles del Producto
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    currencyFormatter.format(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: Colors.green.shade700,
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
