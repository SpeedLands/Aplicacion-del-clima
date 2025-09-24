import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherData {
  final String location;
  final int temperature;
  final String condition;
  final IconData conditionIcon;
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
    required this.location,
    required this.temperature,
    required this.condition,
    required this.conditionIcon,
    required this.feelsLike,
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
        : _formatDuration(now.difference(sunsetTime), 'finalizó hace');

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
          weatherIcon: _getIconForCode(hourlyWeatherCodes[i]),
          iconColor: _getColorForCode(
            hourlyWeatherCodes[i],
            time.hour > 6 && time.hour < 19,
          ),
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
              weatherIcon: _getIconForCode(hourlyWeatherCodes[i]),
              iconColor: _getColorForCode(
                hourlyWeatherCodes[i],
                time.hour > 6 && time.hour < 19,
              ),
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
          ? _getIconForCode(daily['weather_code'][1])
          : Icons.help,
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
      location: cityName ?? 'Ubicación actual',
      temperature: (current['temperature_2m'] as num).round(),
      condition: _getWeatherDescription(current['weather_code']),
      conditionIcon: _getIconForCode(current['weather_code']),
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
          conditionIcon: Icons.calendar_today,
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
  final IconData conditionIcon;
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
  final IconData conditionIcon;
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

IconData _getIconForCode(int code) {
  if (code == 0) return Icons.wb_sunny;
  if (code <= 3) return Icons.cloud;
  return Icons.cloud_queue;
}

Color _getColorForCode(int code, bool isDay) {
  if (code == 0 && isDay) return Colors.orange;
  if (code <= 3) return Colors.grey;
  return Colors.blueGrey;
}

String _getWeatherAnimation(int weatherCode, bool isDay) {
  if (weatherCode == 0) {
    return isDay ? 'assets/clear.jpg' : 'assets/clear.jpg';
  }
  if (weatherCode <= 3) return 'assets/clear.jpg';
  return 'assets/clear.jpg';
}

class RainData {
  final String time;
  final int percentage;
  RainData({required this.time, required this.percentage});
}

class ForecastItem {
  final String time;
  final IconData weatherIcon;
  final Color iconColor;
  final String temperature;
  ForecastItem({
    required this.time,
    required this.weatherIcon,
    required this.iconColor,
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
