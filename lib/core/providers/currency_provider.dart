import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/currencies.dart';
import 'shared_preferences_provider.dart';

part 'currency_provider.g.dart';

class CurrencyState {
  final AppCurrency baseCurrency;
  final Map<String, double> rates;
  final bool isLoading;

  CurrencyState({
    required this.baseCurrency,
    required this.rates,
    this.isLoading = false,
  });

  CurrencyState copyWith({
    AppCurrency? baseCurrency,
    Map<String, double>? rates,
    bool? isLoading,
  }) {
    return CurrencyState(
      baseCurrency: baseCurrency ?? this.baseCurrency,
      rates: rates ?? this.rates,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@riverpod
class CurrencyNotifier extends _$CurrencyNotifier {
  static const _prefKey = 'base_currency';
  static const _ratesKey = 'cached_rates';

  @override
  CurrencyState build() {
    final prefs = ref.watch(sharedPrefsProvider);
    
    // Load saved currency
    final savedCode = prefs.getString(_prefKey);
    final base = AppCurrency.values.firstWhere(
      (e) => e.name == savedCode,
      orElse: () => AppCurrency.dop,
    );

    // Load cached rates
    final cachedStr = prefs.getString(_ratesKey);
    Map<String, double> rates = {
      'DOP': 1.0,
      'USD': 0.017, // Fallback aproximado
      'EUR': 0.015, // Fallback aproximado
    };

    if (cachedStr != null) {
      final decoded = json.decode(cachedStr) as Map<String, dynamic>;
      rates = decoded.map((k, v) => MapEntry(k, (v as num).toDouble()));
    }

    return CurrencyState(
      baseCurrency: base,
      rates: rates,
    );
  }

  Future<void> setBaseCurrency(AppCurrency currency) async {
    state = state.copyWith(baseCurrency: currency);
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_prefKey, currency.name);
    
    // Refresh rates when base currency changes
    await fetchRates();
  }

  Future<void> fetchRates() async {
    state = state.copyWith(isLoading: true);
    try {
      final base = state.baseCurrency.code;
      // Usando API gratuita (necesitaría API Key en prod, pero para el ejemplo usamos un endpoint directo si es posible)
      // Nota: Muchas APIs requieren API_KEY. Usaremos una con fallback.
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$base'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newRates = (data['rates'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));
        
        state = state.copyWith(rates: newRates, isLoading: false);
        
        final prefs = ref.read(sharedPrefsProvider);
        await prefs.setString(_ratesKey, json.encode(newRates));
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  double convert(double amount, AppCurrency from, AppCurrency to) {
    if (from == to) return amount;
    
    // Si la moneda 'from' es la base, simplemente multiplicamos por la tasa de 'to'
    if (from == state.baseCurrency) {
      return amount * (state.rates[to.code] ?? 1.0);
    }
    
    // Si no, convertimos primero a la base y luego a la destino
    final rateFrom = state.rates[from.code] ?? 1.0;
    final amountInBase = amount / rateFrom;
    final rateTo = state.rates[to.code] ?? 1.0;
    
    return amountInBase * rateTo;
  }
}
