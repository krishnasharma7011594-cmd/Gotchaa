import 'package:flutter/material.dart';

import '../firebase/stream_loop_guard.dart';

/// StreamBuilder with loop detection — shows error if emissions exceed threshold.
class GuardedStreamBuilder<T> extends StatefulWidget {
  const GuardedStreamBuilder({
    required this.stream,
    required this.builder,
    super.key,
    this.label,
    this.loopErrorBuilder,
  });

  final Stream<T> stream;
  final String? label;
  final AsyncWidgetBuilder<T> builder;
  final Widget Function(BuildContext, String reason)? loopErrorBuilder;

  @override
  State<GuardedStreamBuilder<T>> createState() => _GuardedStreamBuilderState<T>();
}

class _GuardedStreamBuilderState<T> extends State<GuardedStreamBuilder<T>> {
  final StreamLoopGuard _guard = StreamLoopGuard();

  @override
  Widget build(BuildContext context) => StreamBuilder<T>(
        stream: widget.stream,
        builder: (context, snapshot) {
          if (snapshot.hasData && !_guard.tick(label: widget.label)) {
            final reason = _guard.breakReason ?? 'Too many updates';
            return widget.loopErrorBuilder?.call(context, reason) ??
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Something went wrong loading this content. Pull to refresh.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                );
          }
          return widget.builder(context, snapshot);
        },
      );
}
