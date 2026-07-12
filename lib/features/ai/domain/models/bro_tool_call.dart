enum ToolType { navigate, openDeepLink, conversation, unknown }

sealed class BroToolCall {
  const BroToolCall({
    required this.type,
    required this.confidence,
    this.rawQuery,
  });

  final ToolType type;
  final double confidence;
  final String? rawQuery;

  Map<String, dynamic> toJson();
}

class BroNavigateCall extends BroToolCall {
  const BroNavigateCall({
    required this.screen,
    required double confidence,
    String? rawQuery,
  }) : super(
            type: ToolType.navigate,
            confidence: confidence,
            rawQuery: rawQuery);

  final String screen;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'screen': screen,
        'confidence': confidence,
        'rawQuery': rawQuery,
      };

  @override
  String toString() =>
      'BroNavigateCall(screen: $screen, confidence: $confidence)';
}

class BroDeepLinkCall extends BroToolCall {
  const BroDeepLinkCall({
    required this.app,
    required this.url,
    required double confidence,
    String? rawQuery,
  }) : super(
            type: ToolType.openDeepLink,
            confidence: confidence,
            rawQuery: rawQuery);

  final String app;
  final String url;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'app': app,
        'url': url,
        'confidence': confidence,
        'rawQuery': rawQuery,
      };

  @override
  String toString() =>
      'BroDeepLinkCall(app: $app, url: $url, confidence: $confidence)';
}

class BroConversationCall extends BroToolCall {
  const BroConversationCall({
    required this.reply,
    required double confidence,
    String? rawQuery,
  }) : super(
            type: ToolType.conversation,
            confidence: confidence,
            rawQuery: rawQuery);

  final String reply;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'reply': reply,
        'confidence': confidence,
        'rawQuery': rawQuery,
      };

  @override
  String toString() =>
      'BroConversationCall(reply: $reply, confidence: $confidence)';
}

class BroUnknownCall extends BroToolCall {
  const BroUnknownCall({
    required this.reply,
    required double confidence,
    String? rawQuery,
  }) : super(
            type: ToolType.unknown, confidence: confidence, rawQuery: rawQuery);

  final String reply;

  @override
  Map<String, dynamic> toJson() => {
        'type': type.name,
        'reply': reply,
        'confidence': confidence,
        'rawQuery': rawQuery,
      };

  @override
  String toString() => 'BroUnknownCall(reply: $reply, confidence: $confidence)';
}
