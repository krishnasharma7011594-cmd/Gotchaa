import 'package:google_generative_ai/google_generative_ai.dart';

/// Base class for all BRO Action Tools
abstract class BroTool {
  /// Unique name of the tool for Gemini tool calling
  String get name;

  /// Human-readable description of what the tool does
  String get description;

  /// JSON schema for parameters required by this tool
  Map<String, dynamic> get parameters;

  /// Whether this tool requires biometric verification before execution
  bool get requiresBiometrics;

  /// The actual execution logic for the tool
  Future<Map<String, dynamic>> execute(Map<String, dynamic> arguments);

  /// Convert to [Tool] for Gemini API
  Tool toGeminiTool() => Tool(functionDeclarations: [
        FunctionDeclaration(
          name,
          description,
          Schema.object(
            properties: parameters.map((key, value) {
              // Simplistic mapping: in production this would be more robust
              return MapEntry(
                  key, Schema.string(description: value.toString()));
            }),
          ),
        ),
      ]);
}
