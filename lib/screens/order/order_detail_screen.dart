import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/detail_row.dart';
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
      appBar: AppBar(title: Text('Pedido #${order.shortId}')),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 16),
            _buildItemsCard(),
          ],
        ),
      ),
    );
  }

  // Tarjeta con óptica, fecha, número y estado
  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información del pedido',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            if (showCustomer) ...[
              DetailRow.text(
                label: 'Óptica:',
                icon: Icons.storefront_outlined,
                value: order.customerName,
              ),
              if (order.userEmail.isNotEmpty &&
                  order.userEmail != order.customerName)
                DetailRow(
                  label: 'Correo:',
                  icon: Icons.mail_outline,
                  // Un correo largo se reduce un poco en vez de partirse.
                  value: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      order.userEmail,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
            DetailRow.text(
              label: 'Fecha:',
              icon: Icons.calendar_today_outlined,
              value: formatOrderDate(order.orderDate),
            ),
            DetailRow.text(
              label: 'Número:',
              icon: Icons.tag,
              value: order.shortId,
            ),
            DetailRow.text(
              label: 'Unidades:',
              icon: Icons.inventory_2_outlined,
              value: '${order.totalUnits}',
            ),
            DetailRow(
              label: 'Estado:',
              icon: Icons.flag_outlined,
              value: OrderStatusChip(status: order.status),
            ),
          ],
        ),
      ),
    );
  }

  // Tarjeta con los productos del pedido y el total
  Widget _buildItemsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos solicitados (${order.items.length})',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            for (final item in order.items) ...[
              _buildItemRow(item),
              const Divider(),
            ],
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.muted,
                    ),
                  ),
                ),
                Text(
                  formatCurrency(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Fila de un producto del pedido
  Widget _buildItemRow(OrderedItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ProductImage(
              url: item.imageUrl,
              width: 48,
              height: 48,
              iconSize: 22,
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
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${formatCurrency(item.price)} x ${item.quantity} '
                  '${item.quantity == 1 ? 'unidad' : 'unidades'}',
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatCurrency(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ],
      ),
    );
  }
}
