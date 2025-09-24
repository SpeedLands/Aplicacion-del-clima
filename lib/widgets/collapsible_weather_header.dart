import 'package:clima/controller.dart';
import 'package:clima/data.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CollapsibleWeatherHeader extends StatelessWidget {
  final WeatherData weatherData;

  const CollapsibleWeatherHeader({super.key, required this.weatherData});

  @override
  Widget build(BuildContext context) {
    final WeatherController controller = Get.find<WeatherController>();

    const double expandedHeight = 410.0;
    final double collapsedHeight =
        kToolbarHeight + MediaQuery.of(context).padding.top;

    void showSearchingSnackbar(BuildContext context, String message) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(message, style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          backgroundColor: Colors.purple.shade400,
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }

    void performSearch(
      BuildContext context,
      WeatherController controller,
      String cityName,
    ) {
      Navigator.of(context).pop(); // Cerrar el diálogo
      controller.searchCity(cityName);
      showSearchingSnackbar(context, 'Buscando $cityName...');
    }

    void showSearchDialog(BuildContext context, WeatherController controller) {
      final TextEditingController searchController = TextEditingController();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Título y botón cerrar
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.purple.shade400,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Buscar ciudad',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: Icon(Icons.close, color: Colors.grey.shade600),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),

                    SizedBox(height: 20),

                    // Campo de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: TextField(
                        controller: searchController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Ej: Ciudad de México, Madrid...',
                          hintStyle: TextStyle(color: Colors.grey.shade500),
                          prefixIcon: Icon(
                            Icons.search,
                            color: Colors.grey.shade500,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            performSearch(context, controller, value.trim());
                          }
                        },
                      ),
                    ),

                    SizedBox(height: 20),

                    // Sugerencias rápidas
                    Text(
                      'Ciudades populares:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),

                    SizedBox(height: 24),

                    // Botón de ubicación actual
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          controller.getCurrentLocationWeather();
                          showSearchingSnackbar(
                            context,
                            'Obteniendo ubicación actual...',
                          );
                        },
                        icon: Icon(
                          Icons.my_location,
                          color: Colors.purple.shade400,
                        ),
                        label: Text(
                          'Usar ubicación actual',
                          style: TextStyle(
                            color: Colors.purple.shade400,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.purple.shade200),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

                    // Botón buscar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (searchController.text.trim().isNotEmpty) {
                            performSearch(
                              context,
                              controller,
                              searchController.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple.shade400,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Text(
                          'Buscar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    return SliverAppBar(
      pinned: true,
      stretch: true,
      expandedHeight: expandedHeight,
      backgroundColor: Color(0xFFE1D2F9), // Color de la barra colapsada
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // Título que aparece cuando se colapsa
      title: Obx(
        () => Text(
          weatherData.location,
          style: TextStyle(
            color: controller.isAppBarCollapsed.value
                ? Colors.black
                : Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
            height: 1.40,
          ),
        ),
      ),
      actions: [
        Obx(
          () => IconButton(
            icon: Icon(
              Icons.search,
              color: controller.isAppBarCollapsed.value
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () => showSearchDialog(context, controller),
          ),
        ),
        Obx(
          () => IconButton(
            icon: Icon(
              Icons.my_location,
              color: controller.isAppBarCollapsed.value
                  ? Colors.black
                  : Colors.white,
            ),
            onPressed: () {
              // Get.back()
              controller.getCurrentLocationWeather();
              showSearchingSnackbar(context, 'Obteniendo ubicación actual...');
            },
          ),
        ),
      ],
      flexibleSpace: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double currentHeight = constraints.biggest.height;
          final bool isCurrentlyCollapsed =
              currentHeight <= collapsedHeight + 1.0;

          if (isCurrentlyCollapsed != controller.isAppBarCollapsed.value) {
            // Usamos 'addPostFrameCallback' para actualizar el estado de forma segura
            // DESPUÉS de que el frame actual se haya construido.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              controller.isAppBarCollapsed.value = isCurrentlyCollapsed;
            });
          }

          return FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: const Color(0xFFF6EDFF)),
                // --- Imagen de Fondo ---
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                  child: Image.asset(
                    weatherData.backgroundImage, // DATO: Imagen de fondo
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
                // --- Overlay Oscuro ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(35),
                      bottomRight: Radius.circular(35),
                    ),
                  ),
                ),
                // --- Contenido del Clima ---
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      60,
                      24,
                      15,
                    ), // Ajuste de padding
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 48),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // DATO: Temperatura
                            Text(
                              '${weatherData.temperature}',
                              style: const TextStyle(
                                fontSize: 112,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                                height: 0.57,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(top: 10.0),
                              child: Text(
                                '°',
                                style: TextStyle(
                                  fontSize: 112,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                  height: 0.57,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Padding(
                              padding: const EdgeInsets.only(top: 10.0),
                              child: Column(
                                children: [
                                  // DATO: Icono de la condición
                                  Icon(
                                    weatherData.conditionIcon,
                                    color: Colors.white,
                                    size: 50,
                                  ),
                                  const SizedBox(height: 5),
                                  // DATO: Texto de la condición
                                  Text(
                                    weatherData.condition,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w400,
                                      height: 1.33,
                                      letterSpacing: 0.15,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 18),
                        // DATO: Sensación térmica
                        Text(
                          'Sensación Térmica ${weatherData.feelsLike}°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            height: 1.33,
                            letterSpacing: 0.15,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // DATO: Fecha y hora
                            Text(
                              weatherData.date,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // DATO: Temperatura del día
                                Text(
                                  'Día ${weatherData.dayTemp}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                // DATO: Temperatura de la noche
                                Text(
                                  'Noche ${weatherData.nightTemp}°',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
