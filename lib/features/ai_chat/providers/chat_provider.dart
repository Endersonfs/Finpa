import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ai_repository.dart';
import '../domain/message_model.dart';

final aiRepositoryProvider =
    Provider<AiRepository>((_) => const AiRepository());

// ── ChatNotifier ──────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<MessageModel>> {
  final AiRepository _repo;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ChatNotifier(this._repo)
      : super([
          MessageModel.assistant(
            'Hola! Soy FinPa IA, tu asesor financiero personal. ¿En qué te puedo ayudar hoy? 💙',
          ),
        ]);

  Future<void> sendMessage(
    String text, {
    double? balance,
    double? income,
    double? expenses,
  }) async {
    if (text.trim().isEmpty || _isLoading) return;

    final userMsg = MessageModel.user(text.trim());
    state = [...state, userMsg];
    _isLoading = true;
    // Force notify para mostrar TypingIndicator
    state = [...state];

    try {
      // El historial excluye el último mensaje del usuario —
      // se pasa por separado como userMessage.
      final history = state.sublist(0, state.length - 1);

      final response = await _repo.sendMessage(
        history: history,
        userMessage: text.trim(),
        balance: balance,
        income: income,
        expenses: expenses,
      );

      final assistantMsg = MessageModel.assistant(response);
      var newState = [...state, assistantMsg];
      // Limitar a 40 mensajes (20 pares) para no crecer indefinidamente
      if (newState.length > 40) {
        newState = newState.sublist(newState.length - 40);
      }
      state = newState;
    } catch (_) {
      final errorMsg = MessageModel.assistant(
        'Lo siento, tuve un problema al procesar tu mensaje. Por favor intenta de nuevo. 🙏',
      );
      state = [...state, errorMsg];
    } finally {
      _isLoading = false;
      // Force notify para ocultar TypingIndicator
      state = [...state];
    }
  }

  void clearHistory() {
    state = [
      MessageModel.assistant(
        'Hola! Soy FinPa IA, tu asesor financiero personal. ¿En qué te puedo ayudar hoy? 💙',
      ),
    ];
  }
}

final chatNotifierProvider =
    StateNotifierProvider<ChatNotifier, List<MessageModel>>(
  (ref) => ChatNotifier(ref.watch(aiRepositoryProvider)),
);

// Provider separado para exponer el loading state y que los widgets
// puedan observarlo sin escuchar toda la lista de mensajes.
final chatLoadingProvider = Provider<bool>((ref) {
  ref.watch(chatNotifierProvider); // Suscribirse a cambios de estado
  return ref.read(chatNotifierProvider.notifier).isLoading;
});

