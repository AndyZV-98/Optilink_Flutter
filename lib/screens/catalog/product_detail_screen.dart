// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import '../../models/product.dart';
// import '../../providers/cart_provider.dart';

// // Pantalla para mostrar el detalle de un producto y agregarlo al carrito.
// class ProductDetailScreen extends StatefulWidget {
//   final Product product;

//   const ProductDetailScreen({required this.product, super.key});

//   @override
//   State<ProductDetailScreen> createState() => _ProductDetailScreenState();
// }

// class _ProductDetailScreenState extends State<ProductDetailScreen> {
//   int _quantity = 1; // Cantidad seleccionada para agregar al carrito

//   // Método para construir la fila de control de cantidad
//   Widget _buildQuantityControl() {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         // Botón para decrementar la cantidad
//         IconButton(
//           icon: Icon(
//             Icons.remove_circle_outline,
//             color: Colors.blue.shade700,
//             size: 30,
//           ),
//           onPressed: _quantity > 1
//               ? () {
//                   setState(() {
//                     _quantity--;
//                   });
//                 }
//               : null, // Desactivar si la cantidad es 1
//         ),

//         // Muestra la cantidad actual
//         Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16.0),
//           child: Text(
//             '$_quantity',
//             style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//           ),
//         ),

//         // Botón para incrementar la cantidad
//         IconButton(
//           icon: Icon(
//             Icons.add_circle_outline,
//             color: Colors.blue.shade700,
//             size: 30,
//           ),
//           onPressed: () {
//             setState(() {
//               _quantity++;
//             });
//           },
//         ),
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currencyFormatter = NumberFormat.currency(
//       locale: 'es_CL',
//       symbol: '\$',
//     );
//     final cartProvider = Provider.of<CartProvider>(context, listen: false);

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Detalle', style: TextStyle(color: Colors.white)),
//         backgroundColor: Colors.blue.shade700,
//         iconTheme: const IconThemeData(color: Colors.white),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // --- Imagen del Producto ---
//                   ClipRRect(
//                     borderRadius: BorderRadius.circular(16),
//                     child: Image.network(
//                       widget.product.imageUrl,
//                       width: double.infinity,
//                       height: 250,
//                       fit: BoxFit.cover,
//                       errorBuilder: (context, error, stackTrace) => Container(
//                         width: double.infinity,
//                         height: 250,
//                         color: Colors.grey.shade300,
//                         child: const Center(
//                           child: Icon(
//                             Icons.image_not_supported,
//                             size: 50,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 20),

//                   // --- Nombre del Producto ---
//                   Text(
//                     widget.product.name,
//                     style: TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.blue.shade900,
//                     ),
//                   ),
//                   const SizedBox(height: 10),

//                   // --- Precio ---
//                   Text(
//                     currencyFormatter.format(widget.product.price),
//                     style: TextStyle(
//                       fontSize: 32,
//                       fontWeight: FontWeight.w900,
//                       color: Colors.green.shade700,
//                     ),
//                   ),
//                   const Divider(height: 30),

//                   // --- Descripción Completa ---
//                   const Text(
//                     'Descripción:',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     widget.product.description,
//                     style: const TextStyle(fontSize: 16, height: 1.5),
//                   ),

//                   // Espacio para la sección de control de cantidad
//                   const SizedBox(height: 40),

//                   // Control de Cantidad
//                   _buildQuantityControl(),
//                   const SizedBox(height: 20),
//                 ],
//               ),
//             ),
//           ),

//           // --- Barra de Botón Flotante para Añadir al Carrito ---
//           Container(
//             padding: const EdgeInsets.all(16.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.1),
//                   spreadRadius: 2,
//                   blurRadius: 5,
//                   offset: const Offset(0, -3),
//                 ),
//               ],
//             ),
//             child: ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.orange,
//                 minimumSize: const Size(double.infinity, 50),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onPressed: () {
//                 // Lógica para añadir al carrito
//                 // CORRECCIÓN APLICADA: Pasamos `_quantity` como un argumento NAMED (nombrado).
//                 cartProvider.addItem(
//                   widget.product,
//                   quantity: _quantity, // <-- ¡Solución al error!
//                 );

//                 // Mostrar un mensaje de éxito
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(
//                     content: Text(
//                       '$_quantity ${widget.product.name} añadido(s) al carrito.',
//                     ),
//                     backgroundColor: Colors.green,
//                     duration: const Duration(seconds: 2),
//                   ),
//                 );
//               },
//               child: const Text(
//                 'Añadir al Carrito',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';

// Pantalla para mostrar el detalle de un producto y agregarlo al carrito.
class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({required this.product, super.key});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1; // Cantidad seleccionada para agregar al carrito

  // Método para construir la fila de control de cantidad
  Widget _buildQuantityControl() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Botón para decrementar la cantidad
        IconButton(
          icon: Icon(
            Icons.remove_circle_outline,
            color: Colors.blue.shade700,
            size: 30,
          ),
          onPressed: _quantity > 1
              ? () {
                  setState(() {
                    _quantity--;
                  });
                }
              : null, // Desactivar si la cantidad es 1
        ),

        // Muestra la cantidad actual
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '$_quantity',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        // Botón para incrementar la cantidad
        IconButton(
          icon: Icon(
            Icons.add_circle_outline,
            color: Colors.blue.shade700,
            size: 30,
          ),
          onPressed: () {
            setState(() {
              _quantity++;
            });
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
    );
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Imagen del Producto ---
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      widget.product.imageUrl,
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey.shade300,
                        child: const Center(
                          child: Icon(
                            Icons.image_not_supported,
                            size: 50,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // --- Nombre del Producto ---
                  Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // --- Precio ---
                  Text(
                    currencyFormatter.format(widget.product.price),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.green.shade700,
                    ),
                  ),
                  const Divider(height: 30),

                  // --- Descripción Completa ---
                  const Text(
                    'Descripción:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.product.description,
                    style: const TextStyle(fontSize: 16, height: 1.5),
                  ),

                  // Espacio para la sección de control de cantidad
                  const SizedBox(height: 40),

                  // Control de Cantidad
                  _buildQuantityControl(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // --- Barra de Botón Flotante para Añadir al Carrito ---
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // Lógica para añadir al carrito
                // Ejecutamos addItem tantas veces como indique la cantidad.
                // Esto simula la adición correcta del producto por unidad.
                for (int i = 0; i < _quantity; i++) {
                  cartProvider.addItem(widget.product);
                }

                // Mostrar un mensaje de éxito
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '$_quantity ${widget.product.name} añadido(s) al carrito.',
                    ),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Añadir al Carrito',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
