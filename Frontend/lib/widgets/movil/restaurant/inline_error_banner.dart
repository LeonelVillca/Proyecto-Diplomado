import 'package:flutter/material.dart';
import 'package:frontend/core/movil/theme.dart';

class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({super.key, required this.message, this.onDismiss});

  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFECEB),
        border: Border.all(color: const Color(0xFFB42335)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFF9C162F)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.wineDark,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              tooltip: 'Cerrar aviso',
              onPressed: onDismiss,
              icon: const Icon(Icons.close_rounded, size: 20),
              color: AppColors.wineDark,
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
        ],
      ),
    );
  }
}
