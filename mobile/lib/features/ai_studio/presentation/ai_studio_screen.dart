import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/providers/auth_provider.dart';

class AiStudioScreen extends ConsumerStatefulWidget {
  const AiStudioScreen({super.key});

  @override
  ConsumerState<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends ConsumerState<AiStudioScreen> {
  final _promptController = TextEditingController(text: 'Dragón oriental fineline con flores de cerezo');
  String _selectedStyle = 'FINE_LINE';
  String _selectedPlacement = 'forearm';
  bool _isGenerating = false;
  String? _statusStep;
  AiStencilResponse? _generatedStencil;
  Uint8List? _stencilImageBytes;
  bool _showDarkBg = true;

  final List<Map<String, String>> _samplePrompts = [
    {'title': '🐉 Dragón Oriental', 'prompt': 'Dragón oriental fineline con escamas detalladas', 'style': 'FINE_LINE', 'placement': 'forearm'},
    {'title': '🐺 Lobo Geométrico', 'prompt': 'Lobo geométrico con polígonos sagrados y líneas nítidas', 'style': 'GEOMETRIC', 'placement': 'biceps'},
    {'title': '🌸 Flor de Loto', 'prompt': 'Flor de loto minimalista con tallo botánico y gotas', 'style': 'MINIMALIST', 'placement': 'wrist'},
    {'title': '⚔️ Daga Cybersigilism', 'prompt': 'Daga gótica con halo astral y símbolos cybersigilism', 'style': 'NEOTRIBAL', 'placement': 'forearm'},
    {'title': '🐍 Serpiente Blackwork', 'prompt': 'Serpiente enrollada con sombreado denso blackwork', 'style': 'BLACKWORK', 'placement': 'calf'},
  ];

  final List<Map<String, String>> _styles = [
    {'id': 'FINE_LINE', 'label': 'Fine Line'},
    {'id': 'BLACKWORK', 'label': 'Blackwork'},
    {'id': 'GEOMETRIC', 'label': 'Geométrico'},
    {'id': 'NEOTRIBAL', 'label': 'Neotribal'},
    {'id': 'MINIMALIST', 'label': 'Minimalista'},
    {'id': 'JAPANESE', 'label': 'Japonés'},
  ];

  final List<Map<String, String>> _placements = [
    {'id': 'forearm', 'label': 'Antebrazo'},
    {'id': 'wrist', 'label': 'Muñeca'},
    {'id': 'biceps', 'label': 'Bíceps'},
    {'id': 'calf', 'label': 'Pantorrilla'},
    {'id': 'back', 'label': 'Espalda'},
  ];

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isGenerating = true;
      _statusStep = 'Analizando prompt y estilo anatómico...';
    });

    try {
      await Future.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      setState(() => _statusStep = 'Generando lineart de alta resolución...');

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.generateAiStencil(
        prompt: prompt,
        style: _selectedStyle,
        placement: _selectedPlacement,
      );

      if (!mounted) return;
      setState(() => _statusStep = 'Optimizando transparencia para Realidad Aumentada...');
      await Future.delayed(const Duration(milliseconds: 300));

      Uint8List? bytes;
      if (response.stencilDataUrl.isNotEmpty && response.stencilDataUrl.contains(',')) {
        final base64Str = response.stencilDataUrl.split(',').last;
        bytes = base64Decode(base64Str);
      }

      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _statusStep = null;
        _generatedStencil = response;
        _stencilImageBytes = bytes;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isGenerating = false;
        _statusStep = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar: $e')),
      );
    }
  }

  void _openInAr() {
    Navigator.of(context).pushNamed(
      '/ar',
      arguments: {
        'tattooBytes': _stencilImageBytes,
        'stencilTitle': _generatedStencil?.title ?? 'Diseño IA',
        'curvatureFactor': _generatedStencil?.suggestedCurvatureFactor ?? 0.18,
        'bodyPart': _selectedPlacement,
        'isDemo': false,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estudio Creativo IA'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    const Color(0xFF06B6D4).withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Color(0xFFA78BFA), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Text-to-Stencil IA',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Describe tu idea y crea un stencil con fondo transparente listo para AR.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Prompt Input
            const Text(
              'Descripción del Tatuaje (Prompt)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _promptController,
              maxLines: 2,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'ej. Serpiente enredada en una espada con rosas finas...',
                hintStyle: const TextStyle(color: Color(0xFF64748B)),
                filled: true,
                fillColor: const Color(0xFF14141F),
                contentPadding: const EdgeInsets.all(14),
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
              ),
            ),
            const SizedBox(height: 12),

            // Inspiration Chips
            SizedBox(
              height: 34,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _samplePrompts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final sample = _samplePrompts[index];
                  return ActionChip(
                    label: Text(sample['title']!, style: const TextStyle(fontSize: 12, color: Color(0xFFE2E8F0))),
                    backgroundColor: const Color(0xFF1E1E2E),
                    side: const BorderSide(color: Color(0xFF334155)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    onPressed: () {
                      setState(() {
                        _promptController.text = sample['prompt']!;
                        _selectedStyle = sample['style']!;
                        _selectedPlacement = sample['placement']!;
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Style Selector
            const Text(
              'Estilo de Tatuaje',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _styles.map((s) {
                final isSelected = _selectedStyle == s['id'];
                return ChoiceChip(
                  label: Text(s['label']!),
                  selected: isSelected,
                  selectedColor: const Color(0xFF8B5CF6),
                  backgroundColor: const Color(0xFF14141F),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF8B5CF6) : const Color(0xFF1E293B),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedStyle = s['id']!);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),

            // Placement Selector
            const Text(
              'Ubicación Anatómica en el Cuerpo',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFCBD5E1)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _placements.map((p) {
                final isSelected = _selectedPlacement == p['id'];
                return ChoiceChip(
                  label: Text(p['label']!),
                  selected: isSelected,
                  selectedColor: const Color(0xFF06B6D4),
                  backgroundColor: const Color(0xFF14141F),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF94A3B8),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                    color: isSelected ? const Color(0xFF06B6D4) : const Color(0xFF1E293B),
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _selectedPlacement = p['id']!);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Generate Button
            ElevatedButton.icon(
              icon: _isGenerating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.auto_awesome_rounded, size: 20),
              label: Text(_isGenerating ? (_statusStep ?? 'Generando...') : 'Generar Stencil con IA'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: _isGenerating ? null : _generate,
            ),
            const SizedBox(height: 28),

            // Generated Result Card
            if (_generatedStencil != null) ...[
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF14141F),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.4)),
                ),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _generatedStencil!.title,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: Colors.white),
                          ),
                        ),
                        // Background toggle button
                        IconButton(
                          tooltip: 'Alternar fondo de contraste',
                          icon: Icon(
                            _showDarkBg ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined,
                            size: 20,
                            color: const Color(0xFFA78BFA),
                          ),
                          onPressed: () => setState(() => _showDarkBg = !_showDarkBg),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stencil Preview Canvas
                    Container(
                      height: 260,
                      decoration: BoxDecoration(
                        color: _showDarkBg ? const Color(0xFF0A0A0F) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF1E293B)),
                      ),
                      child: Center(
                        child: _stencilImageBytes != null
                            ? Image.memory(
                                _stencilImageBytes!,
                                fit: BoxFit.contain,
                                color: _showDarkBg ? Colors.white : Colors.black,
                              )
                            : Icon(
                                Icons.brush_rounded,
                                size: 80,
                                color: _showDarkBg ? Colors.white : Colors.black,
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // AI Anatomical Advice
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: const [
                              Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF06B6D4), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Recomendación Anatómica de la IA',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: Color(0xFF06B6D4)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _generatedStencil!.placementAdvice,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFCBD5E1), height: 1.4),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(
                                'Tamaño estimado: ${_generatedStencil!.widthCm} x ${_generatedStencil!.heightCm} cm',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                              ),
                              const Spacer(),
                              Text(
                                'Curvatura: ${(_generatedStencil!.suggestedCurvatureFactor * 100).toInt()}%',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFA78BFA), fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // AR PREVIEW CTA
                    ElevatedButton.icon(
                      icon: const Icon(Icons.view_in_ar_rounded, size: 22),
                      label: const Text(
                        'PROBAR EN MI PIEL CON AR',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF06B6D4),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 6,
                        shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                      ),
                      onPressed: _openInAr,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),
    );
  }
}
