enum AppCurrency {
  dop,
  usd,
  eur;

  String get code => name.toUpperCase();
  
  String get symbol {
    switch (this) {
      case AppCurrency.dop: return 'RD\$';
      case AppCurrency.usd: return '\$';
      case AppCurrency.eur: return '€';
    }
  }

  String get flag {
    switch (this) {
      case AppCurrency.dop: return '🇩🇴';
      case AppCurrency.usd: return '🇺🇸';
      case AppCurrency.eur: return '🇪🇺';
    }
  }

  String get label {
    switch (this) {
      case AppCurrency.dop: return 'Peso Dominicano';
      case AppCurrency.usd: return 'Dólar Estadounidense';
      case AppCurrency.eur: return 'Euro';
    }
  }

  String get locale {
    switch (this) {
      case AppCurrency.dop: return 'es_DO';
      case AppCurrency.usd: return 'en_US';
      case AppCurrency.eur: return 'de_DE';
    }
  }
}
