import 'package:clima/controller.dart';
import 'package:clima/data.dart';
import 'package:clima/widgets/collapsible_weather_header.dart';
import 'package:clima/widgets/login_screen.dart';
import 'package:clima/widgets/persistent_header_delegate.dart';
import 'package:clima/widgets/rain_probability_card.dart';
import 'package:clima/widgets/weather_card.dart';
import 'package:clima/widgets/weather_forecast_card.dart';
import 'package:clima/widgets/weekly_forecast_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong2.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  await initializeDateFormatting('es_ES', null);
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ponemos la barra de estado transparente para una mejor integración visual
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            Brightness.light, // Iconos de la barra de estado en blanco
      ),
    );

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: Obx(
        () => Get.find<WeatherController>().isLoggedIn
            ? const WeatherScreen()
            : LoginRegisterScreen(),
      ),
      initialBinding: BindingsBuilder(() {
        Get.put(WeatherController());
      }),
    );
  }
}

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final WeatherController weatherController = Get.put(WeatherController());
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Obx(() {
      if (weatherController.isLoading.value &&
          weatherController.weatherData.value == null) {
        // Muestra un indicador de carga mientras se obtienen los datos por primera vez.
        return const Center(child: CircularProgressIndicator());
      }
      if (weatherController.errorMessage.value.isNotEmpty &&
          weatherController.weatherData.value == null) {
        final errorMessage = weatherController.errorMessage.value.toLowerCase();

        // Comprueba si el error es por falta de conexión a internet
        if (errorMessage.contains('socketexception') ||
            errorMessage.contains('failed host lookup')) {
          return ErrorDisplayWidget(
            imagePath:
                'assets/backgrounds/offline.jpg', // ¡Asegúrate que la ruta es correcta!
            title: 'Sin Conexión',
            message:
                'Parece que no tienes internet. Por favor, revisa tu conexión.',
            onRetry: () => weatherController
                .getCurrentLocationWeather(), // Asumiendo que esta es tu función para recargar
          );
        } else {
          // Para cualquier otro tipo de error (API, permisos, etc.)
          return ErrorDisplayWidget(
            imagePath:
                'assets/backgrounds/desconocido.jpg', // ¡Asegúrate que la ruta es correcta!
            title: '¡Oh, no!',
            message:
                'Ocurrió un error inesperado al obtener los datos del clima.',
            onRetry: () => weatherController.getCurrentLocationWeather(),
          );
        }
      }

      final data = weatherController.weatherData.value!;
      final currentTabData = weatherController.currentTabData!;

      // Obtener datos de sunrise/sunset según la pestaña actual
      String sunriseTime = '';
      String sunsetTime = '';

      if (weatherController.selectedTabIndex.value == 0) {
        // HOY
        sunriseTime = DateFormat('h:mm a').format(DateTime.parse(data.sunrise));
        sunsetTime = DateFormat('h:mm a').format(DateTime.parse(data.sunset));
      } else if (weatherController.selectedTabIndex.value == 1) {
        // MAÑANA
        sunriseTime = DateFormat(
          'h:mm a',
        ).format(DateTime.parse(data.tomorrowData.sunrise));
        sunsetTime = DateFormat(
          'h:mm a',
        ).format(DateTime.parse(data.tomorrowData.sunset));
      } else {
        // PRÓXIMOS DÍAS - usar datos actuales como referencia
        sunriseTime = DateFormat('h:mm a').format(DateTime.parse(data.sunrise));
        sunsetTime = DateFormat('h:mm a').format(DateTime.parse(data.sunset));
      }

      return Scaffold(
        backgroundColor: const Color(0xFFF3F4F8), // Color de fondo del cuerpo
        body: CustomScrollView(
          slivers: [
            CollapsibleWeatherHeader(weatherData: data),
            SliverPersistentHeader(
              pinned: true, // <-- LA CLAVE PARA QUE SE PEGUE
              delegate: SliverPersistentHeaderDelegateImpl(
                minHeight: weatherController.isAppBarCollapsed.value
                    ? 145.0
                    : 80.0, // Altura que tendrá al estar "pegado"
                maxHeight: weatherController.isAppBarCollapsed.value
                    ? 145.0
                    : 80.0,
                child: Obx(
                  () => Container(
                    color: weatherController.isAppBarCollapsed.value
                        ? Color(0xFFE1D2F9)
                        : Color(0xFFF6EDFF),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        if (weatherController.isAppBarCollapsed.value)
                          Row(
                            verticalDirection: VerticalDirection.down,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${currentTabData.temperature}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 57,
                                  fontWeight: FontWeight.w400,
                                  height: 1.12,
                                ),
                              ),
                              Text(
                                '°',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 57,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w400,
                                  height: 1.12,
                                ),
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (weatherController.selectedTabIndex.value <
                                      2)
                                    Text(
                                      'Sensación Térmica ${weatherController.selectedTabIndex.value == 0 ? data.feelsLike : currentTabData.dayTemp}°',
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w400,
                                        height: 1.50,
                                        letterSpacing: 0.15,
                                      ),
                                    ),
                                  Text(
                                    currentTabData.condition,
                                    style: TextStyle(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              Spacer(),
                              currentTabData.conditionIcon,
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildForecastButton(
                              'Hoy',
                              weatherController.selectedTabIndex.value == 0,
                              () => weatherController.changeTab(0),
                            ),
                            const SizedBox(width: 8),
                            _buildForecastButton(
                              'Mañana',
                              weatherController.selectedTabIndex.value == 1,
                              () => weatherController.changeTab(1),
                            ),
                            const SizedBox(width: 8),
                            _buildForecastButton(
                              '7 días',
                              weatherController.selectedTabIndex.value == 2,
                              () => weatherController.changeTab(2),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 2. El resto del contenido de la página - AHORA DINÁMICO SEGÚN LA PESTAÑA
            SliverToBoxAdapter(
              child: Container(
                color: Color.fromARGB(255, 246, 237, 255),
                padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomPadding),
                child: _buildTabContent(
                  weatherController,
                  data,
                  currentTabData,
                  sunriseTime,
                  sunsetTime,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildTabContent(
    WeatherController controller,
    WeatherData data,
    TabWeatherData currentTabData,
    String sunriseTime,
    String sunsetTime,
  ) {
    switch (controller.selectedTabIndex.value) {
      case 0: // HOY
        return _buildTodayContent(
          controller,
          data,
          currentTabData,
          sunriseTime,
          sunsetTime,
        );
      case 1: // MAÑANA
        return _buildTomorrowContent(
          controller,
          data,
          currentTabData,
          sunriseTime,
          sunsetTime,
        );
      case 2: // PRÓXIMOS 7 DÍAS
        return _buildWeeklyContent(controller, data);
      default:
        return _buildTodayContent(
          controller,
          data,
          currentTabData,
          sunriseTime,
          sunsetTime,
        );
    }
  }

  Widget _buildTodayContent(
    WeatherController controller,
    WeatherData data,
    TabWeatherData currentTabData,
    String sunriseTime,
    String sunsetTime,
  ) {
    return Column(
      children: [
        WeatherStatsGrid(
          windSpeed: '${data.windSpeed} km/h',
          windChange: data.windChange,
          rainProbability: '${data.rainProbability}',
          rainChange: '${data.rainChange}%',
          atmosphericPressure: '${data.pressure} hpa',
          pressureChange: data.pressureChange,
          uvIndex: data.uvIndex.toString(),
          uvChange: '- ${data.uvChange}',
          cardColor: Color(0x4CD0BCFF),
        ),
        _buildLocationMap(data),
        SizedBox(height: 16),
        WeatherForecastCard(forecastData: currentTabData.forecastData),
        SizedBox(height: 16),
        WeeklyForecastChart(weekData: data.weeklyData),
        SizedBox(height: 16),
        RainProbabilityCard(hourlyData: currentTabData.rainData),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: WeatherStatCard(
                icon: Icons.wb_sunny,
                title: 'Amanecer',
                mainValue: sunriseTime,
                changeValue: data.sunriseChangeValue,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: WeatherStatCard(
                icon: Icons.wb_twilight,
                title: 'Anochecer',
                mainValue: sunsetTime,
                changeValue: data.sunsetChangeValue,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTomorrowContent(
    WeatherController controller,
    WeatherData data,
    TabWeatherData currentTabData,
    String sunriseTime,
    String sunsetTime,
  ) {
    return Column(
      children: [
        // Resumen del día de mañana
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Color(0x4CD0BCFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de mañana',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTomorrowStat('Máxima', '${currentTabData.dayTemp}°'),
                  _buildTomorrowStat('Mínima', '${currentTabData.nightTemp}°'),
                  _buildTomorrowStat('UV', '${currentTabData.uvIndex.round()}'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Pronóstico por horas si está disponible
        if (currentTabData.forecastData.isNotEmpty) ...[
          WeatherForecastCard(forecastData: currentTabData.forecastData),
          SizedBox(height: 16),
        ],

        // Datos de lluvia si están disponibles
        if (currentTabData.rainData.isNotEmpty) ...[
          RainProbabilityCard(hourlyData: currentTabData.rainData),
          SizedBox(height: 16),
        ],

        // Sunrise y sunset de mañana
        Row(
          children: [
            Expanded(
              child: WeatherStatCard(
                icon: Icons.wb_sunny,
                title: 'Amanecer',
                mainValue: sunriseTime,
                changeValue: '', // Sin cambio para mañana
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: WeatherStatCard(
                icon: Icons.wb_twilight,
                title: 'Anochecer',
                mainValue: sunsetTime,
                changeValue: '', // Sin cambio para mañana
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWeeklyContent(WeatherController controller, WeatherData data) {
    final weeklyData = controller.weeklyForecastData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pronóstico de 7 días',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 16),

        // Gráfico semanal mejorado
        WeeklyForecastChart(weekData: weeklyData),
        SizedBox(height: 16),

        // Lista detallada de días
        for (int index = 0; index < weeklyData.take(7).length; index++)
          Builder(
            builder: (context) {
              final day = weeklyData[index];
              return Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0x4CD0BCFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // Día
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            day.dayName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                          if (index <
                              3) // Solo mostrar fecha para los primeros días
                            Text(
                              DateFormat('MMM d').format(day.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.black.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Ícono del clima
                    getWeatherIcon(
                      code: day.weatherCode,
                      isDay:
                          true, // Para el pronóstico semanal, es más claro usar siempre los íconos de día
                      size:
                          32, // Ajusta el tamaño como prefieras, 32 podría verse mejor que 28
                    ),
                    SizedBox(width: 16),

                    // Temperaturas
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${day.temperature.round()}°',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '${day.minTemperature.round()}°',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.black.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildTomorrowStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastButton(
    String text,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? const Color.fromARGB(255, 224, 182, 255)
              : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: isSelected ? 4 : 1,
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.black,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationMap(WeatherData data) {
    final lat = data.latitude;
    final lon = data.longitude;

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: FlutterMap(
          options: MapOptions(
            initialCenter: LatLng(lat, lon),
            initialZoom: 13.0,
            onTap: (tapPosition, point) {
              final weatherController = Get.find<WeatherController>();
              weatherController.fetchWeatherData(point.latitude, point.longitude);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.clima',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  width: 80.0,
                  height: 80.0,
                  point: LatLng(lat, lon),
                  child: const Icon(
                    Icons.location_pin,
                    color: Colors.red,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Coloca esta nueva clase en tu archivo

class ErrorDisplayWidget extends StatelessWidget {
  final String imagePath;
  final String title;
  final String message;
  final VoidCallback onRetry;

  const ErrorDisplayWidget({
    super.key,
    required this.imagePath,
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8), // Un color de fondo suave
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // La imagen de la ranita
              Image.asset(imagePath, height: 200, fit: BoxFit.contain),
              const SizedBox(height: 24),

              // Título del error
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),

              // Mensaje del error
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.black54),
              ),
              const SizedBox(height: 32),

              // Botón para reintentar
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  'Volver a intentar',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 140, 93, 201),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
