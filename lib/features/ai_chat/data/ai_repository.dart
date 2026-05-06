import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../domain/message_model.dart';

class AiRepository {
  const AiRepository();

  static const _apiUrl = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-3-5-sonnet-20240620';

  String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';

  String _buildSystemPrompt({
    double? balance,
    double? income,
    double? expenses,
    String languageCode = 'es',
    String currencySymbol = 'RD\$',
  }) {
    final isEn = languageCode == 'en';
    final langName = isEn ? 'English' : 'Spanish (Dominican style)';
    
    if (isEn) {
      return '''You are FinPa AI, the personal financial advisor of the FinPa app.
You are friendly, empathetic, and an expert in personal finance for the Dominican Republic.

USER DATA (current month):
- Balance: $currencySymbol${balance?.toStringAsFixed(0) ?? 'N/A'}
- Income: $currencySymbol${income?.toStringAsFixed(0) ?? 'N/A'}
- Expenses: $currencySymbol${expenses?.toStringAsFixed(0) ?? 'N/A'}

INSTRUCTIONS:
- ALWAYS respond in $langName.
- Maximum 120 words per response.
- Give concrete and actionable advice.
- Use user data when relevant.
- If you detect a bad financial habit, be empathetic but direct.
- Never recommend specific financial products by name.
- End with a follow-up question when appropriate.''';
    }

    return '''Eres FinPa IA, el asesor financiero personal de la app FinPa.
Eres amigable, empático y experto en finanzas personales para la República Dominicana.

DATOS DEL USUARIO (mes actual):
- Balance: $currencySymbol${balance?.toStringAsFixed(0) ?? 'N/D'}
- Ingresos: $currencySymbol${income?.toStringAsFixed(0) ?? 'N/D'}
- Gastos: $currencySymbol${expenses?.toStringAsFixed(0) ?? 'N/D'}

INSTRUCCIONES:
- Responde SIEMPRE en $langName.
- Máximo 120 palabras por respuesta.
- Da consejos concretos y accionables.
- Usa los datos del usuario cuando sea relevante.
- Si detectas mal hábito financiero, sé empático pero directo.
- Nunca recomiendes productos financieros específicos con nombre.
- Termina con una pregunta de seguimiento cuando sea apropiado.''';
  }

  /// Envía un mensaje al API de Anthropic y devuelve la respuesta.
  Future<String> sendMessage({
    required List<MessageModel> history,
    required String userMessage,
    double? balance,
    double? income,
    double? expenses,
    String languageCode = 'es',
    String currencySymbol = 'RD\$',
  }) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 800));
      return _localFallback(userMessage, languageCode);
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
          languageCode: languageCode,
          currencySymbol: currencySymbol,
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
  Future<String> generateAutoTip({
    double? balance,
    double? income,
    double? expenses,
    List<String>? topCategories,
    String languageCode = 'es',
    String currencySymbol = 'RD\$',
  }) async {
    if (_apiKey.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 700));
      final fallbacks = languageCode == 'en' ? _fallbackTipsEn : _fallbackTipsEs;
      return fallbacks[DateTime.now().second % fallbacks.length];
    }

    final isEn = languageCode == 'en';
    final langName = isEn ? 'English' : 'Spanish (Dominican style)';

    final categoryText =
        topCategories != null && topCategories.isNotEmpty
            ? 'Top categories: ${topCategories.join(', ')}.'
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
            'Eres FinPa IA. Da UN consejo financiero personal en 1-2 oraciones en $langName. Sin saludos. Directo al punto. $categoryText',
        'messages': [
          {
            'role': 'user',
            'content':
                'Give me a tip based on: balance $currencySymbol${balance?.toStringAsFixed(0) ?? "N/A"}, income $currencySymbol${income?.toStringAsFixed(0) ?? "N/A"}, expenses $currencySymbol${expenses?.toStringAsFixed(0) ?? "N/A"}.',
          }
        ],
      }),
    );

    if (response.statusCode != 200) return languageCode == 'en' ? _fallbackTipsEn[0] : _fallbackTipsEs[0];

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['content'] as List<dynamic>)[0]['text'] as String;
  }

  String _localFallback(String userMessage, String languageCode) {
    return languageCode == 'en'
      ? 'I understand your query. To give you the best advice, I need you to activate the integration with FinPa AI by configuring your API key in the .env file. Do you have any specific questions about your finances?'
      : 'Entiendo tu consulta. Para darte el mejor consejo, necesito que actives la integración con FinPa IA configurando tu API key en el archivo .env. ¿Tienes alguna pregunta específica sobre tus finanzas?';
  }

  static const _fallbackTipsEs = [
    'Ahorra al menos el 10% de tus ingresos cada mes para construir un fondo de emergencia.',
    'Revisa tus suscripciones activas; podrías estar pagando por servicios que ya no utilizas.',
    'Evita las compras impulsivas esperando 24 horas antes de adquirir algo que no sea de primera necesidad.',
    'Prioriza el pago de las deudas con las tasas de interés más altas para ahorrar dinero a largo plazo.',
    'Usa FinPa para registrar cada pequeño gasto; la suma de los "gastos hormiga" te sorprenderá.',
  ];

  static const _fallbackTipsEn = [
    'Save at least 10% of your income each month to build an emergency fund.',
    'Review your active subscriptions; you might be paying for services you no longer use.',
    'Avoid impulsive purchases by waiting 24 hours before buying non-essential items.',
    'Prioritize paying off debts with the highest interest rates to save money in the long run.',
    'Use FinPa to track every small expense; the total of "ghost expenses" will surprise you.',
  ];
}
