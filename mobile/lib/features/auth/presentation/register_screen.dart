import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'CLIENT'; // 'CLIENT' or 'ARTIST'
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).register(
      displayName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      role: _selectedRole,
    );

    if (success && mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            authState.errorMessage!,
                            style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Role Selector Section
                const Text(
                  'Tipo de Cuenta',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildRoleCard(
                        role: 'CLIENT',
                        title: 'Cliente',
                        subtitle: 'Visualizar tatuajes en piel con AR y generar ideas',
                        icon: Icons.person_rounded,
                        accentColor: const Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildRoleCard(
                        role: 'ARTIST',
                        title: 'Tatuador',
                        subtitle: 'Estudio de stencils, compartir QR y catálogo',
                        icon: Icons.palette_rounded,
                        accentColor: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Name Field
                const Text(
                  'Nombre o Estudio',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration(
                    hint: 'ej. Alex Rivera',
                    icon: Icons.badge_outlined,
                  ),
                  validator: (val) {
                    if (val == null || val.trim().length < 2) {
                      return 'Ingresa al menos 2 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Field
                const Text(
                  'Correo Electrónico',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration(
                    hint: 'ej. usuario@inksight.app',
                    icon: Icons.alternate_email_rounded,
                  ),
                  validator: (val) {
                    if (val == null || !val.contains('@') || !val.contains('.')) {
                      return 'Ingresa un correo electrónico válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Password Field
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Contraseña',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFCBD5E1)),
                    ),
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _passwordController,
                      builder: (context, value, _) {
                        final len = value.text.length;
                        final isOk = len >= 6 && len <= 15;
                        return Text(
                          '$len/15 caracteres (mín. 6)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isOk ? const Color(0xFF10B981) : const Color(0xFFA78BFA),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: _inputDecoration(
                    hint: 'Entre 6 y 15 caracteres',
                    icon: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: const Color(0xFF94A3B8),
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: AuthNotifier.validatePassword,
                ),
                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Text(
                          'Crear Cuenta y Comenzar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required String role,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _selectedRole == role;

    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : const Color(0xFF14141F),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? accentColor : const Color(0xFF1E293B),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: isSelected ? accentColor : const Color(0xFF94A3B8), size: 24),
                const Spacer(),
                if (isSelected)
                  Icon(Icons.check_circle_rounded, color: accentColor, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF14141F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF1E293B)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5),
      ),
    );
  }
}
