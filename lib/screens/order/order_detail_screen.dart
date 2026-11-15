import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../../widgets/max_width.dart';
import '../../widgets/order_status_chip.dart';
import '../../widgets/product_image.dart';

/// Desglose completo de un pedido.
class OrderDetailScreen extends StatelessWidget {
  final Order order;

  const OrderDetailScreen({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pedido #${order.shortId}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: OrderDetailBody(order: order),
    );
  }
}

/// Contenido del detalle de un pedido: resumen, productos y total.
///
/// Con [showCustomer] incluye los datos de la óptica (vista del distribuidor).
class OrderDetailBody extends StatelessWidget {
  final Order order;
  final bool showCustomer;

  const OrderDetailBody({
    required this.order,
    this.showCustomer = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MaxWidth(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),
            Text(
              'Productos solicitados (${order.items.length})',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const Divider(height: 15, thickness: 2),
            ...order.items.map(_buildItemRow),
            const Divider(height: 15, thickness: 2),
            _buildTotalFooter(),
          ],
        ),
      ),
    );
  }

  // Fila de un producto del pedido
  Widget _buildItemRow(OrderedItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: ProductImage(
              url: item.imageUrl,
              width: 50,
              height: 50,
              iconSize: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatCurrency(item.price)} x ${item.quantity} '
                  '${item.quantity == 1 ? 'unidad' : 'unidades'}',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(item.subtotal),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta con fecha, número y estado
  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del pedido',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 10),
            if (showCustomer) ...[
              _buildDetailRow(
                'Óptica:',
                Icons.storefront,
                Text(
                  order.customerName,
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              if (order.userEmail.isNotEmpty &&
                  order.userEmail != order.customerName)
                _buildDetailRow(
                  'Correo:',
                  Icons.email_outlined,
                  Text(
                    order.userEmail,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
            _buildDetailRow(
              'Fecha:',
              Icons.calendar_today,
              Text(
                formatOrderDate(order.orderDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildDetailRow(
              'Número:',
              Icons.confirmation_number,
              Text(
                order.shortId,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildDetailRow(
              'Unidades:',
              Icons.inventory_2_outlined,
              Text(
                '${order.totalUnits}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            _buildDetailRow(
              'Estado:',
              Icons.pending_actions,
              OrderStatusChip(status: order.status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, IconData icon, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 12),
          Expanded(
            child: Align(alignment: Alignment.centerRight, child: value),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalFooter() {
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
            'TOTAL:',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          Text(
            formatCurrency(order.totalAmount),
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
