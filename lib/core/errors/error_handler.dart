import 'package:flutter/material.dart';

class ErrorHandler {
  static void initialize() {
    // Inicjalizacja obsługi błędów globalnych
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('Flutter Error: ${details.exception}');
    };
  }

  static Widget buildErrorWidget(FlutterErrorDetails errorDetails) {
    return Material(
      child: Container(
        color: const Color(0xFFFF6600),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Wystąpił błąd aplikacji',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Aplikacja napotkała nieoczekiwany problem.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Szczegóły błędu:\n${errorDetails.exception}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('SocketException')) {
      return 'Brak połączenia z internetem. Sprawdź połączenie i spróbuj ponownie.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Połączenie zbyt wolne. Spróbuj ponownie za chwilę.';
    } else if (error.toString().contains('FormatException')) {
      return 'Błąd w formacie danych. Skontaktuj się z administratorem.';
    } else {
      return 'Wystąpił nieoczekiwany błąd. Spróbuj ponownie.';
    }
  }
}
