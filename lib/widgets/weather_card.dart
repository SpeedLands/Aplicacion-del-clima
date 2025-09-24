import 'package:flutter/material.dart';

class WeatherStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String mainValue;
  final String changeValue;
  final Color backgroundColor;

  const WeatherStatCard({
    super.key,
    required this.icon,
    required this.title,
    required this.mainValue,
    required this.changeValue,
    this.backgroundColor = const Color(0xFFE8D5FF),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            decoration: ShapeDecoration(
              color: const Color(0xFFFFFBFF),
              shape: OvalBorder(),
            ),
            child: Icon(icon, color: Colors.black, size: 24),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      mainValue,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Spacer(),
                    Text(
                      changeValue,
                      style: TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Widget contenedor para mostrar las 4 cards en formato 2x2
class WeatherStatsGrid extends StatelessWidget {
  final String windSpeed;
  final String windChange;
  final String rainProbability;
  final String rainChange;
  final String atmosphericPressure;
  final String pressureChange;
  final String uvIndex;
  final String uvChange;
  final Color cardColor;

  const WeatherStatsGrid({
    super.key,
    required this.windSpeed,
    required this.windChange,
    required this.rainProbability,
    required this.rainChange,
    required this.atmosphericPressure,
    required this.pressureChange,
    required this.uvIndex,
    required this.uvChange,
    this.cardColor = const Color(0xFFE8D5FF),
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Primera fila
        Row(
          children: [
            Expanded(
              child: WeatherStatCard(
                icon: Icons.air,
                title: 'Viento',
                mainValue: windSpeed,
                changeValue: windChange,
                backgroundColor: cardColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: WeatherStatCard(
                icon: Icons.grain,
                title: 'Probabilidad',
                mainValue: rainProbability,
                changeValue: rainChange,
                backgroundColor: cardColor,
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        // Segunda fila
        Row(
          children: [
            Expanded(
              child: WeatherStatCard(
                icon: Icons.thermostat,
                title: 'Ambiente',
                mainValue: atmosphericPressure,
                changeValue: pressureChange,
                backgroundColor: cardColor,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: WeatherStatCard(
                icon: Icons.wb_sunny,
                title: 'UV Index',
                mainValue: uvIndex,
                changeValue: uvChange,
                backgroundColor: cardColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
