import 'dart:convert';

import 'package:clima/core/local_db_service.dart';
import 'package:clima/data.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class WeatherController extends GetxController {
  var weatherData = Rxn<WeatherData>();
  var isLoading = false.obs;
  var errorMessage = ''.obs;
  var selectedTabIndex = 0.obs;
  var isAppBarCollapsed = false.obs;

  var currentUser = Rxn<Map<String, dynamic>>();

  Future<void> register(String email, String password) async {
    final id = await LocalDBService.registerUser(email, password);
    if (id > 0) {
      Get.snackbar("Éxito", "Usuario registrado");
    } else {
      Get.snackbar("Error", "Ese usuario ya existe");
    }
  }

  Future<void> login(String email, String password) async {
    final user = await LocalDBService.loginUser(email, password);
    if (user != null) {
      currentUser.value = user;
      Get.snackbar("Éxito", "Sesión iniciada como ${user['email']}");
    } else {
      Get.snackbar("Error", "Credenciales incorrectas");
    }
  }

  void logout() {
    currentUser.value = null;
    Get.snackbar("Sesión cerrada", "Vuelve pronto");
  }

  bool get isLoggedIn => currentUser.value != null;

  // Getter para obtener los datos de la pestaña actual
  TabWeatherData? get currentTabData {
    if (weatherData.value == null) return null;
    return weatherData.value!.getDataForTab(selectedTabIndex.value);
  }

  // Getter para obtener los datos semanales extendidos
  List<DayForecast> get weeklyForecastData {
    if (weatherData.value == null) return [];
    return weatherData.value!.extendedWeeklyData;
  }

  // Lista de títulos para las pestañas
  List<String> get tabTitles => ['Hoy', 'Mañana', 'Próximos días'];

  @override
  void onInit() {
    super.onInit();
    getCurrentLocationWeather();
  }

  Future<void> getCurrentLocationWeather() async {
    isLoading(true);
    errorMessage('');

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Los servicios de ubicación están deshabilitados');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permisos de ubicación denegados');
        }
      }

      Position position = await Geolocator.getCurrentPosition();
      await fetchWeatherData(position.latitude, position.longitude);
    } catch (e) {
      errorMessage('Error obteniendo ubicación: $e');
      isLoading(false);
      // Usar coordenadas por defecto (Piedras Negras, Coahuila)
      await fetchWeatherData(
        28.7003,
        -100.5234,
        cityName: 'Piedras Negras, Coahuila',
      );
    }
  }

  Future<void> searchCity(String cityName) async {
    if (cityName.trim().isEmpty) return;

    isLoading(true);
    errorMessage('');

    try {
      final geocodingUrl =
          'https://geocoding-api.open-meteo.com/v1/search?name=$cityName&count=1&language=es&format=json';
      final geocodingResponse = await http.get(Uri.parse(geocodingUrl));

      if (geocodingResponse.statusCode == 200) {
        final geocodingData = json.decode(geocodingResponse.body);

        if (geocodingData['results'] != null &&
            geocodingData['results'].isNotEmpty) {
          final location = geocodingData['results'][0];
          final lat = location['latitude'];
          final lon = location['longitude'];

          await fetchWeatherData(lat, lon, cityName: location['name']);
        } else {
          errorMessage('Ciudad no encontrada');
          isLoading(false);
        }
      } else {
        throw Exception('Error en la búsqueda de la ciudad');
      }
    } catch (e) {
      errorMessage('Error buscando la ciudad: $e');
      isLoading(false);
    }
  }

  Future<void> fetchWeatherData(
    double lat,
    double lon, {
    String? cityName,
  }) async {
    isLoading(true);
    errorMessage('');
    weatherData.value = null;
    try {
      // Solicitar más días para datos semanales (14 días)
      final url =
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m,apparent_temperature,is_day,precipitation,weather_code,cloud_cover,pressure_msl,wind_speed_10m&hourly=temperature_2m,relative_humidity_2m,precipitation_probability,weather_code,pressure_msl,uv_index,wind_speed_10m&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset,uv_index_max&timezone=auto&forecast_days=14';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        weatherData.value = WeatherData.fromJson(data, cityName);
      } else {
        throw Exception('Error al obtener datos del clima');
      }
    } catch (e) {
      errorMessage('Error obteniendo datos del clima: $e');
      isLoading(false);
    } finally {
      isLoading(false);
    }
  }

  String getWeatherAnimation(int weatherCode, bool isDay) {
    // Mapear códigos de clima a las animaciones/ilustraciones
    if (weatherCode == 0) {
      return isDay ? 'sunny' : 'clear';
    }
    if (weatherCode <= 3) {
      return isDay ? 'partly_cloudy_day' : 'partly_cloudy';
    }
    if (weatherCode <= 48) return 'drizzle';
    if (weatherCode <= 67) return 'rain';
    if (weatherCode <= 77) return 'heavy_rain';
    if (weatherCode <= 82) return 'rain';
    if (weatherCode <= 86) return 'squalls';
    if (weatherCode <= 99) return 'thunderstorm';
    return 'mostly_sunny';
  }

  String getWeatherDescription(int weatherCode) {
    if (weatherCode == 0) return 'Despejado';
    if (weatherCode <= 3) return 'Parcialmente nublado';
    if (weatherCode <= 48) return 'Niebla';
    if (weatherCode <= 67) return 'Lluvia';
    if (weatherCode <= 77) return 'Nieve';
    if (weatherCode <= 82) return 'Chubascos';
    if (weatherCode <= 86) return 'Chubascos de nieve';
    if (weatherCode <= 99) return 'Tormenta';
    return 'Variado';
  }

  void changeTab(int index) {
    selectedTabIndex(index);
  }

  Color getGradientColor(int weatherCode, bool isDay) {
    if (weatherCode == 0 && isDay) {
      return Color(0xFF87CEEB); // Cielo azul claro
    }
    if (weatherCode == 0 && !isDay) {
      return Color(0xFF483D8B); // Púrpura nocturno
    }
    if (weatherCode <= 3) {
      return isDay ? Color(0xFF87CEEB) : Color(0xFF6A5ACD);
    }
    if (weatherCode <= 48) return Color(0xFF708090);
    if (weatherCode <= 67) return Color(0xFF4682B4);
    if (weatherCode <= 99) return Color(0xFF2F4F4F);
    return Color(0xFF87CEEB);
  }

  // Método para obtener el color del gradiente según la pestaña actual
  Color getCurrentGradientColor() {
    if (weatherData.value == null) return Color(0xFF87CEEB);

    final currentData = currentTabData;
    if (currentData == null) return Color(0xFF87CEEB);

    // Para la vista semanal, usar el clima actual
    if (selectedTabIndex.value == 2) {
      return getGradientColor(weatherData.value!.conditionIcon.hashCode, true);
    }

    // Para hoy y mañana, usar el código de clima específico
    final weatherCode = selectedTabIndex.value == 0
        ? weatherData.value!.conditionIcon.hashCode
        : weatherData.value!.tomorrowData.conditionIcon.hashCode;

    return getGradientColor(weatherCode, true);
  }

  // Método para refrescar los datos
  Future<void> refreshWeatherData() async {
    if (weatherData.value != null) {
      // Si ya tenemos datos, usar la misma ubicación
      getCurrentLocationWeather();
    }
  }

  // Método para obtener el pronóstico por horas de un día específico
  List<ForecastItem> getHourlyForecastForDay(int dayIndex) {
    if (weatherData.value == null) return [];

    switch (dayIndex) {
      case 0:
        return weatherData.value!.forecastData;
      case 1:
        return weatherData.value!.tomorrowData.forecastData;
      default:
        return []; // Para días futuros, no mostramos pronóstico por horas
    }
  }

  // Método para obtener los datos de lluvia de un día específico
  List<RainData> getRainDataForDay(int dayIndex) {
    if (weatherData.value == null) return [];

    switch (dayIndex) {
      case 0:
        return weatherData.value!.rainData;
      case 1:
        return weatherData.value!.tomorrowData.rainData;
      default:
        return [];
    }
  }

  // Método para verificar si una pestaña tiene datos disponibles
  bool hasDataForTab(int tabIndex) {
    if (weatherData.value == null) return false;

    switch (tabIndex) {
      case 0:
        return true; // Siempre hay datos para hoy
      case 1:
        return weatherData.value!.tomorrowData.forecastData.isNotEmpty;
      case 2:
        return weatherData.value!.extendedWeeklyData.length > 2;
      default:
        return false;
    }
  }

  // Método para obtener un resumen del clima para una pestaña
  String getTabSummary(int tabIndex) {
    final data = currentTabData;
    if (data == null) return '';

    switch (tabIndex) {
      case 0:
        return '${data.temperature}° • ${data.condition}';
      case 1:
        return '${data.dayTemp}°/${data.nightTemp}° • ${data.condition}';
      case 2:
        final weekData = weeklyForecastData;
        if (weekData.isNotEmpty) {
          final avgTemp =
              weekData
                  .take(7)
                  .map((d) => d.temperature)
                  .reduce((a, b) => a + b) /
              7;
          return '${avgTemp.round()}° promedio • 7 días';
        }
        return 'Pronóstico semanal';
      default:
        return '';
    }
  }
}
