import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';

class WeatherData {
  final double latitude;
  final double longitude;
  final String location;
  final int temperature;
  final String condition;
  final Widget conditionIcon;
  final int weatherCode;
  final bool isDay;
  final int feelsLike;
  final String date;
  final int dayTemp;
  final int nightTemp;
  final String backgroundImage;
  final String sunrise;
  final String sunset;
  final double windSpeed;
  final int rainProbability;
  final double pressure;
  final double uvIndex;

  final String windChange;
  final String rainChange;
  final String pressureChange;
  final String uvChange;
  final String sunriseChangeValue;
  final String sunsetChangeValue;

  final List<ForecastItem> forecastData;
  final List<DayForecast> weeklyData;
  final List<RainData> rainData;

  // Nuevas propiedades para mañana y datos extendidos
  final TomorrowData tomorrowData;
  final List<DayForecast> extendedWeeklyData;

  WeatherData({
    required this.latitude,
    required this.longitude,
    required this.location,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.feelsLike,
    required this.weatherCode,
    required this.isDay,
    required this.date,
    required this.dayTemp,
    required this.nightTemp,
    required this.backgroundImage,
    required this.sunrise,
    required this.sunset,
    required this.windSpeed,
    required this.rainProbability,
    required this.pressure,
    required this.uvIndex,
    required this.windChange,
    required this.rainChange,
    required this.pressureChange,
    required this.uvChange,
    required this.sunriseChangeValue,
    required this.sunsetChangeValue,
    required this.forecastData,
    required this.weeklyData,
    required this.rainData,
    required this.tomorrowData,
    required this.extendedWeeklyData,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String? cityName) {
    final current = json['current'];
    final daily = json['daily'];
    final hourly = json['hourly'];

    final hourlyTimes = hourly['time'] as List;
    final now = DateTime.now();
    int startIndex = hourlyTimes.indexWhere(
      (t) => DateTime.parse(t).isAfter(now),
    );
    if (startIndex == -1) startIndex = 0;
    if (startIndex > 0) startIndex--;

    const int historyHours = 3;
    final int referenceIndex = (startIndex - historyHours).clamp(0, startIndex);

    final currentWind = (hourly['wind_speed_10m'][startIndex] as num)
        .toDouble();
    final pastWind = (hourly['wind_speed_10m'][referenceIndex] as num)
        .toDouble();
    final windChange = _calculateChange(currentWind, pastWind, "km/h", 1);

    final currentRainProb =
        (hourly['precipitation_probability'][startIndex] as num).toDouble();
    final pastRainProb =
        (hourly['precipitation_probability'][referenceIndex] as num).toDouble();
    final rainChange = _calculateChange(currentRainProb, pastRainProb, "%", 0);

    final currentPressure = (hourly['pressure_msl'][startIndex] as num)
        .toDouble();
    final pastPressure = (hourly['pressure_msl'][referenceIndex] as num)
        .toDouble();
    final pressureChange = _calculateChange(
      currentPressure,
      pastPressure,
      "hPa",
      1,
    );

    final referenceUvIndex = (startIndex > 0) ? startIndex - 1 : 0;
    final currentUv = (hourly['uv_index'][startIndex] as num).toDouble();
    final pastUv = (hourly['uv_index'][referenceUvIndex] as num).toDouble();
    final uvChange = _calculateChange(currentUv, pastUv, "", 1);

    final sunriseTime = DateTime.parse(daily['sunrise'][0] as String);
    final sunsetTime = DateTime.parse(daily['sunset'][0] as String);
    final calculatedSunriseChange = now.isAfter(sunriseTime)
        ? _formatDuration(now.difference(sunriseTime), 'hace')
        : _formatDuration(sunriseTime.difference(now), 'en');
    final calculatedSunsetChange = now.isBefore(sunsetTime)
        ? _formatDuration(sunsetTime.difference(now), 'en')
        : _formatDuration(now.difference(sunsetTime), 'hace');

    // Datos para HOY
    final List<ForecastItem> todayForecast = [];
    final List<RainData> todayRain = [];
    final hourlyTemps = hourly['temperature_2m'] as List;
    final hourlyWeatherCodes = hourly['weather_code'] as List;
    final hourlyRainProb = hourly['precipitation_probability'] as List;

    const int numberOfHoursToShow = 8;
    for (
      int i = startIndex;
      i < startIndex + numberOfHoursToShow && i < hourlyTimes.length;
      i++
    ) {
      final time = DateTime.parse(hourlyTimes[i]);
      final isCurrentHour = i == startIndex;
      todayForecast.add(
        ForecastItem(
          time: isCurrentHour ? 'Ahora' : DateFormat('ha').format(time),
          weatherCode: hourlyWeatherCodes[i] as int,
          isDay: time.hour > 6 && time.hour < 19,
          temperature: '${(hourlyTemps[i] as num).round()}°',
        ),
      );
      final rainPercentage = (hourlyRainProb[i] as num).round();
      todayRain.add(
        RainData(
          time: DateFormat('ha').format(time),
          percentage: rainPercentage,
        ),
      );
    }

    // Datos para MAÑANA
    final tomorrow = now.add(Duration(days: 1));
    // final tomorrowStartHour =
    //     24 - now.hour + startIndex; // Aproximación para el siguiente día

    final List<ForecastItem> tomorrowForecast = [];
    final List<RainData> tomorrowRainData = [];

    // Buscar datos del día siguiente
    for (int i = 0; i < hourlyTimes.length; i++) {
      final time = DateTime.parse(hourlyTimes[i]);
      if (time.day == tomorrow.day && time.month == tomorrow.month) {
        if (tomorrowForecast.length < 8) {
          tomorrowForecast.add(
            ForecastItem(
              time: DateFormat('ha').format(time),
              weatherCode: hourlyWeatherCodes[i] as int,
              isDay: time.hour > 6 && time.hour < 19,
              temperature: '${(hourlyTemps[i] as num).round()}°',
            ),
          );
          tomorrowRainData.add(
            RainData(
              time: DateFormat('ha').format(time),
              percentage: (hourlyRainProb[i] as num).round(),
            ),
          );
        }
      }
    }

    // Crear datos de mañana
    final tomorrowData = TomorrowData(
      dayTemp: daily.length > 1
          ? (daily['temperature_2m_max'][1] as num).round()
          : 0,
      nightTemp: daily.length > 1
          ? (daily['temperature_2m_min'][1] as num).round()
          : 0,
      condition: daily.length > 1
          ? _getWeatherDescription(daily['weather_code'][1])
          : 'N/A',
      conditionIcon: daily.length > 1
          ? getWeatherIcon(
              code: daily['weather_code'][1],
              isDay: true,
              size: 59.0,
            )
          : Icon(Icons.help),
      sunrise: daily.length > 1 ? daily['sunrise'][1] as String : '',
      sunset: daily.length > 1 ? daily['sunset'][1] as String : '',
      uvIndex: daily.length > 1
          ? (daily['uv_index_max'][1] as num? ?? 0.0).toDouble()
          : 0.0,
      forecastData: tomorrowForecast,
      rainData: tomorrowRainData,
    );

    // Datos semanales (próximos 7 días)
    final List<DayForecast> weeklyData = [];
    final List<DayForecast> extendedWeeklyData = [];
    final dailyTimes = daily['time'] as List;
    final dailyMaxTemps = daily['temperature_2m_max'] as List;
    final dailyMinTemps = daily['temperature_2m_min'] as List;
    final dailyWeatherCodes = daily['weather_code'] as List;

    for (int i = 0; i < dailyTimes.length; i++) {
      final day = DateTime.parse(dailyTimes[i]);
      final dayForecast = DayForecast(
        dayName: i == 0
            ? 'Hoy'
            : i == 1
            ? 'Mañana'
            : DateFormat('E', 'es_ES').format(day),
        temperature: (dailyMaxTemps[i] as num).toDouble(),
        minTemperature: (dailyMinTemps[i] as num).toDouble(),
        weatherCode: dailyWeatherCodes[i] as int,
        date: day,
      );

      if (i < 3) {
        weeklyData.add(dayForecast);
      }
      extendedWeeklyData.add(dayForecast);
    }

    return WeatherData(
      latitude: json['latitude'],
      longitude: json['longitude'],
      location: cityName ?? 'Ubicación actual',
      temperature: (current['temperature_2m'] as num).round(),
      condition: _getWeatherDescription(current['weather_code']),
      conditionIcon: getWeatherIcon(
        code: current['weather_code'],
        isDay: current['is_day'] == 1,
        size: 59.0,
      ),
      feelsLike: (current['apparent_temperature'] as num).round(),
      date: DateFormat('MMMM d, HH:mm', 'es_ES').format(now),
      dayTemp: (daily['temperature_2m_max'][0] as num).round(),
      nightTemp: (daily['temperature_2m_min'][0] as num).round(),
      backgroundImage: _getWeatherAnimation(
        current['weather_code'],
        current['is_day'] == 1,
      ),
      sunrise: daily['sunrise'][0] as String,
      sunset: daily['sunset'][0] as String,
      windSpeed: currentWind,
      rainProbability: currentRainProb.round(),
      pressure: currentPressure,
      uvIndex: (daily['uv_index_max'][0] as num? ?? 0.0).toDouble(),
      windChange: windChange,
      rainChange: rainChange,
      pressureChange: pressureChange,
      uvChange: uvChange,
      sunriseChangeValue: calculatedSunriseChange,
      sunsetChangeValue: calculatedSunsetChange,
      forecastData: todayForecast,
      weeklyData: weeklyData,
      rainData: todayRain,
      tomorrowData: tomorrowData,
      extendedWeeklyData: extendedWeeklyData,
      weatherCode: current['weather_code'],
      isDay: current['is_day'] == 1,
    );
  }

  // Método para obtener datos según el índice de pestaña seleccionado
  TabWeatherData getDataForTab(int tabIndex) {
    switch (tabIndex) {
      case 0: // HOY
        return TabWeatherData(
          title: 'Hoy',
          date: date,
          temperature: temperature,
          condition: condition,
          conditionIcon: conditionIcon,
          dayTemp: dayTemp,
          nightTemp: nightTemp,
          sunrise: sunrise,
          sunset: sunset,
          uvIndex: uvIndex,
          forecastData: forecastData,
          rainData: rainData,
          backgroundImage: backgroundImage,
        );

      case 1: // MAÑANA
        final tomorrow = DateTime.now().add(Duration(days: 1));
        return TabWeatherData(
          title: 'Mañana',
          date: DateFormat('MMMM d', 'es_ES').format(tomorrow),
          temperature: tomorrowData.dayTemp,
          condition: tomorrowData.condition,
          conditionIcon: tomorrowData.conditionIcon,
          dayTemp: tomorrowData.dayTemp,
          nightTemp: tomorrowData.nightTemp,
          sunrise: tomorrowData.sunrise,
          sunset: tomorrowData.sunset,
          uvIndex: tomorrowData.uvIndex,
          forecastData: tomorrowData.forecastData,
          rainData: tomorrowData.rainData,
          backgroundImage: _getWeatherAnimation(
            extendedWeeklyData.length > 1
                ? extendedWeeklyData[1].weatherCode
                : 0,
            true,
          ),
        );

      case 2: // PRÓXIMOS DÍAS
        return TabWeatherData(
          title: 'Próximos 7 días',
          date: 'Pronóstico semanal',
          temperature:
              temperature, // Mantener temperatura actual como referencia
          condition: 'Ver detalles por día',
          conditionIcon: Icon(Icons.calendar_today),
          dayTemp: dayTemp,
          nightTemp: nightTemp,
          sunrise: sunrise,
          sunset: sunset,
          uvIndex: uvIndex,
          forecastData: [], // Sin datos horarios para vista semanal
          rainData: [],
          backgroundImage: backgroundImage,
        );

      default:
        return getDataForTab(0); // Default a HOY
    }
  }
}

// Clase para datos de mañana
class TomorrowData {
  final int dayTemp;
  final int nightTemp;
  final String condition;
  final Widget conditionIcon;
  final String sunrise;
  final String sunset;
  final double uvIndex;
  final List<ForecastItem> forecastData;
  final List<RainData> rainData;

