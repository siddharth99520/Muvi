import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';
import '../theme/app_theme.dart';
import 'settings_dialog.dart';

class TitleBar extends StatelessWidget {
  const TitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: MoveWindow(
        child: Container(
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

              // ── Fullscreen Toggle ────────────────────────────
              IconButton(
                icon: const Icon(Icons.fullscreen_rounded, size: 18),
                color: AppTheme.textSecondary,
                hoverColor: Colors.white,
                splashRadius: 20,
                tooltip: 'Immersive Fullscreen (F11)',
                onPressed: () async {
                  bool isFull = await windowManager.isFullScreen();
                  await windowManager.setFullScreen(!isFull);
                },
              ),
              const SizedBox(width: 4),

              // ── Settings ─────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 18),
                color: AppTheme.textSecondary,
                hoverColor: Colors.white,
                splashRadius: 20,
                tooltip: 'Settings',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (_) => const SettingsDialog(),
                  );
                },
              ),
              const SizedBox(width: 10),

              // ── Live / Detecting badge ───────────────────────
              Selector<PlayerProvider, bool>(
                selector: (_, p) => p.state.isLive,
                builder: (_, isLive, __) => _StatusBadge(isLive: isLive),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Status badge ────────────────────────────────────────────────
class _StatusBadge extends StatefulWidget {
  final bool isLive;
  const _StatusBadge({required this.isLive});

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.isLive ? AppTheme.accentGlow : AppTheme.accentCyan;
    final label = widget.isLive ? 'LIVE' : 'DETECTING MEDIA';

    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, __) {
        final opacity = widget.isLive
            ? 0.5 + 0.5 * _pulse.value // pulse when live
            : 1.0; // steady when detecting
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                  color: dotColor.withOpacity(opacity),
                  boxShadow: [
                    BoxShadow(
                      color: dotColor.withOpacity(opacity * 0.8),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        );
      },
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
        const SizedBox(width: 8),
        _WinBtn(
          color: const Color(0xFF28C840),
          hoverColor: const Color(0xFF00A216),
          icon: Icons.open_in_full_rounded,
          onTap: () => appWindow.maximizeOrRestore(),
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
