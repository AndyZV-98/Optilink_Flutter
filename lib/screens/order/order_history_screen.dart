import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../services/firestore_service.dart';
import 'order_detail_screen.dart'; // ¡Importante para la navegación!

// Pantalla que muestra el historial de pedidos del usuario
class OrderHistoryScreen extends StatelessWidget {
  const OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenemos el servicio de Firestore para acceder a los datos de pedidos
    final firestoreService = Provider.of<FirestoreService>(
      context,
      listen: false,
    );

    return StreamBuilder<List<Order>>(
      // Escuchamos los pedidos del usuario en tiempo real
      stream: firestoreService.getUserOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar pedidos: ${snapshot.error}'),
          );
        }

        final orders = snapshot.data;

        if (orders == null || orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history_toggle_off,
                  size: 80,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aún no tienes pedidos registrados.',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        // Si hay pedidos, los mostramos en una lista
        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return OrderCard(order: order);
          },
        );
      },
    );
  }
}

// Widget para mostrar la información resumida de un pedido
class OrderCard extends StatelessWidget {
  final Order order;
  const OrderCard({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    // Formateadores de datos
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
    );
    final dateFormatter = DateFormat('dd MMM yyyy, hh:mm a');

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        // Acción de clic: Navegamos a la pantalla de detalle
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(
                order: order,
              ), // Usamos la pantalla que creamos antes
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ID del Pedido y Fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id.substring(0, 8)}...',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    dateFormatter.format(order.orderDate),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              const Divider(height: 16),

              // Muestra un resumen de los primeros 3 ítems
              ...order.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${item.quantity}x ${item.productId.name}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

              // Indicador si hay más ítems
              if (order.items.length > 3)
                Text(
                  '+ ${order.items.length - 3} ítems más',
                  style: const TextStyle(
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: Colors.blue,
                  ),
                ),

              const SizedBox(height: 12),

              // Total del Pedido
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.blue.shade900,
                    ),
                  ),
                  Text(
                    currencyFormatter.format(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  get name => null;
}
