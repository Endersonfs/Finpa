import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../domain/message_model.dart';

class AiRepository {
  const AiRepository();

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-20250514';

  String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  String _buildSystemPrompt({
    double? balance,
    double? income,
    double? expenses,
  }) {
    return '''Eres FinPa IA, el asesor financiero personal de la app FinPa.
Eres amigable, empático y experto en finanzas personales para la República Dominicana.

DATOS DEL USUARIO (mes actual):
- Balance: RD\$${balance?.toStringAsFixed(0) ?? 'N/D'}
- Ingresos: RD\$${income?.toStringAsFixed(0) ?? 'N/D'}
- Gastos: RD\$${expenses?.toStringAsFixed(0) ?? 'N/D'}

INSTRUCCIONES:
- Responde SIEMPRE en español dominicano (natural y cercano)
- Máximo 120 palabras por respuesta
- Da consejos concretos y accionables
- Usa los datos del usuario cuando sea relevante
- Si detectas mal hábito financiero, sé empático pero directo
- Nunca recomiendes productos financieros específicos con nombre
- Termina con una pregunta de seguimiento cuando sea apropiado''';
  }

  /// Envía un mensaje al API de Anthropic y devuelve la respuesta.
  Future<String> sendMessage({
    required List<MessageModel> history,
    required String userMessage,
    double? balance,
    double? income,
    double? expenses,
  }) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _localFallback(userMessage);
    }

    final messages = [
      ...history.map((m) => {
            'role': m.role == MessageRole.user ? 'user' : 'assistant',
            'content': m.content,
          }),
      {'role': 'user', 'content': userMessage},
    ];

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 300,
        'system': _buildSystemPrompt(
          balance: balance,
          income: income,
          expenses: expenses,
        ),
        'messages': messages,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final errMsg =
          (body['error'] as Map<String, dynamic>?)?['message'] as String? ??
              response.statusCode.toString();
      throw Exception('Error de API: $errMsg');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['content'] as List<dynamic>)[0]['text'] as String;
  }

  /// Genera un tip corto para el dashboard o banners.
  /// Mantiene la misma firma pública que la versión anterior para compatibilidad
  /// con TipBanner, AddBudgetScreen y dashboard_provider.
  Future<String> generateAutoTip({
    double? balance,
    double? income,
    double? expenses,
    List<String>? topCategories,
  }) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      return _fallbackTips[DateTime.now().second % _fallbackTips.length];
    }

    final categoryText =
        topCategories != null && topCategories.isNotEmpty
            ? 'Top categorías de gasto: ${topCategories.join(', ')}.'
            : '';

    final response = await http.post(
      Uri.parse(_apiUrl),
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': _apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode({
        'model': _model,
        'max_tokens': 100,
        'system':
            'Eres FinPa IA. Da UN consejo financiero personal en 1-2 oraciones en español dominicano. Sin saludos. Directo al punto. $categoryText',
        'messages': [
          {
            'role': 'user',
            'content':
                'Dame un consejo basado en: balance RD\$${balance?.toStringAsFixed(0) ?? "N/D"}, ingresos RD\$${income?.toStringAsFixed(0) ?? "N/D"}, gastos RD\$${expenses?.toStringAsFixed(0) ?? "N/D"}.',
          }
        ],
      }),
    );

    if (response.statusCode != 200) return _fallbackTips[0];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['content'] as List<dynamic>)[0]['text'] as String;
  }

  // ── Fallbacks locales (sin API key) ───────────────────────────────────────

  static const _fallbackTips = [
    'Registra todos tus gastos diariamente para tener control total de tus finanzas.',
    'Destina al menos el 20% de tus ingresos al ahorro antes de gastar.',
    'Revisa tus suscripciones activas — podrías estar pagando por servicios que no usas.',
    'La regla 50/30/20: 50% necesidades, 30% deseos, 20% ahorro.',
    'Construye un fondo de emergencia de 3-6 meses de gastos básicos.',
  ];

  static String _localFallback(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('presupuesto') || msg.contains('gastos')) {
      return 'Llevar un registro de tus gastos es el primer paso para mejorar tus finanzas. '
          'Te recomiendo revisar la sección de Presupuesto para ver cómo vas este mes. '
          '¿Hay alguna categoría específica que te preocupe?';
    }
    if (msg.contains('ahorro') || msg.contains('meta')) {
      return 'El ahorro es el hábito financiero más importante. '
          'Incluso pequeñas cantidades como RD\$500 al mes pueden hacer una gran diferencia a largo plazo. '
          '¿Tienes alguna meta de ahorro específica?';
    }
    if (msg.contains('deuda') || msg.contains('préstamo')) {
      return 'Para salir de deudas, la estrategia de avalancha (pagar primero la de mayor interés) '
          'te ahorra más dinero. ¿Quieres que analicemos tu situación específica?';
    }
    return 'Entiendo tu consulta. Para darte el mejor consejo, necesito que actives la integración '
        'con FinPa IA configurando tu API key en el archivo .env. '
        '¿Tienes alguna pregunta específica sobre tus finanzas?';
  }
}

