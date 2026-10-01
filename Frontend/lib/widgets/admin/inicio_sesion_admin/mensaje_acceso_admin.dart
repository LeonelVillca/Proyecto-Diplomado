part of '../../../screens/admin/auth/admin_login_screen.dart';

extension _MensajeAccesoAdmin on _AdminLoginScreenState {
  Widget _buildInlineMessage() {
    final isError = _inlineMessageIsError;
    return AnimatedSize(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: _inlineMessage == null
          ? const SizedBox.shrink()
          : Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 16),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: (isError ? const Color(0xFFD95C5C) : authSage)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isError ? const Color(0xFFD95C5C) : authSage)
                      .withValues(alpha: 0.24),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError
                        ? Icons.error_outline_rounded
                        : Icons.check_circle_outline_rounded,
                    color: isError ? const Color(0xFFD95C5C) : authSage,
                    size: 19,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _inlineMessage!,
                      style: GoogleFonts.manrope(
                        color: isError
                            ? const Color(0xFF9C3F3F)
                            : const Color(0xFF47703F),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _inlineMessage = null),
                    child: Icon(
                      Icons.close_rounded,
                      color: isError ? const Color(0xFFD95C5C) : authSage,
                      size: 17,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
