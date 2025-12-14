import 'dart:convert';
import 'package:http/http.dart' as http;

class QaService {
  // The backend URL can be provided at build/run time with --dart-define:
  // flutter run -d chrome --dart-define=QA_BACKEND_URL="https://.../qaHandler"
  // If not provided, the placeholder triggers the mock fallback.
  static const _backendUrl = String.fromEnvironment(
    'QA_BACKEND_URL',
    defaultValue: 'https://YOUR_CLOUD_FUNCTION_URL/qaHandler',
  );

  /// Ask a question. Returns the AI answer as plain text.
  static Future<String> askQuestion(String question) async {
    if (_backendUrl.contains('YOUR_CLOUD_FUNCTION_URL') ||
        question.trim().isEmpty) {
      return _mockAnswer(question);
    }

    try {
      final resp = await http.post(
        Uri.parse(_backendUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'question': question}),
      );
      if (resp.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(resp.body);
        return (body['answer'] as String?) ?? _mockAnswer(question);
      } else {
        // Return a helpful error so users can see why the backend failed.
        String details = '';
        try {
          final Map<String, dynamic> body = jsonDecode(resp.body);
          details = body['error'] != null
              ? body['error'].toString()
              : resp.body;
        } catch (_) {
          details = resp.body;
        }
        return '(Backend error ${resp.statusCode}): $details';
      }
    } catch (_) {
      return _mockAnswer(question);
    }
  }

  static String _mockAnswer(String question) {
    if (question.trim().isEmpty) return 'Please ask a question.';
    return "(Mock answer) I received your question: '$question'.\n\nTo enable real AI answers locally:\n1) Create a file at `functions/.runtimeconfig.json` with:\n   { \"openai\": { \"key\": \"sk_YOUR_OPENAI_KEY\" } }\n2) Start the Functions emulator in the project root: `npx firebase emulators:start --only functions`\n3) Run the app with the backend URL: `flutter run -d chrome --dart-define=QA_BACKEND_URL=\"http://localhost:5002/travellerapp2025/us-central1/qaHandler\"`\n\nDo NOT commit your API key to source control or paste it in public chat.";
  }
}
