import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:optilink_app/utils/formatters.dart';

void main() {
  test('formatea montos en dólares con dos decimales', () {
    expect(formatCurrency(12.5), r'$12,50');
    expect(formatCurrency(0), r'$0,00');
    expect(formatCurrency(1234.567), r'$1.234,57');
    expect(formatCurrency(1250000), r'$1.250.000,00');
  });

  test('formatea fechas en español', () async {
    await initializeDateFormatting(appLocale);

    expect(formatOrderDate(DateTime(2026, 3, 5, 14, 30)), '05 mar 2026, 14:30');
  });
}
