import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/form_message.dart';

/// Formulario para crear un producto o editar uno existente.
class ProductFormScreen extends StatefulWidget {
  /// Producto a editar; `null` para crear uno nuevo.
  final Product? product;

  const ProductFormScreen({this.product, super.key});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sku;
  late final TextEditingController _name;
  late final TextEditingController _type;
  late final TextEditingController _material;
  late final TextEditingController _index;
  late final TextEditingController _treatment;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _imageUrl;
  late bool _active;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _sku = TextEditingController(text: product?.sku ?? '');
    _name = TextEditingController(text: product?.name ?? '');
    _type = TextEditingController(text: product?.category ?? '');
    _material = TextEditingController(text: product?.material ?? '');
    _index = TextEditingController(text: product?.indexLabel ?? '');
    _treatment = TextEditingController(text: product?.treatment ?? '');
    _description = TextEditingController(text: product?.description ?? '');
    _price = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _stock = TextEditingController(text: product?.stock?.toString() ?? '');
    _imageUrl = TextEditingController(text: product?.imageUrl ?? '');
    _active = product?.active ?? true;
  }

  @override
  void dispose() {
    for (final controller in [
      _sku,
      _name,
      _type,
      _material,
      _index,
      _treatment,
      _description,
      _price,
      _stock,
      _imageUrl,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  static String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null;
  }

  static String? _validatePrice(String? value) {
    final price = parseDecimal(value ?? '');
    if (price == null) return 'Escribe un precio, p. ej. 12,50';
    if (price < 0) return 'El precio no puede ser negativo';
    return null;
  }

  static String? _validateIndex(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final index = parseDecimal(text);
    if (index == null || index < 1 || index > 2) {
      return 'Índice entre 1 y 2, p. ej. 1,56';
    }
    return null;
  }

  static String? _validateStock(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return null;
    final stock = int.tryParse(text);
    if (stock == null || stock < 0) return 'Número entero, 0 o mayor';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final original = widget.product;
    final stockText = _stock.text.trim();
    final indexText = _index.text.trim();

    final product = Product(
      id: original?.id ?? '',
      sku: _sku.text.trim(),
      name: _name.text.trim(),
      category: _type.text.trim(),
      material: _material.text.trim(),
      index: indexText.isEmpty ? null : parseDecimal(indexText),
      treatment: _treatment.text.trim(),
      description: _description.text.trim(),
      price: parseDecimal(_price.text)!,
      stock: stockText.isEmpty ? null : int.parse(stockText),
      imageUrl: _imageUrl.text.trim(),
      isFeatured: original?.isFeatured ?? false,
      active: _active,
    );

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await context.read<FirestoreService>().saveProduct(product);
      messenger.showSnackBar(
        SnackBar(
          content: Text('"${product.name}" guardado.'),
          backgroundColor: AppColors.success,
        ),
      );
      navigator.pop();
    } on DuplicateSkuException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage = 'Ya existe otro producto con el código "${e.sku}".';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorMessage =
            'No se pudo guardar. Revisa tu conexión e inténtalo de nuevo.';
      });
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? Function(String?)? validator,
    String? helperText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(labelText: label, helperText: helperText),
      ),
    );
  }

  /// Grupo de campos con título, dentro de una tarjeta.
  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const decimal = TextInputType.numberWithOptions(decimal: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Nuevo producto' : 'Editar producto',
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _section('Identificación', [
                    _field(
                      'Código',
                      _sku,
                      validator: _required,
                      helperText:
                          'Único por producto. Es la clave en el Excel.',
                    ),
                    _field('Nombre', _name, validator: _required),
                    _field(
                      'Tipo',
                      _type,
                      validator: _required,
                      helperText: 'Monofocal, Bifocal, Progresivo…',
                    ),
                  ]),
                  _section('Características', [
                    _field('Material', _material),
                    _field(
                      'Índice',
                      _index,
                      validator: _validateIndex,
                      keyboardType: decimal,
                    ),
                    _field('Tratamiento', _treatment),
                    _field('Descripción', _description, maxLines: 3),
                    _field(
                      'Imagen (URL)',
                      _imageUrl,
                      keyboardType: TextInputType.url,
                    ),
                  ]),
                  _section('Venta', [
                    _field(
                      'Precio (USD)',
                      _price,
                      validator: _validatePrice,
                      keyboardType: decimal,
                    ),
                    _field(
                      'Stock',
                      _stock,
                      validator: _validateStock,
                      keyboardType: TextInputType.number,
                      helperText: 'Vacío: sin control de stock.',
                    ),
                    SwitchListTile(
                      value: _active,
                      onChanged: (value) => setState(() => _active = value),
                      title: const Text('Activo'),
                      subtitle: const Text(
                        'Los productos inactivos no aparecen en el catálogo '
                        'de las ópticas.',
                        style: TextStyle(color: AppColors.muted),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const SizedBox(height: 8),
                  ]),
                  if (_errorMessage != null) ...[
                    FormMessage(text: _errorMessage!),
                    const SizedBox(height: 16),
                  ],
                  FilledButton(
                    onPressed: _isSaving ? null : _save,
                    child: _isSaving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
