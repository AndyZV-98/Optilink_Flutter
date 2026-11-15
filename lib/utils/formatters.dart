import 'package:intl/intl.dart';

/// Locale de los textos y fechas de la app.
///
/// El paquete `intl` no incluye datos específicos de Ecuador (`es_EC`), así
/// que se usa español genérico y el formato de moneda se define aquí.
const String appLocale = 'es';

/// Formatea un monto en dólares con el formato usado en Ecuador:
/// símbolo delante, punto para miles y coma para decimales (`$1.234,50`).
String formatCurrency(num amount) {
  return NumberFormat.currency(
    locale: appLocale,
    symbol: r'$',
    decimalDigits: 2,
    customPattern: '¤#,##0.00',
  ).format(amount);
}

/// Fecha y hora de un pedido, p. ej. `05 mar 2026, 14:30`.
///
/// Requiere haber llamado antes a `initializeDateFormatting(appLocale)`.
String formatOrderDate(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm', appLocale).format(date);
}

/// Convierte un número escrito con coma o punto decimal (`12,5` o `12.5`).
/// Devuelve `null` si el texto no es un número.
double? parseDecimal(String text) {
  return double.tryParse(text.trim().replaceAll(',', '.'));
}