  TomorrowData({
    required this.dayTemp,
    required this.nightTemp,
    required this.condition,
    required this.conditionIcon,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
    required this.forecastData,
    required this.rainData,
  });
}

// Clase para datos de pestaña
class TabWeatherData {
  final String title;
  final String date;
  final int temperature;
  final String condition;
  final Widget conditionIcon;
  final int dayTemp;
  final int nightTemp;
  final String sunrise;
  final String sunset;
  final double uvIndex;
  final List<ForecastItem> forecastData;
  final List<RainData> rainData;
  final String backgroundImage;

  TabWeatherData({
    required this.title,
    required this.date,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.dayTemp,
    required this.nightTemp,
    required this.sunrise,
    required this.sunset,
    required this.uvIndex,
    required this.forecastData,
    required this.rainData,
    required this.backgroundImage,
  });
}

String _calculateChange(
  double current,
  double past,
  String unit,
  int precision,
) {
  final diff = current - past;
  if (diff.abs() < 0.1) return '';
  final sign = diff > 0 ? '+' : '';
  final roundedDiff = (diff * pow(10, precision)).round() / pow(10, precision);
  return '$sign${roundedDiff.toStringAsFixed(precision)} $unit'.trim();
}

String _formatDuration(Duration duration, String prefix) {
  if (duration.isNegative) return '';
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  if (hours > 0) return '$prefix ${hours}h';
  if (minutes > 0) return '$prefix ${minutes}m';
  return '$prefix < 1m';
}

String _getWeatherDescription(int code) {
  if (code == 0) return 'Despejado';
  if (code <= 3) return 'Parcialmente nublado';
  if (code <= 48) return 'Niebla';
  if (code <= 67) return 'Lluvia';
  if (code <= 77) return 'Nieve';
  if (code <= 82) return 'Chubascos';
  if (code <= 86) return 'Chubascos de nieve';
  if (code <= 99) return 'Tormenta';
  return 'Variado';
}

Widget getWeatherIcon({
  required int code,
  required bool isDay,
  double size = 59.0,
}) {
  String assetName;

  switch (code) {
    // --- CIELO DESPEJADO Y NUBES ---
    case 0: // Despejado
      assetName = isDay ? 'sunny.svg' : 'clear.svg';
      break;
    case 1: // Principalmente despejado
      assetName = isDay ? 'mostly_sunny.svg' : 'mostly_cloudy_night.svg';
      break;
    case 2: // Parcialmente nublado
      assetName = isDay ? 'mostly_cloudy.svg' : 'mostly_cloudy_night.svg';
      break;
    case 3: // Nublado / Cubierto
      assetName = 'cloudy.svg';
      break;

    // --- NIEBLA ---
    case 45: // Niebla
    case 48: // Niebla de cencellada
      // Aún no tienes un icono para niebla, usamos 'cloudy' como alternativa.
      assetName = 'cloudy.svg';
      break;

    // --- LLUVIA Y LLOVIZNA ---
    case 51: // Llovizna ligera
    case 53: // Llovizna moderada
    case 55: // Llovizna densa
      assetName = 'drizzle.svg';
      break;
    case 61: // Lluvia ligera
    case 80: // Chubascos de lluvia ligeros
      assetName = 'showers.svg';
      break;
    case 63: // Lluvia moderada
    case 81: // Chubascos de lluvia moderados
      assetName = 'scattered_showers.svg';
      break;
    case 65: // Lluvia fuerte
    case 82: // Chubascos de lluvia violentos
      assetName = 'heavy.svg';
      break;

    // --- NIEVE Y MEZCLA INVERNAL ---
    case 56: // Llovizna helada ligera
    case 57: // Llovizna helada densa
    case 66: // Lluvia helada ligera
    case 67: // Lluvia helada fuerte
      assetName = 'wintry_mix.svg'; // O 'sleet_hail.svg' si lo prefieres
      break;
    case 71: // Nieve ligera
    case 77: // Granos de nieve
      assetName = 'flurries.svg';
      break;
    case 73: // Nieve moderada
      assetName = 'scattered_snow.svg';
      break;
    case 75: // Nieve fuerte
      assetName = 'heavy_snow.svg';
      break;
    case 85: // Chubascos de nieve ligeros
      assetName = 'snow_showers.svg';
      break;
    case 86: // Chubascos de nieve fuertes
      assetName = 'blowing_snow.svg'; // O 'heavy_snow.svg'
      break;

    // --- TORMENTAS ---
    case 95: // Tormenta ligera o moderada
      assetName = 'isolated_tstorms.svg';
      break;
    case 96: // Tormenta con granizo ligero
    case 99: // Tormenta con granizo fuerte
      assetName = 'strong_tstorms.svg';
      // Nota: También podrías usar 'sleet_hail.svg' aquí si quieres enfatizar el granizo.
      break;

    // --- POR DEFECTO ---
    default:
      assetName = 'cloudy.svg';
      break;
  }

  return SvgPicture.asset(
    'assets/icons/$assetName', // Asegúrate que esta ruta coincida con tu pubspec.yaml
    width: size,
    height: size,
  );
}

// FUNCIÓN PRINCIPAL: Llama a esta para obtener una imagen de fondo
String _getWeatherAnimation(int weatherCode, bool isDay) {
  // 1. Obtiene la colección de imágenes para el código de clima actual
  final imageCollection = _getImageCollectionForCode(weatherCode);

  // 2. Decide si usar la lista de día o de noche
  final timeKey = isDay ? 'day' : 'night';
  List<String> imageList = imageCollection[timeKey] ?? [];

  // 3. Si no hay imágenes para la hora actual (ej. no hay de noche), usa las de día como alternativa
  if (imageList.isEmpty) {
    imageList = imageCollection['day'] ?? [];
  }

  // 4. Si aún no hay imágenes, usa una por defecto
  if (imageList.isEmpty) {
    return 'assets/backgrounds/desconocido.jpg'; // O una imagen por defecto que prefieras
  }

  // 5. Elige una imagen al azar de la lista
  final random = Random();
  final selectedImage = imageList[random.nextInt(imageList.length)];

  // ¡Asegúrate de que la ruta 'assets/backgrounds/' es correcta!
  return 'assets/backgrounds/$selectedImage';
}

// FUNCIÓN DE AYUDA: Mapea los códigos de clima a tus listas de imágenes
Map<String, List<String>> _getImageCollectionForCode(int code) {
  switch (code) {
    // --- DESPEJADO ---
    case 0:
      return {
        'day': [
          'sunny1.jpg',
          'sunny2.jpg',
          'sunny3.jpg',
          'sunny4.jpg',
          'sunny5.jpg',
          'sunny6.jpg',
          'mostly_sunny1.jpg',
          'mostly_sunny2.jpg',
          'mostly_sunny3.jpg',
        ],
        'night': [
          'clear.jpg',
          'clear1.jpg',
          'clear2.jpg',
          'clear3.jpg',
          'clear_with_periodic_clouds.jpg',
          'clear_with_periodic_clouds2.jpg',
        ],
      };

    // --- PARCIALMENTE NUBLADO ---
    case 1:
    case 2:
      return {
        'day': [
          'partly_cloudy_day.jpg',
          'partly_cloudy2.jpg',
          'partly_cloudy3.jpg',
          'partly_cloudy4.jpg',
          'partly_cloudy5.jpg',
          'partly_cloudy6.jpg',
        ],
        'night': [
          'partly_cloudy.jpg',
          'partly_cloudy7.jpg',
          'partly_cloudy8.jpg',
        ],
      };

    // --- NUBLADO ---
    case 3:
      return {
        'day': [
          'cloudy.jpg',
          'cloudy1.jpg',
          'cloudy2.jpg',
          'mostly_cloudy.jpg',
          'mostly_cloudy1.jpg',
          'mostly_cloudy2.jpg',
          'mostly_cloudy3.jpg',
          'mostly_cloudy4.jpg',
          'mostly_cloudy5.jpg',
        ],
        'night': [
          'mostly_cloudy.jpg',
          'mostly_cloudy2.jpg',
          'mostly_cloudy3.jpg',
        ], // Reutilizamos algunas de noche
      };

    // --- NIEBLA ---
    case 45:
    case 48:
      return {
        'day': ['fog.jpg'],
        'night': [
          'fog.jpg',
        ], // Puedes buscar una imagen de niebla nocturna si quieres
      };

    // --- LLOVIZNA Y LLUVIA LIGERA ---
    case 51:
    case 53:
    case 55: // Llovizna
    case 61: // Lluvia ligera
      return {
        'day': [
          'drizzle.jpg',
          'light_rain_showers.jpg',
          'light_rain_showers1.jpg',
          'light_rain_showers2.jpg',
          'light_rain_showers3.jpg',
          'light_rain_showers4.jpg',
        ],
        'night': [
          'light_rain_showers2.jpg',
          'light_rain_showers3.jpg',
        ], // Algunas de ciudad funcionan bien de noche
      };

    // --- LLUVIA MODERADA A FUERTE ---
    case 63:
    case 65: // Lluvia moderada a fuerte
    case 80:
    case 81:
    case 82: // Chubascos
      return {
        'day': ['rain.jpg', 'heavy_rain.jpg', 'heavy_rain1.jpg'],
        'night': ['heavy_rain1.jpg'],
      };

    // --- MEZCLA INVERNAL (AGUANIEVE, LLUVIA HELADA) ---
    case 56:
    case 57: // Llovizna helada
    case 66:
    case 67: // Lluvia helada
      return {
        'day': ['sleet.jpg', 'ice_crystals.jpg'],
        'night': ['sleet.jpg', 'ice_crystals.jpg'],
      };

    // --- NIEVE ---
    case 71:
    case 73:
    case 75:
    case 77: // Nieve
    case 85:
    case 86: // Chubascos de nieve
      return {
        'day': [
          'light_snow.jpg',
          'light_snow1.jpg',
          'light_snow2.jpg',
          'low_drifting_snow.jpg',
        ],
        'night': ['light_snow1.jpg', 'light_snow2.jpg'],
      };

    // --- TORMENTAS ---
    case 95:
    case 96:
    case 99:
      return {
        'day': ['thunderstorm.jpg', 'squalls.jpg'],
        'night': ['thunderstorm.jpg'],
      };

    // --- CASO POR DEFECTO ---
    default:
      return {
        'day': ['partly_cloudy_day.jpg'],
        'night': ['partly_cloudy.jpg'],
      };
  }
}

class RainData {
  final String time;
  final int percentage;
  RainData({required this.time, required this.percentage});
}

class ForecastItem {
  final String time;
  final int weatherCode; // <-- Guardamos el código
  final bool isDay;
  final String temperature;
  ForecastItem({
    required this.time,
    required this.weatherCode,
    required this.isDay,
    required this.temperature,
  });
}

class DayForecast {
  final String dayName;
  final double temperature;
  final double minTemperature;
  final int weatherCode;
  final DateTime date;

  DayForecast({
    required this.dayName,
    required this.temperature,
    this.minTemperature = 0.0,
    this.weatherCode = 0,
    DateTime? date,
  }) : date = date ?? DateTime.now();
}
