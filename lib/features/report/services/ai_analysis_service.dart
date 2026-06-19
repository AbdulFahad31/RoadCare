import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ai_analysis.dart';

class AiAnalysisService {
  /// Analyzes a road image with Gemini 2.5 Flash
  Future<AiAnalysis> analyzeImage(File imageFile) async {
    int attempts = 0;
    const maxAttempts = 2;
    Object? lastError;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';
        if (apiKey.isEmpty) {
          throw Exception('Gemini API key is not configured in .env file.');
        }

        final url =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';
        final uri = Uri.parse(url);

        // Read image bytes and encode as Base64
        final bytes = await imageFile.readAsBytes();
        final base64Image = base64Encode(bytes);

        // Detect mimeType (default to image/jpeg)
        String mimeType = 'image/jpeg';
        final path = imageFile.path.toLowerCase();
        if (path.endsWith('.png')) {
          mimeType = 'image/png';
        } else if (path.endsWith('.webp')) {
          mimeType = 'image/webp';
        }

        const prompt = '''
You are an experienced civil road inspection engineer.
Analyze this road image.
Return ONLY valid JSON.
Do not include markdown.
Do not explain anything.
JSON Schema:
{
  "damage_type":"",
  "severity":"",
  "repair_priority":"",
  "estimated_diameter_cm":0,
  "estimated_depth_cm":0,
  "confidence":0,
  "description":"",
  "safety_warning":"",
  "suggested_action":""
}''';

        final requestBody = {
          'contents': [
            {
              'parts': [
                {
                  'text': prompt,
                },
                {
                  'inlineData': {
                    'mimeType': mimeType,
                    'data': base64Image,
                  }
                }
              ]
            }
          ],
          'generationConfig': {
            'responseMimeType': 'application/json',
          }
        };

        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(requestBody),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode != 200) {
          throw Exception(
              'Gemini API returned status code ${response.statusCode}: ${response.body}');
        }

        final decodedResponse =
            jsonDecode(response.body) as Map<String, dynamic>;

        // Extract content text from candidates
        final candidates = decodedResponse['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw Exception('No candidates returned from Gemini API.');
        }

        final candidate = candidates.first as Map<String, dynamic>;
        final content = candidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List?;
        if (parts == null || parts.isEmpty) {
          throw Exception('No parts returned in model content.');
        }

        final text = parts.first['text'] as String?;
        if (text == null || text.trim().isEmpty) {
          throw Exception('Model content part text is empty.');
        }

        final parsedJson = jsonDecode(text) as Map<String, dynamic>;
        return AiAnalysis.fromJson(parsedJson);
      } catch (e) {
        lastError = e;
        if (attempts < maxAttempts) {
          // Wait a short duration before retrying (2 seconds)
          await Future.delayed(const Duration(seconds: 2));
        }
      }
    }

    throw Exception(
        'Gemini analysis failed after $maxAttempts attempts. Last error: $lastError');
  }
}
