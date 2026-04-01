import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../transactions/providers/transaction_provider.dart';
import '../domain/message_model.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // Los quick replies se muestran solo hasta que el usuario envíe su primer
  // mensaje en la sesión actual de la pantalla.
  bool _showQuickReplies = true;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _send(String text, Map<String, double>? summary) {
    if (text.trim().isEmpty) return;

    final income = summary?['income'];
    final expense = summary?['expense'];
    final balance =
        (income != null && expense != null) ? income - expense : null;

    ref.read(chatNotifierProvider.notifier).sendMessage(
          text,
          balance: balance,
          income: income,
          expenses: expense,
        );

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark
        ? const Color(0xFF0A0D14)
        : const Color(0xFFF5F6FA);
    final textPrimary =
        isDark ? const Color(0xFFE8EEFF) : const Color(0xFF1A1F36);

    final messages = ref.watch(chatNotifierProvider);
    final isLoading = ref.watch(chatLoadingProvider);
    final summary = ref.watch(monthlySummaryProvider).valueOrNull;

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: scaffoldBg,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF0D1227)
                    : const Color(0xFFEEF2FF),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFC7D2FE),
                ),
              ),
              child: const Icon(
                Icons.psychology_rounded,
                size: 20,
                color: Color(0xFF3B5BDB),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FinPa IA',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF059669),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'En línea',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Limpiar chat'),
                content: const Text(
                  '¿Borrar el historial de conversación?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      ref
                          .read(chatNotifierProvider.notifier)
                          .clearHistory();
                      setState(() => _showQuickReplies = true);
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Limpiar',
                      style: TextStyle(color: Color(0xFFDC2626)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollCtrl,
              reverse: true,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: messages.length + (isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // En lista invertida el índice 0 es el más reciente.
                // Si está cargando, el primer slot es el TypingIndicator.
                if (isLoading && index == 0) {
                  return const _TypingIndicator();
                }
                final msgIndex = isLoading ? index - 1 : index;
                final msg = messages[messages.length - 1 - msgIndex];

                return Column(
                  crossAxisAlignment: msg.role == MessageRole.user
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    _MessageBubble(message: msg, isDark: isDark),
                    const SizedBox(height: 2),
                    if (!isLoading &&
                        msg.role == MessageRole.assistant &&
                        msgIndex == 0 &&
                        _showQuickReplies)
                      _QuickReplies(
                        onTap: (text) {
                          setState(() => _showQuickReplies = false);
                          _send(text, summary);
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
          _InputArea(
            controller: _textCtrl,
            isLoading: isLoading,
            isDark: isDark,
            onSend: () {
              final text = _textCtrl.text;
              _textCtrl.clear();
              setState(() => _showQuickReplies = false);
              _send(text, summary);
            },
          ),
        ],
      ),
    );
  }
}

// ── _MessageBubble ────────────────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isDark;

  const _MessageBubble({required this.message, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final timeFmt = DateFormat('HH:mm');

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isUser
                  ? const Color(0xFF3B5BDB)
                  : (isDark
                      ? const Color(0xFF0F1320)
                      : const Color(0xFFEEF2FF)),
              border: isUser
                  ? null
                  : Border.all(
                      color: isDark
                          ? const Color(0xFF1E2840)
                          : const Color(0xFFC7D2FE),
                    ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft:
                    isUser ? const Radius.circular(12) : const Radius.circular(3),
                bottomRight:
                    isUser ? const Radius.circular(3) : const Radius.circular(12),
              ),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isUser
                    ? Colors.white
                    : (isDark
                        ? const Color(0xFFE8EEFF)
                        : const Color(0xFF1A1F36)),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            timeFmt.format(message.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? const Color(0xFF4A5580)
                  : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _TypingIndicator ──────────────────────────────────────────────────────────

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;

  static const _delays = [0, 200, 400];

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (i) {
      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      );
      Future.delayed(Duration(milliseconds: _delays[i]), () {
        if (mounted) ctrl.repeat(reverse: true);
      });
      return ctrl;
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F1320) : const Color(0xFFEEF2FF),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E2840)
                : const Color(0xFFC7D2FE),
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
            bottomLeft: Radius.circular(3),
            bottomRight: Radius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: AnimatedBuilder(
                animation: _controllers[i],
                builder: (_, __) => Transform.translate(
                  offset: Offset(0, -6 * _controllers[i].value),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF3B5BDB).withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ── _QuickReplies ─────────────────────────────────────────────────────────────

class _QuickReplies extends StatelessWidget {
  final void Function(String) onTap;

  const _QuickReplies({required this.onTap});

  static const _chips = [
    '¿Cómo está mi presupuesto?',
    'Dame consejos de ahorro',
    'Analiza mis gastos',
    '¿Cómo van mis metas?',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: _chips.map((chip) {
          return GestureDetector(
            onTap: () => onTap(chip),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0D1227)
                    : const Color(0xFFEEF2FF),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A8A)
                      : const Color(0xFFC7D2FE),
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                chip,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xFF93C5FD)
                      : const Color(0xFF3730A3),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── _InputArea ────────────────────────────────────────────────────────────────

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final bool isDark;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.isLoading,
    required this.isDark,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0D14) : const Color(0xFFF5F6FA),
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E2840)
                : const Color(0xFFE2E6F0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              maxLines: null,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Pregúntale a FinPa IA...',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xFF4A5580)
                      : const Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF141928)
                    : const Color(0xFFF0F2F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E2840)
                        : const Color(0xFFE2E6F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(
                    color: isDark
                        ? const Color(0xFF1E2840)
                        : const Color(0xFFE2E6F0),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(
                    color: Color(0xFF3B5BDB),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isLoading
                    ? (isDark
                        ? const Color(0xFF1E2840)
                        : const Color(0xFFE2E6F0))
                    : const Color(0xFF3B5BDB),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF3B5BDB),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.arrow_upward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
