import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/core/utils/network/api_endpoints.dart';
import 'package:frontend/controllers/movil/auth_controller.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';

class UserReviewsScreen extends StatefulWidget {
  const UserReviewsScreen({super.key});

  @override
  State<UserReviewsScreen> createState() => _UserReviewsScreenState();
}

class _UserReviewsScreenState extends State<UserReviewsScreen> {
  bool _isLoading = true;
  List<dynamic> _reviews = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarResenas());
  }

  Future<void> _cargarResenas() async {
    final auth = AuthScope.of(context, listen: false);
    final idUsuario = auth.idUsuario;
    final token = auth.token;

    if (idUsuario == null) return;

    try {
      final url = Uri.parse('${ApiEndpoints.baseUrl}/api/v1/resenas/usuario/$idUsuario');
      final res = await http.get(url, headers: {'Authorization': 'Bearer $token'});

      if (res.statusCode == 200) {
        final data = jsonDecode(utf8.decode(res.bodyBytes));
        setState(() => _reviews = data);
      }
    } catch (e) {
      debugPrint('Error cargando reseñas de usuario: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editarResena(Map<String, dynamic> review) async {
    final comentarioCtrl = TextEditingController(text: review['comentario']?.toString() ?? '');
    var calificacion = (review['calificacion'] as num?)?.toInt() ?? 1;
    final guardar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.paper,
          title: Text('Editar reseña', style: Theme.of(context).textTheme.titleLarge),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) => IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(index < calificacion ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.gold),
                  onPressed: () => setDialogState(() => calificacion = index + 1),
                )),
              ),
              TextField(
                controller: comentarioCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Cuéntanos tu experiencia',
                  filled: true,
                  fillColor: AppColors.card,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
            FilledButton(
              onPressed: comentarioCtrl.text.trim().isEmpty ? null : () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.wine),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
    final comentario = comentarioCtrl.text.trim();
    comentarioCtrl.dispose();
    if (guardar != true || !mounted) return;
    try {
      await RestauranteScope.of(context, listen: false).actualizarResena(review['id'].toString(), calificacion, comentario);
      await _cargarResenas();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _eliminarResena(Map<String, dynamic> review) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar reseña'),
        content: const Text('Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await RestauranteScope.of(context, listen: false).eliminarResena(review['id'].toString());
      await _cargarResenas();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('Mis Reseñas', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18, color: AppColors.ink)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.wine))
          : _reviews.isEmpty
              ? _buildEmptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(22),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _reviews.length,
                  itemBuilder: (context, index) {
                    final review = Map<String, dynamic>.from(_reviews[index] as Map);
                    return _buildReviewCard(context, review);
                  },
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.star_outline_rounded, size: 64, color: AppColors.inkSoft),
            const SizedBox(height: 24),
            Text('No tienes reseñas', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text('Aún no has calificado ningún restaurante. ¡Anímate a compartir tus experiencias!', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(BuildContext context, dynamic review) {
    final restaurante = review['restaurante'];
    final calificacion = review['calificacion'] ?? 0;
    final comentario = review['comentario'] ?? '';
    final fecha = review['fecha'] != null ? DateTime.parse(review['fecha']) : DateTime.now();
    final fechaStr = '${fecha.day.toString().padLeft(2,'0')}/${fecha.month.toString().padLeft(2,'0')}/${fecha.year}';
    final respuesta = review['respuesta'];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  restaurante != null ? restaurante['nombre'] : 'Restaurante',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 16),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (respuesta == null)
                PopupMenuButton<String>(
                  padding: EdgeInsets.zero,
                  onSelected: (value) => value == 'editar' ? _editarResena(review) : _eliminarResena(review),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'editar', child: Text('Editar')),
                    PopupMenuItem(value: 'eliminar', child: Text('Eliminar')),
                  ],
                ),
              Text(fechaStr, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(5, (index) => Icon(
              index < calificacion ? Icons.star_rounded : Icons.star_border_rounded,
              color: AppColors.gold,
              size: 16,
            )),
          ),
          const SizedBox(height: 12),
          Text(comentario, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14)),
          
          if (respuesta != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.wineSoft.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.wineSoft.withOpacity(0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.reply_rounded, size: 16, color: AppColors.wine),
                      const SizedBox(width: 6),
                      Text('Respuesta del restaurante', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 12, color: AppColors.wine)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(respuesta['texto'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ]
        ],
      ),
    );
  }
}
