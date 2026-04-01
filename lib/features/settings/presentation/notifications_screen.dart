import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

// ── Modelo de notificación local ───────────────────────────────────────────────

class _Notif {
  final String type;
  final String title;
  final String description;
  final DateTime time;
  bool isRead;

  _Notif({
    required this.type,
    required this.title,
    required this.description,
    required this.time,
    this.isRead = false,
  });
}

// ── Config de ícono por tipo ───────────────────────────────────────────────────

const _kNotifConfig = {
  'alerta_presupuesto': (
    Icons.warning_amber_rounded,
    Color(0xFF3B5BDB),
    Color(0xFFEEF2FF),
    Color(0xFF0D1227),
  ),
  'meta_lograda': (
    Icons.check_circle_rounded,
    Color(0xFF059669),
    Color(0xFFF0FDF4),
    Color(0xFF0A1F0F),
  ),
  'tip_ia': (
    Icons.psychology_rounded,
    Color(0xFF6B7280),
    Color(0xFFFFFFFF),
    Color(0xFF0F1320),
  ),
  'nueva_leccion': (
    Icons.menu_book_rounded,
    Color(0xFF6B7280),
    Color(0xFFFFFFFF),
    Color(0xFF0F1320),
  ),
};

// ── NotificationsScreen ────────────────────────────────────────────────────────

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late List<_Notif> _notifs;

  @override
  void initState() {
    super.initState();
    _notifs = [
      _Notif(
        type: 'alerta_presupuesto',
        title: 'Alerta de presupuesto',
        description:
            'Llevas el 82% de tu presupuesto en Comida este mes.',
        time: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
      _Notif(
        type: 'meta_lograda',
        title: '¡Meta alcanzada!',
        description:
            'Completaste tu meta "Fondo de emergencia". ¡Felicidades! 🎉',
        time: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      _Notif(
        type: 'tip_ia',
        title: 'Tip de FinPa IA',
        description:
            'Tus gastos en transporte bajaron 12% este mes. ¡Buen trabajo!',
        time: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: true,
      ),
      _Notif(
        type: 'nueva_leccion',
        title: 'Nueva lección disponible',
        description:
            'Aprende sobre interés compuesto en el módulo de Inversión.',
        time: DateTime.now().subtract(const Duration(days: 1)),
        isRead: true,
      ),
    ];
  }

  void _markAllRead() {
    setState(() {
      for (final n in _notifs) {
        n.isRead = true;
      }
    });
  }

  static String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours} h';
    return 'Hace ${diff.inDays} días';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final c = theme.extension<FinPaColors>()!;
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final textPrimary = theme.colorScheme.onSurface;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: Text(
              'Marcar todas',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF3B5BDB),
              ),
            ),
          ),
        ],
      ),
      body: _notifs.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 48,
                    color: c.muted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No tienes notificaciones',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _notifs.length,
              itemBuilder: (context, index) {
                final notif = _notifs[index];
                final config = _kNotifConfig[notif.type] ??
                    _kNotifConfig['tip_ia']!;
                final icon = config.$1;
                final iconColor = config.$2;
                final bgLight = config.$3;
                final bgDark = config.$4;

                return GestureDetector(
                  onTap: () => setState(() => notif.isRead = true),
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: notif.isRead
                          ? surface
                          : (isDark ? bgDark : bgLight),
                      border: Border.all(
                        color: notif.isRead
                            ? c.border
                            : iconColor.withValues(alpha: 50),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 26),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(icon, size: 18, color: iconColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      notif.title,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(0xFF3B5BDB),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                notif.description,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(notif.time),
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: c.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
