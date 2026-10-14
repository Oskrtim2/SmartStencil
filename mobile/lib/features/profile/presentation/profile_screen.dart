import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    final isArtist = user?.isArtist ?? false;
    final roleColor = isArtist ? const Color(0xFF8B5CF6) : const Color(0xFF06B6D4);
    final roleLabel = isArtist ? 'Tatuador / Artista' : 'Cliente';
    final roleIcon = isArtist ? Icons.palette_rounded : Icons.person_rounded;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de Cuenta'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            // User Avatar & Header
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [roleColor, roleColor.withValues(alpha: 0.6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: roleColor.withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (user?.displayName.isNotEmpty == true ? user!.displayName[0] : 'U').toUpperCase(),
                        style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF14141F),
                      shape: BoxShape.circle,
                      border: Border.all(color: roleColor, width: 2),
                    ),
                    child: Icon(roleIcon, size: 16, color: roleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Name & Email
            Text(
              user?.displayName ?? 'Usuario InkSight',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 4),
            Text(
              user?.email ?? 'correo@inksight.app',
              style: const TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),

            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: roleColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: roleColor.withValues(alpha: 0.5)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(roleIcon, size: 16, color: roleColor),
                  const SizedBox(width: 6),
                  Text(
                    'Cuenta: $roleLabel',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: roleColor),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Account Information Card
            _buildCard(
              title: 'Datos de la Cuenta',
              children: [
                _buildInfoRow('ID de Usuario', user?.userId ?? 'usr_local'),
                const Divider(color: Color(0xFF1E293B)),
                _buildInfoRow('Estado', 'Activo en Base de Datos', valueColor: const Color(0xFF10B981)),
                const Divider(color: Color(0xFF1E293B)),
                _buildInfoRow('Tipo de Acceso', isArtist ? 'Catálogo & Generación' : 'Visualización AR'),
                const Divider(color: Color(0xFF1E293B)),
                _buildInfoRow('Regla de Contraseña', 'Mín. 6 y Máx. 15 caracteres', valueColor: const Color(0xFFA78BFA)),
              ],
            ),
            const SizedBox(height: 18),

            // Permissions / Features according to role
            _buildCard(
              title: isArtist ? 'Funciones de Tatuador' : 'Funciones de Cliente',
              children: [
                _buildFeatureRow(
                  icon: Icons.auto_awesome_rounded,
                  title: 'Generador de Stencils con IA',
                  desc: 'Creación de stencils vectoriales y predicción anatómica.',
                  color: const Color(0xFF8B5CF6),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: Icons.view_in_ar_rounded,
                  title: 'Visor de Realidad Aumentada',
                  desc: 'Proyección sobre piel con shader multiply-blend y mapeo curvo.',
                  color: const Color(0xFF06B6D4),
                ),
                const SizedBox(height: 12),
                _buildFeatureRow(
                  icon: isArtist ? Icons.qr_code_2_rounded : Icons.qr_code_scanner_rounded,
                  title: isArtist ? 'Generación de QR para Clientes' : 'Escáner de Diseños QR',
                  desc: isArtist ? 'Comparte stencils mediante tokens temporales y QR.' : 'Escanea el código de tu artista para probarlo en tu piel.',
                  color: const Color(0xFF10B981),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Logout Button
            OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFFEF4444)),
              label: const Text(
                'Cerrar Sesión',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFEF4444)),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFEF4444), width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFFEF4444).withValues(alpha: 0.08),
              ),
              onPressed: () => _confirmLogout(context, ref),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF14141F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF1E293B)),
        ),
        title: const Text('¿Cerrar Sesión?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: const Text(
          'Se cerrará tu sesión activa y se requerirá iniciar sesión nuevamente para acceder a la app.',
          style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text('Sí, Cerrar Sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF14141F),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8))),
          Text(
            value,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFFE2E8F0)),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String desc,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }
}
