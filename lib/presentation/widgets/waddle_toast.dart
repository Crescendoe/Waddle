import 'dart:async';
import 'package:flutter/material.dart';
import 'package:waddle/core/theme/app_theme.dart';

/// A themed toast banner that slides in from the top, auto-dismisses, and
/// optionally supports a tap action.
///
/// Usage:
/// ```dart
/// WaddleToast.show(context, title: 'New Quest!', body: 'Daily quests refreshed.', icon: Icons.assignment);
/// ```
class WaddleToast {
  WaddleToast._();

  static OverlayEntry? _currentEntry;
  static Timer? _autoDismiss;

  /// Show a contextual toast banner at the top of the screen.
  static void show(
    BuildContext context, {
    required String title,
    String? body,
    IconData icon = Icons.info_rounded,
    Color? color,
    Duration duration = const Duration(seconds: 3),
    VoidCallback? onTap,
  }) {
    dismiss(); // Clear any existing toast

    final overlay = Overlay.of(context, rootOverlay: true);
    final themeColor = color ?? AppColors.primary;

    _currentEntry = OverlayEntry(
      builder: (_) => _WaddleToastWidget(
        title: title,
        body: body,
        icon: icon,
        color: themeColor,
        onTap: onTap,
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_currentEntry!);

    _autoDismiss?.cancel();
    _autoDismiss = Timer(duration, dismiss);
  }

  static void dismiss() {
    _autoDismiss?.cancel();
    _autoDismiss = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _WaddleToastWidget extends StatefulWidget {
  final String title;
  final String? body;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final VoidCallback onDismiss;

  const _WaddleToastWidget({
    required this.title,
    this.body,
    required this.icon,
    required this.color,
    this.onTap,
    required this.onDismiss,
  });

  @override
  State<_WaddleToastWidget> createState() => _WaddleToastWidgetState();
}

class _WaddleToastWidgetState extends State<_WaddleToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 350),
      reverseDuration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismissAnimated() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Positioned(
      top: topPad + 8,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: () {
              widget.onTap?.call();
              _dismissAnimated();
            },
            onVerticalDragEnd: (details) {
              if (details.velocity.pixelsPerSecond.dy < -100) {
                _dismissAnimated();
              }
            },
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.color.withValues(alpha: 0.3),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.15),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, size: 20, color: widget.color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (widget.body != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.body!,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
