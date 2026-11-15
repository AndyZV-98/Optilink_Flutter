import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/order.dart';
import '../../services/firestore_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/max_width.dart';
import '../../widgets/order_status_chip.dart';
import '../order/order_detail_screen.dart';

/// Pedidos de todas las ópticas, con filtro por estado.
class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  late final Stream<List<Order>> _orders;

  /// Estado elegido en el filtro; `null` muestra todos.
  String? _status;

  @override
  void initState() {
    super.initState();
    _orders = context.read<FirestoreService>().watchAllOrders();
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
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'No se pudieron cargar los pedidos. Revisa tu conexión e '
                'inténtalo de nuevo.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final orders = snapshot.data ?? const <Order>[];
        final visible = orders
            .where((order) => _status == null || order.status == _status)
            .toList();

        return Column(
          children: [
            _buildStatusFilter(orders),
            Expanded(
              child: visible.isEmpty
                  ? Center(
                      child: Text(
                        _status == null
                            ? 'Aún no hay pedidos.'
                            : 'No hay pedidos en estado "$_status".',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : MaxWidth(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8.0),
                        itemCount: visible.length,
                        itemBuilder: (context, index) =>
                            AdminOrderCard(order: visible[index]),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  // Filtro por estado, con la cantidad de pedidos en cada uno
  Widget _buildStatusFilter(List<Order> orders) {
    int count(String status) =>
        orders.where((order) => order.status == status).length;

    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          for (final status in <String?>[null, ...orderStatuses])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: ChoiceChip(
                  label: Text(
                    status == null
                        ? 'Todos (${orders.length})'
                        : '$status (${count(status)})',
                  ),
                  selected: _status == status,
                  onSelected: (_) => setState(() => _status = status),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Tarjeta de un pedido en la lista del distribuidor.
class AdminOrderCard extends StatelessWidget {
  final Order order;

  const AdminOrderCard({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdminOrderDetailScreen(orderId: order.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.customerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OrderStatusChip(status: order.status),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Pedido #${order.shortId} · ${formatOrderDate(order.orderDate)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${order.totalUnits} '
                      '${order.totalUnits == 1 ? 'unidad' : 'unidades'} · '
                      '${order.items.length} '
                      '${order.items.length == 1 ? 'producto' : 'productos'}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  ),
                  Text(
                    formatCurrency(order.totalAmount),
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
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

/// Detalle de un pedido para el distribuidor, con los botones para cambiar
/// su estado. Se actualiza en tiempo real.
class AdminOrderDetailScreen extends StatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({required this.orderId, super.key});

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  late final Stream<Order?> _order;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _order = context.read<FirestoreService>().watchOrder(widget.orderId);
  }

  /// Texto del botón que lleva un pedido a [status].
  static String _actionLabel(String status) {
    switch (status) {
      case orderStatusApproved:
        return 'Aprobar pedido';
      case orderStatusShipped:
        return 'Marcar como enviado';
      case orderStatusDelivered:
        return 'Marcar como entregado';
      default:
        return 'Cancelar pedido';
    }
  }

  Future<void> _changeStatus(Order order, String status) async {
    final service = context.read<FirestoreService>();
    final messenger = ScaffoldMessenger.of(context);

    if (status == orderStatusCancelled) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('¿Cancelar el pedido?'),
          content: Text(
            order.stockDeducted
                ? 'El stock descontado al aprobarlo volverá al catálogo. '
                      'Esta acción no se puede deshacer.'
                : 'Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sí, cancelar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    setState(() => _isUpdating = true);
    String message;
    var failed = false;
    try {
      await service.updateOrderStatus(order.id, status);
      message = 'Pedido #${order.shortId}: $status.';
    } on InsufficientStockException catch (e) {
      failed = true;
      message =
          'No se puede aprobar: de "${e.productName}" se pidieron '
          '${e.requested} y solo hay ${e.available}.';
    } catch (_) {
      failed = true;
      message = 'No se pudo cambiar el estado. Inténtalo de nuevo.';
    }

    if (mounted) setState(() => _isUpdating = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: failed ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Order?>(
      stream: _order,
      builder: (context, snapshot) {
        final order = snapshot.data;

        return Scaffold(
          appBar: AppBar(
            title: Text(order == null ? 'Pedido' : 'Pedido #${order.shortId}'),
          ),
          body: order == null
              ? Center(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? const CircularProgressIndicator()
                      : const Text('No se pudo cargar el pedido.'),
                )
              : OrderDetailBody(order: order, showCustomer: true),
          bottomNavigationBar: order == null
              ? null
              : _buildActions(order, nextOrderStatuses(order.status)),
        );
      },
    );
  }

  // Botones para pasar el pedido a su siguiente estado o cancelarlo
  Widget? _buildActions(Order order, List<String> nextStatuses) {
    if (nextStatuses.isEmpty) return null;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: MaxWidth(
          fitHeight: true,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final status in nextStatuses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: status == orderStatusCancelled
                      ? OutlinedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _changeStatus(order, status),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            minimumSize: const Size(double.infinity, 46),
                          ),
                          child: Text(_actionLabel(status)),
                        )
                      : ElevatedButton(
                          onPressed: _isUpdating
                              ? null
                              : () => _changeStatus(order, status),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: Text(
                            _actionLabel(status),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
