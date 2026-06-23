import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeminiService {

  // ⚠️ For production do not hardcode API keys
  static const String _apiKey = "AIzaSyBfA3MUDGGd2pjjhUIVi53MAVpWm3Xdr8U";
  static const String _model = "models/gemini-2.5-flash";

  Future<String> getAIResponse(String message) async {

    if (message.trim().isEmpty) {
      return "Please type a message.";
    }

    final hasInternet = await _hasInternet();
    if (!hasInternet) {
      return "No internet connection. Please check your network.";
    }

    return _callGeminiWithRetry(message);
  }

  Future<String> _callGeminiWithRetry(String message) async {

    final result1 = await _callGemini(message);

    if (!result1.startsWith("TEMP_ERROR::")) {
      return result1;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    final result2 = await _callGemini(message);

    return result2.replaceFirst("TEMP_ERROR::", "");
  }

  Future<String> _callGemini(String message) async {

    try {

      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/$_model:generateContent?key=$_apiKey",
      );

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
You are an AI assistant inside a mobile chat app.

Rules:
- Explain the answer clearly.
- Keep the explanation short and simple.
- Respond in about 5 to 6 lines maximum.
- No bullet points.

User question: $message
"""
                }
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.7,
            "maxOutputTokens": 200
          }
        }),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);
        final candidates = data["candidates"];

        if (candidates == null || candidates.isEmpty) {
          return "AI returned empty response.";
        }

        String aiText =
            candidates[0]["content"]["parts"][0]["text"] ?? "No response text.";

        return aiText.trim();
      }

      final errorMessage = _parseGeminiError(response.body);

      if (response.statusCode == 429) {
        return "API quota exceeded. Please try again later.";
      }

      if (response.statusCode == 400) {
        return "Invalid request. Please try a different message.";
      }

      if (response.statusCode == 401 || response.statusCode == 403) {
        return "API key issue. Please check your Gemini API key.";
      }

      if (response.statusCode >= 500 && response.statusCode <= 599) {
        return "TEMP_ERROR::Server error. Retrying...";
      }

      return errorMessage.isNotEmpty ? errorMessage : "Request failed.";
    }

    on SocketException {
      return "No internet connection. Please check your network.";
    }

    on HttpException {
      return "Network error. Please try again.";
    }

    on FormatException {
      return "Invalid server response.";
    }

    on TimeoutException {
      return "TEMP_ERROR::Request timeout. Retrying...";
    }

    catch (_) {
      return "Something went wrong.";
    }
  }

  String _parseGeminiError(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded["error"] != null) {
        return decoded["error"]["message"]?.toString() ?? "";
      }
    } catch (_) {}
    return "";
  }

  Future<bool> _hasInternet() async {
    try {
      final result = await InternetAddress.lookup("google.com")
          .timeout(const Duration(seconds: 3));

      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}