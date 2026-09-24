import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/services/movil/restaurante_cliente_service.dart';
import 'package:frontend/controllers/movil/auth_controller.dart' as frontend_auth;

class CreateReviewModal extends StatefulWidget {
  final String restaurantId;
  final VoidCallback onSuccess;

  const CreateReviewModal({
    super.key,
    required this.restaurantId,
    required this.onSuccess,
  });

  @override
  State<CreateReviewModal> createState() => _CreateReviewModalState();
}

class _CreateReviewModalState extends State<CreateReviewModal> {
  int _rating = 5;
  final _commentCtrl = TextEditingController();
  bool _isSubmitting = false;

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      final auth = frontend_auth.AuthScope.of(context, listen: false);
      final idUsuario = auth.idUsuario;
      if (idUsuario == null) throw Exception('Usuario no autenticado');

      final ctrl = RestauranteScope.of(context, listen: false);
      await ctrl.crearResena(widget.restaurantId, idUsuario, _rating, _commentCtrl.text.trim());
      
      if (mounted) {
        widget.onSuccess();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('¡Reseña publicada con éxito!'),
            backgroundColor: AppColors.sage,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ReservaFinalizadaRequerida catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.wine,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al publicar la reseña: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Opinar', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.inkSoft),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Puedes reseñar después de que tu reserva en este restaurante esté finalizada.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            '¿Cómo calificarías tu experiencia?',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                iconSize: 40,
                padding: EdgeInsets.zero,
                icon: Icon(
                  index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.gold,
                ),
                onPressed: () {
                  setState(() => _rating = index + 1);
                },
              );
            }),
          ),
          const SizedBox(height: 24),
          Text(
            'Cuéntanos más',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentCtrl,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: '¿Qué fue lo que más te gustó? ¿Algo podría mejorar?',
              hintStyle: const TextStyle(color: AppColors.inkSoft),
              filled: true,
              fillColor: AppColors.paperDeep,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isSubmitting || _commentCtrl.text.trim().isEmpty ? null : _submitReview,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.wine,
                disabledBackgroundColor: AppColors.wineSoft.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(
                      'Publicar reseña',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
