import 'package:clima/data.dart';
import 'package:flutter/material.dart';

class WeatherForecastCard extends StatelessWidget {
  final List<ForecastItem> forecastData;

  const WeatherForecastCard({super.key, required this.forecastData});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150,
      decoration: ShapeDecoration(
        color: const Color(0x4CD0BCFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con ícono
          Row(
            children: [
              Icon(Icons.schedule, color: Colors.black87, size: 18),
              SizedBox(width: 8),
              Text(
                'Pronóstico',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),

          SizedBox(height: 16),

          // Lista horizontal de pronósticos
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: forecastData.map((forecast) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Hora
                      Text(
                        forecast.time,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Ícono del clima
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: forecast.iconColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          forecast.weatherIcon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),

                      // Temperatura
                      Text(
                        forecast.temperature,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
