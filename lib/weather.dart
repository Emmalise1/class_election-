import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  WeatherData({required this.temperature, required this.code});
  final double temperature;
  final int code;

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['temperature_2m'] as num).toDouble(),
      code: (json['weather_code'] as num).toInt(),
    );
  }
}

Future<WeatherData> fetchWeather() async {
  final url = Uri.parse('https://api.open-meteo.com/v1/forecast?latitude=-1.9441&longitude=30.0619&current=temperature_2m,weather_code&timezone=Africa%2FKigali');
  final response = await http.get(url);
  if (response.statusCode != 200) throw Exception('Failed');
  final data = jsonDecode(response.body);
  return WeatherData.fromJson(data['current']);
}