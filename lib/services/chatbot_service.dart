import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  static const String _apiKey = 'YOUR_ANTHROPIC_API_KEY';
  static const String _baseUrl = 'https://api.anthropic.com/v1/messages';

  static const String _systemPrompt = '''
You are BloodBot, the AI assistant for BloodConnect - a blood bank management app.
You help blood donors and blood bank administrators with:
1. Blood donation FAQs (eligibility, process, recovery, diet)
2. Understanding blood types and compatibility
3. Guidance on donation frequency (whole blood: every 56 days)
4. Pre-donation preparation tips (hydration, iron-rich foods, sleep)
5. Post-donation care instructions
6. App usage guidance
7. Understanding blood inventory and why donations matter
8. Addressing anxiety or fears about donating

Important rules:
- Always encourage eligible donors to donate
- For medical concerns, always recommend consulting a healthcare professional
- Be warm, empathetic, and encouraging
- Keep responses concise but informative
- For emergencies, direct users to call emergency services
''';

  final List<Map<String, String>> _conversationHistory = [];

  Future<String> sendMessage(String userMessage) async {
    _conversationHistory.add({'role': 'user', 'content': userMessage});
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-sonnet-4-20250514',
          'max_tokens': 1024,
          'system': _systemPrompt,
          'messages': _conversationHistory,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage = data['content'][0]['text'] as String;
        _conversationHistory.add({'role': 'assistant', 'content': assistantMessage});
        if (_conversationHistory.length > 20) {
          _conversationHistory.removeRange(0, 2);
        }
        return assistantMessage;
      } else if (response.statusCode == 429) {
        return 'I am receiving too many requests right now. Please try again in a moment.';
      } else {
        return 'I am having trouble connecting right now. Please try again later.';
      }
    } catch (e) {
      return 'Connection error. Please check your internet connection and try again.';
    }
  }

  void clearHistory() => _conversationHistory.clear();

  static List<String> get quickReplies => [
    'Am I eligible to donate?',
    'What should I eat before donating?',
    'How long does donation take?',
    'Which blood types can I donate to?',
    'How to book an appointment?',
    'What happens after I donate?',
  ];
}
