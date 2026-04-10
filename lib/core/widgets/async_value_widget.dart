import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'error_state.dart';
import 'shimmer_box.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AsyncValueWidget — helper para renderizar AsyncValue<T> como Widget
// ─────────────────────────────────────────────────────────────────────────────

extension AsyncValueWidget<T> on AsyncValue<T> {
  /// Renderiza el AsyncValue como un Widget con estados loading/error/data.
  ///
  /// - [data]: builder con el valor cargado.
  /// - [loading]: widget durante la carga (default: shimmer vertical).
  /// - [error]: widget en caso de error (default: ErrorState con Reintentar).
  Widget whenWidget({
    required Widget Function(T value) data,
    Widget? loading,
    Widget Function(Object error, VoidCallback? retry)? error,
    VoidCallback? onRetry,
  }) {
    return when(
      data: data,
      loading: () =>
          loading ??
          const _DefaultShimmerLoading(),
      error: (err, _) =>
          error != null
              ? error(err, onRetry)
              : ErrorState(
                  message: err.toString(),
                  onRetry: onRetry,
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Default shimmer cuando no se especifica loading widget
// ─────────────────────────────────────────────────────────────────────────────

class _DefaultShimmerLoading extends StatelessWidget {
  const _DefaultShimmerLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      padding: const EdgeInsets.all(16),
      children: [
        ShimmerBox(width: double.infinity, height: 160, radius: 20),
        const SizedBox(height: 16),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: TransactionTileShimmer(),
          ),
        ),
      ],
    );
  }
}

