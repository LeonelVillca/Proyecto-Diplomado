import 'package:frontend/core/movil/consumer_design.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:frontend/widgets/movil/restaurant/inline_error_banner.dart';
import 'package:frontend/controllers/movil/restaurante_controller.dart';
import 'package:frontend/services/movil/restaurante_cliente_service.dart';
import 'package:frontend/controllers/movil/auth_controller.dart'
    as frontend_auth;

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
  final _scrollController = ScrollController();
  bool _isSubmitting = false;
  String? _errorMessage;

  void _showError(String message) {
    if (!mounted) return;
    setState(() => _errorMessage = message);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submitReview() async {
    if (_commentCtrl.text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final auth = frontend_auth.AuthScope.of(context, listen: false);
      final idUsuario = auth.idUsuario;
      if (idUsuario == null) throw Exception('Usuario no autenticado');

      final ctrl = RestauranteScope.of(context, listen: false);
      await ctrl.crearResena(
        widget.restaurantId,
        idUsuario,
        _rating,
        _commentCtrl.text.trim(),
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        widget.onSuccess();
        Navigator.of(context).pop();
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Reseña publicada con éxito.'),
            backgroundColor: ConsumerColors.sage,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ReservaFinalizadaRequerida catch (error) {
      _showError(error.toString());
    } catch (error) {
      _showError(error.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _scrollController.dispose();
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
        color: ConsumerColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Opinar',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(
                    LucideIcons.x,
                    color: ConsumerColors.inkSoft,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (_errorMessage != null) ...[
              InlineErrorBanner(
                message: _errorMessage!,
                onDismiss: () => setState(() => _errorMessage = null),
              ),
              const SizedBox(height: 16),
            ],
            const SizedBox(height: 8),
            Text(
              'Puedes reseñar después de que tu reserva en este restaurante esté finalizada.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              '¿Cómo calificarías tu experiencia?',
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  iconSize: 40,
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : LucideIcons.star,
                    color: ConsumerColors.gold,
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
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: '¿Qué fue lo que más te gustó? ¿Algo podría mejorar?',
                hintStyle: const TextStyle(color: ConsumerColors.inkSoft),
                filled: true,
                fillColor: ConsumerColors.paperDeep,
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
                onPressed: _isSubmitting || _commentCtrl.text.trim().isEmpty
                    ? null
                    : _submitReview,
                style: FilledButton.styleFrom(
                  backgroundColor: ConsumerColors.wine,
                  disabledBackgroundColor: ConsumerColors.wineSoft.withValues(
                    alpha: 0.5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Publicar reseña',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
