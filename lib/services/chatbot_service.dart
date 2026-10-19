import 'package:google_generative_ai/google_generative_ai.dart';

/// Chatbot service powered by Google Gemini (gemini-1.5-flash).
///
/// To get a free API key:
/// 1. Go to https://aistudio.google.com/app/apikey
/// 2. Click "Create API Key"
/// 3. Replace the value of [_apiKey] below with your key.
///
/// The Gemini free tier supports ~60 requests/minute — more than enough
/// for typical app usage.
class ChatbotService {
  // 🔑 Replace with your Gemini API key from https://aistudio.google.com/
  static const String _apiKey = 'YOUR_GEMINI_API_KEY';

  static const String _systemPrompt = '''
You are BloodBot, the AI assistant for BloodConnect — a blood bank management app.
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

  String _currentModel;
  late GenerativeModel _model;
  ChatSession? _session;

  String get currentModel => _currentModel;

  ChatbotService({String model = 'gemini-1.5-flash'}) : _currentModel = model {
    _initModel();
  }

  void _initModel() {
    _model = GenerativeModel(
      model: _currentModel,
      apiKey: _apiKey,
      systemInstruction: Content.system(_systemPrompt),
      generationConfig: GenerationConfig(maxOutputTokens: 600),
    );
    _session = _model.startChat();
  }

  void setModel(String model) {
    if (_currentModel != model) {
      _currentModel = model;
      _initModel();
    }
  }

  Future<String> sendMessage(String userMessage) async {
    if (_apiKey == 'YOUR_GEMINI_API_KEY') {
      return 'BloodBot is not configured yet. Please add a Gemini API key to chatbot_service.dart.\n\nGet a free key at: https://aistudio.google.com/app/apikey';
    }
    try {
      final response = await _session!.sendMessage(Content.text(userMessage));
      return response.text ??
          'I could not generate a response. Please try again.';
    } on GenerativeAIException catch (e) {
      if (e.message.contains('quota') || e.message.contains('429')) {
        return 'I am receiving too many requests right now. Please try again in a moment.';
      }
      return 'I am having trouble connecting right now. Please try again later.';
    } catch (_) {
      return 'Connection error. Please check your internet connection and try again.';
    }
  }

  /// Clears conversation history and starts a fresh chat session.
  void clearHistory() {
    _session = _model.startChat();
  }

  static List<String> get quickReplies => [
    'Am I eligible to donate?',
    'What should I eat before donating?',
    'How long does donation take?',
    'Which blood types can I donate to?',
    'How to book an appointment?',
    'What happens after I donate?',
  ];
}
