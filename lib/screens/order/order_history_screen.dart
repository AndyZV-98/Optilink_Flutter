import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/max_width.dart';
import '../../widgets/order_status_chip.dart';
import 'order_detail_screen.dart';

/// Lista de pedidos del usuario, del más reciente al más antiguo.
class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  late final Stream<List<Order>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = context.read<FirestoreService>().getUserOrders();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Order>>(
      stream: _orders,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return const EmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'No se pudieron cargar tus pedidos.',
            subtitle: 'Revisa tu conexión e inténtalo de nuevo.',
          );
        }

        final orders = snapshot.data ?? const <Order>[];

        if (orders.isEmpty) {
          return const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Aún no tienes pedidos registrados.',
            subtitle: 'Cuando confirmes un pedido aparecerá aquí.',
          );
        }

        return MaxWidth(
          child: ListView.separated(
            padding: const EdgeInsets.all(16.0),
            itemCount: orders.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) => OrderCard(order: orders[index]),
          ),
        );
      },
    );
  }
}

/// Tarjeta con el resumen de un pedido.
class OrderCard extends StatelessWidget {
  final Order order;

  const OrderCard({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDetailScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Número de pedido y estado
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #${order.shortId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                formatOrderDate(order.orderDate),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Divider(),
              ),

              // Resumen de los primeros 3 ítems
              ...order.items
                  .take(3)
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '${item.quantity} x ${item.name}',
                        style: const TextStyle(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

              if (order.items.length > 3)
                Text(
                  '+ ${order.items.length - 3} productos más',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),

              const SizedBox(height: 10),

              // Total del pedido
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Total:',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ),
                  Text(
                    formatCurrency(order.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      letterSpacing: -0.3,
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
