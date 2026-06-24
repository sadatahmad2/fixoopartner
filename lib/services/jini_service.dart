import 'dart:convert';
import 'package:http/http.dart' as http;

class JiniService {
  static const String _apiKey = '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';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  static Future<String> getJiniResponse(String userPrompt) async {
    try {
      final url = Uri.parse(_baseUrl);
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };

      final body = jsonEncode({
        "model": "llama-3.1-8b-instant",
        "messages": [
          {
            "role": "system",
            "content": "You are Jini, the magical AI assistant for the FixooIndia Partner app. "
                       "Speak in a friendly and professional Hinglish (Hindi + English) style. "
                       "Refer to the user as 'Master'. FixooIndia Partner app features include: "
                       "Earnings (check balance and payouts), Bookings (manage service requests), "
                       "KYC (document verification), and Profile settings. "
                       "Keep your answers concise, helpful, and magical. "
                       "Always be polite and helpful. If you don't know something about the app, "
                       "tell them to check the Support Center."
          },
          {
            "role": "user",
            "content": userPrompt
          }
        ],
        "temperature": 0.7,
        "max_tokens": 1024,
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String aiText = data['choices'][0]['message']['content'];
        return aiText;
      } else {
        final errorData = jsonDecode(response.body);
        return "Master, mere neural link mein error hai. Code: ${response.statusCode}, Msg: ${errorData['error']['message']}";
      }
    } catch (e) {
      return "Master, main connect nahi ho pa raha hoon. Error: ${e.toString()}";
    }
  }
}
