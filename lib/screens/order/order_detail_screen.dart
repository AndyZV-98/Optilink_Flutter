import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';

// Pantalla para ver el desglose completo de un pedido específico.
class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    // Configuramos los formateadores de moneda y fecha
    final currencyFormatter = NumberFormat.currency(
      locale: 'es_CL',
      symbol: '\$',
    );
    final dateFormatter = DateFormat('dd MMMM yyyy, hh:mm a');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detalle de Pedido #${order.id.substring(0, 8)}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Resumen del Pedido ---
            _buildSummaryCard(dateFormatter, currencyFormatter),

            const SizedBox(height: 20),

            // --- Título de Ítems ---
            Text(
              'Productos Solicitados (${order.items.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const Divider(height: 15, thickness: 2),

            // --- Lista de Ítems del Pedido ---
            ...order.items.map((item) {
              final subtotal = item.productId.price * item.quantity;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Imagen Placeholder/Miniatura
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        item.productId.imageUrl ??
                            'https://via.placeholder.com/50',
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 50,
                          height: 50,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.lens_outlined,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Descripción y Cantidad
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productId.name ?? 'Producto Desconocido',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${currencyFormatter.format(item.productId.price)} x ${item.quantity} unidades',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),

                    // Subtotal
                    Text(
                      currencyFormatter.format(subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            const Divider(height: 15, thickness: 2),

            // --- Total Final ---
            _buildTotalFooter(currencyFormatter),
          ],
        ),
      ),
    );
  }

  // Widget de tarjeta resumen (Fecha y Estado)
  Widget _buildSummaryCard(
    DateFormat dateFormatter,
    NumberFormat currencyFormatter,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del Pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 10),
            _buildDetailRow(
              'Fecha:',
              dateFormatter.format(order.orderDate),
              Icons.calendar_today,
            ),
            _buildDetailRow(
              'ID Corto:',
              order.id.substring(0, 10),
              Icons.confirmation_number,
            ),
            _buildDetailRow(
              'Estado:',
              // Asumimos que el modelo Order debería tener un campo 'status'
              // Como no lo definimos, usamos un valor estático por ahora
              'Pendiente de Aprobación',
              Icons.pending_actions,
              color: Colors.orange.shade700,
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para filas de detalle
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label ', style: const TextStyle(fontWeight: FontWeight.w500)),
          const Expanded(child: SizedBox()),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar el total final
  Widget _buildTotalFooter(NumberFormat currencyFormatter) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'TOTAL FINAL:',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          Text(
            currencyFormatter.format(order.totalAmount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.green.shade800,
            ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String? get imageUrl => null;

  get price => null;

  String? get name => null;
}
