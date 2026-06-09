import 'package:flutter/widgets.dart';

class TextDirectionHelper {
  static TextDirection of(BuildContext context) => Directionality.of(context);

  static bool isRTL(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl;

  static EdgeInsetsDirectional symmetric(
          {double horizontal = 0.0, double vertical = 0.0}) =>
      EdgeInsetsDirectional.symmetric(
          horizontal: horizontal, vertical: vertical);

  static AlignmentDirectional start() => AlignmentDirectional.centerStart;

  static AlignmentDirectional end() => AlignmentDirectional.centerEnd;
}

class RtlAwareWidget extends StatelessWidget {
  const RtlAwareWidget({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // If the widget is deeply nested and we need to wrap it specifically to ensure
    // it gets the correct Directionality or to force a specific layout constraint based on RTL
    return Directionality(
      textDirection: Directionality.of(context),
      child: child,
    );
  }
}
