import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../theme/app_theme.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return MoveWindow(
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppTheme.divider, width: 1),
          ),
        ),
        child: Row(
          children: [
            // ── Window Buttons ───────────────────────────────
            _WindowButtons(),
            const SizedBox(width: 20),

            // ── App Name ─────────────────────────────────────
            Text('MUVI', style: AppTheme.appName),

            const Spacer(),

            // ── Status indicator ─────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentCyan,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.accentCyan.withOpacity(0.8),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'DETECTING MEDIA',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textSecondary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _WinBtn(
          color: const Color(0xFFFF5F57),
          hoverColor: const Color(0xFFFF3B30),
          icon: Icons.close_rounded,
          onTap: () => appWindow.close(),
        ),
        const SizedBox(width: 8),
        _WinBtn(
          color: const Color(0xFFFFBD2E),
          hoverColor: const Color(0xFFFF9500),
          icon: Icons.remove_rounded,
          onTap: () => appWindow.minimize(),
        ),
      ],
    );
  }
}

class _WinBtn extends StatefulWidget {
  final Color color;
  final Color hoverColor;
  final IconData icon;
  final VoidCallback onTap;

  const _WinBtn({
    required this.color,
    required this.hoverColor,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_WinBtn> createState() => _WinBtnState();
}

class _WinBtnState extends State<_WinBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered ? widget.hoverColor : widget.color,
          ),
          child: _hovered
              ? Icon(widget.icon, size: 10, color: Colors.black54)
              : null,
        ),
      ),
    );
  }
}
