import 'package:flutter/material.dart';

import '../models/app_user.dart';

/// Formulario con los datos de una óptica.
///
/// Con [withCredentials] pide además correo y contraseña (registro). Sin él,
/// solo los datos del perfil (cuentas que ya existen pero no tienen perfil).
class ProfileForm extends StatefulWidget {
  final bool withCredentials;
  final String submitLabel;
  final bool isSubmitting;
  final String? errorMessage;

  /// Se llama con los datos ya validados. `email` y `password` van vacíos si
  /// [withCredentials] es `false`.
  final void Function(ProfileData profile, String email, String password)
  onSubmit;

  const ProfileForm({
    required this.onSubmit,
    required this.submitLabel,
    this.withCredentials = false,
    this.isSubmitting = false,
    this.errorMessage,
    super.key,
  });

  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessName = TextEditingController();
  final _ruc = TextEditingController();
  final _contactName = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _businessName,
      _ruc,
      _contactName,
      _phone,
      _address,
      _email,
      _password,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    widget.onSubmit(
      ProfileData(
        businessName: _businessName.text.trim(),
        ruc: _ruc.text.trim(),
        contactName: _contactName.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
      ),
      _email.text.trim(),
      _password.text,
    );
  }

  static String? _required(String? value) {
    return (value == null || value.trim().isEmpty) ? 'Campo obligatorio' : null;
  }

  static String? _validateRuc(String? value) {
    final ruc = value?.trim() ?? '';
    if (ruc.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^\d{13}$').hasMatch(ruc)) {
      return 'El RUC debe tener 13 dígitos';
    }
    return null;
  }

  static String? _validatePhone(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return 'Campo obligatorio';
    if (digits.length < 7) return 'Teléfono incompleto';
    return null;
  }

  static String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Campo obligatorio';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Correo no válido';
    }
    return null;
  }

  static String? _validatePassword(String? value) {
    if ((value ?? '').length < 6) return 'Mínimo 6 caracteres';
    return null;
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    required String? Function(String?) validator,
    IconData? icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Iterable<String>? autofillHints,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        obscureText: obscureText,
        autofillHints: autofillHints,
        textCapitalization: textCapitalization,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            'Razón social',
            _businessName,
            validator: _required,
            icon: Icons.storefront,
            textCapitalization: TextCapitalization.words,
          ),
          _field(
            'RUC',
            _ruc,
            validator: _validateRuc,
            icon: Icons.badge_outlined,
            keyboardType: TextInputType.number,
          ),
          _field(
            'Persona de contacto',
            _contactName,
            validator: _required,
            icon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
          ),
          _field(
            'Teléfono',
            _phone,
            validator: _validatePhone,
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          _field(
            'Dirección',
            _address,
            validator: _required,
            icon: Icons.place_outlined,
            textCapitalization: TextCapitalization.sentences,
          ),
          if (widget.withCredentials) ...[
            _field(
              'Correo electrónico',
              _email,
              validator: _validateEmail,
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
            ),
            _field(
              'Contraseña',
              _password,
              validator: _validatePassword,
              icon: Icons.lock_outline,
              obscureText: true,
              autofillHints: const [AutofillHints.newPassword],
            ),
          ],
          if (widget.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                widget.errorMessage!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: widget.isSubmitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    widget.submitLabel,
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ],
      ),
    );
  }
}
