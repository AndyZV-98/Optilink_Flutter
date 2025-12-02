import 'package:flutter/material.dart';
import 'package:optilink_app/screens/order/cart_screen.dart';
import 'package:optilink_app/screens/order/order_history_screen.dart';
import 'package:provider/provider.dart';
// Uso de importaciones de paquete para mayor estabilidad
import 'package:optilink_app/providers/cart_provider.dart';
import 'package:optilink_app/models/product.dart';
// import '../cart_screen.dart'; // Asumiendo que CartScreen está en lib/screens/
// import '../order_history_screen.dart'; // Asumiendo que OrderHistoryScreen está en lib/screens/

class ProductListScreen extends StatelessWidget {
  // Se remueve 'const' del constructor de la clase debido a que la lista de productos no es constante
  ProductListScreen({super.key});

  // Lista de productos simulada (AHORA SIN 'const' y con todos los campos requeridos)
  final List<Product> _dummyProducts = [
    Product(
      id: 'p1',
      name: 'Zapatillas Urbanas',
      category: 'Calzado',
      description: 'Zapatillas cómodas para el día a día.',
      price: 59.99,
      stock: 50,
      imageUrl: 'https://placehold.co/600x400/0047AB/white?text=Zapatillas',
      isFeatured: true,
    ),
    Product(
      id: 'p2',
      name: 'Camiseta Deportiva',
      category: 'Ropa',
      description: 'Hecha con material transpirable, ideal para ejercicio.',
      price: 29.99,
      stock: 120,
      imageUrl: 'https://placehold.co/600x400/FF5733/white?text=Camiseta',
      isFeatured: false,
    ),
    Product(
      id: 'p3',
      name: 'Pantalón Cargo',
      category: 'Ropa',
      description: 'Pantalón resistente con múltiples bolsillos.',
      price: 79.99,
      stock: 30,
      imageUrl: 'https://placehold.co/600x400/2ECC71/white?text=Pantalón',
      isFeatured: true,
    ),
    Product(
      id: 'p4',
      name: 'Reloj Inteligente',
      category: 'Accesorios',
      description: 'Monitorea tu actividad física y sueño.',
      price: 149.99,
      stock: 75,
      imageUrl: 'https://placehold.co/600x400/8E44AD/white?text=Reloj',
      isFeatured: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Escucha del CartProvider se mantiene igual
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Catálogo de Productos',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.teal,
        actions: [
          // Botón para ir al Historial de Pedidos (NUEVO)
          IconButton(
            icon: const Icon(Icons.history, color: Colors.white),
            tooltip: 'Historial de Pedidos',
            onPressed: () {
              // Asumiendo que OrderHistoryScreen es una clase existente
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const OrderHistoryScreen(),
                ),
              );
            },
          ),
          // Botón para ir al Carrito (EXISTENTE)
          Consumer<CartProvider>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              child: IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  // Asumiendo que CartScreen es una clase existente
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _dummyProducts.length,
        itemBuilder: (ctx, i) {
          return ProductItem(product: _dummyProducts[i]);
        },
      ),
    );
  }
}

// Widget simple para mostrar un producto
class ProductItem extends StatelessWidget {
  final Product product;
  const ProductItem({required this.product, super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: ListTile(
        leading: Image.network(
          product.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '\$${product.price.toStringAsFixed(2)}\nStock: ${product.stock}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart, color: Colors.teal),
          onPressed: () {
            cartProvider.addItem(product);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${product.name} añadido al carrito.')),
            );
          },
        ),
      ),
    );
  }
}
