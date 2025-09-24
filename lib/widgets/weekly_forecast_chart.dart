import 'package:clima/data.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class WeeklyForecastChart extends StatelessWidget {
  final List<DayForecast> weekData;
  final bool showToday;
  final String title;
  final int maxDaysToShow; // Nuevo parámetro para limitar días

  const WeeklyForecastChart({
    super.key,
    required this.weekData,
    this.showToday = true,
    this.title = 'Pronóstico semanal',
    this.maxDaysToShow = 7, // Por defecto mostrar 7 días
  });

  @override
  Widget build(BuildContext context) {
    if (weekData.isEmpty) {
      return Container(
        height: 219,
        decoration: ShapeDecoration(
          color: const Color(0x4CD0BCFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Center(
          child: Text(
            'No hay datos disponibles',
            style: TextStyle(color: Colors.black54),
          ),
        ),
      );
    }

    // Limitar los datos a mostrar
    final displayData = weekData.take(maxDaysToShow).toList();

    // Determinar si necesitamos mostrar solo algunos días de la semana
    final shouldShowSelectiveLabels = displayData.length > 5;

    // Calcular temperaturas min/max para las etiquetas
    final temperatures = displayData
        .expand((day) => [day.temperature, day.minTemperature])
        .toList();
    final minTemp = temperatures.reduce(math.min).round();
    final maxTemp = temperatures.reduce(math.max).round();

    return Container(
      height: shouldShowSelectiveLabels
          ? 300
          : 270, // Más altura para etiquetas selectivas
      decoration: ShapeDecoration(
        color: const Color(0x4CD0BCFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      padding: EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título con información del rango
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.black87, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
              // Mostrar rango de temperaturas y cantidad de días
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$minTemp° - $maxTemp°',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (weekData.length > maxDaysToShow)
                    Text(
                      '${displayData.length} de ${weekData.length} días',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black45,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
            ],
          ),

          SizedBox(height: 5),

          // Gráfico principal
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                // Etiquetas de temperatura (lado izquierdo)
                _buildTemperatureLabels(minTemp, maxTemp),

                // Gráfico
                Padding(
                  padding: EdgeInsets.only(left: 35),
                  child: CustomPaint(
                    size: Size(double.infinity, double.infinity),
                    painter: OptimizedWeatherChartPainter(
                      displayData,
                      showTodayIndicator: showToday,
                      minTemp: minTemp.toDouble(),
                      maxTemp: maxTemp.toDouble(),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 5),

          // Etiquetas de días (inteligentes según la cantidad)
          Expanded(
            flex: 1,
            child: Padding(
              padding: EdgeInsets.only(left: 35),
              child: _buildDayLabels(
                displayData,
                shouldShowSelectiveLabels,
                context,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemperatureLabels(int minTemp, int maxTemp) {
    final midTemp = ((minTemp + maxTemp) / 2).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$maxTemp°',
          style: TextStyle(
            fontSize: 12,
            color: Colors.orange.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          '$midTemp°',
          style: TextStyle(
            fontSize: 11,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          '$minTemp°',
          style: TextStyle(
            fontSize: 12,
            color: Colors.blue.shade600,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDayLabels(
    List<DayForecast> data,
    bool selective,
    BuildContext context,
  ) {
    if (selective) {
      // Mostrar solo algunos días para evitar sobrecarga
      return _buildSelectiveDayLabels(data, context);
    } else {
      // Mostrar todos los días
      return _buildAllDayLabels(data);
    }
  }

  Widget _buildAllDayLabels(List<DayForecast> data) {
    return Column(
      children: [
        // Nombres de días
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.map((day) {
            final isToday = day.dayName == 'Hoy';
            return Expanded(
              child: Text(
                day.dayName,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isToday ? Colors.purple.shade600 : Colors.black54,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 6),
        // Temperaturas
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: data.map((day) {
            return Expanded(
              child: Column(
                children: [
                  Text(
                    '${day.temperature.round()}°',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.orange.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${day.minTemperature.round()}°',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSelectiveDayLabels(
    List<DayForecast> data,
    BuildContext context,
  ) {
    // Mostrar solo cada 2 días para evitar superposición
    final selectiveIndices = <int>[];
    for (int i = 0; i < data.length; i += 2) {
      selectiveIndices.add(i);
    }
    // Asegurar que el último día siempre se muestre
    if (!selectiveIndices.contains(data.length - 1)) {
      selectiveIndices.add(data.length - 1);
    }

    return Column(
      children: [
        // Fila de nombres y fechas
        SizedBox(
          height: 35,
          child: Stack(
            children: selectiveIndices.map((index) {
              final day = data[index];
              final isToday = day.dayName == 'Hoy';
              final position = (index / (data.length - 1));

              return Positioned(
                left:
                    MediaQuery.of(context).size.width *
                    position *
                    0.65, // Ajustar según el ancho
                child: Container(
                  constraints: BoxConstraints(maxWidth: 60),
                  child: Column(
                    children: [
                      Text(
                        day.dayName.length > 3
                            ? day.dayName.substring(0, 3)
                            : day.dayName,
                        style: TextStyle(
                          fontSize: 11,
                          color: isToday
                              ? Colors.purple.shade600
                              : Colors.black54,
                          fontWeight: isToday
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        DateFormat('M/d').format(day.date),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black45,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      // Temperaturas debajo
                      Text(
                        '${day.temperature.round()}°/${day.minTemperature.round()}°',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class OptimizedWeatherChartPainter extends CustomPainter {
  final List<DayForecast> data;
  final bool showTodayIndicator;
  final double minTemp;
  final double maxTemp;

  OptimizedWeatherChartPainter(
    this.data, {
    required this.showTodayIndicator,
    required this.minTemp,
    required this.maxTemp,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final tempRange = maxTemp - minTemp;
    if (tempRange <= 0) return;

    // Configuración de estilos
    final maxTempPaint = Paint()
      ..color = Colors.orange.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final minTempPaint = Paint()
      ..color = Colors.blue.shade600
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final todayPaint = Paint()
      ..color = Colors.purple.shade300
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Dibujar líneas de cuadrícula horizontales
    for (int i = 0; i <= 4; i++) {
      final y = (i / 4) * size.height;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Función para convertir temperatura a Y
    double tempToY(double temp) {
      final normalized = (temp - minTemp) / tempRange;
      return size.height -
          (normalized * size.height * 0.85) -
          (size.height * 0.075);
    }

    // Crear puntos
    final maxPoints = <Offset>[];
    final minPoints = <Offset>[];
    int todayIndex = -1;

    for (int i = 0; i < data.length; i++) {
      final x = data.length > 1
          ? (i / (data.length - 1)) * size.width
          : size.width / 2;

      maxPoints.add(Offset(x, tempToY(data[i].temperature)));
      minPoints.add(Offset(x, tempToY(data[i].minTemperature)));

      if (data[i].dayName == 'Hoy') todayIndex = i;
    }

    // Dibujar área entre las curvas (opcional)
    if (maxPoints.length > 1) {
      final areaPath = Path();
      areaPath.moveTo(maxPoints.first.dx, maxPoints.first.dy);

      // Línea superior (máximas)
      for (int i = 1; i < maxPoints.length; i++) {
        areaPath.lineTo(maxPoints[i].dx, maxPoints[i].dy);
      }

      // Línea inferior (mínimas) en reverso
      for (int i = minPoints.length - 1; i >= 0; i--) {
        areaPath.lineTo(minPoints[i].dx, minPoints[i].dy);
      }

      areaPath.close();

      canvas.drawPath(
        areaPath,
        Paint()
          ..color = Colors.purple.withValues(alpha: 0.1)
          ..style = PaintingStyle.fill,
      );
    }

    // Dibujar curvas
    _drawSmoothPath(canvas, maxPoints, maxTempPaint);
    _drawSmoothPath(canvas, minPoints, minTempPaint);

    // Dibujar puntos
    for (int i = 0; i < maxPoints.length; i++) {
      final isToday = i == todayIndex;
      final pointSize = isToday ? 6.0 : 4.0;

      // Puntos máximos
      canvas.drawCircle(
        maxPoints[i],
        pointSize,
        Paint()
          ..color = isToday ? Colors.purple.shade600 : Colors.orange.shade600
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        maxPoints[i],
        pointSize,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Puntos mínimos
      canvas.drawCircle(
        minPoints[i],
        pointSize,
        Paint()
          ..color = isToday ? Colors.purple.shade600 : Colors.blue.shade600
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        minPoints[i],
        pointSize,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // Indicador de "hoy"
    if (showTodayIndicator && todayIndex >= 0) {
      final x = maxPoints[todayIndex].dx;
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), todayPaint);
    }
  }

  void _drawSmoothPath(Canvas canvas, List<Offset> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (int i = 1; i < points.length; i++) {
      final controlX =
          points[i - 1].dx + (points[i].dx - points[i - 1].dx) * 0.5;
      path.quadraticBezierTo(
        controlX,
        points[i - 1].dy,
        points[i].dx,
        points[i].dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 6;
    const double dashSpace = 4;
    double distance = (end - start).distance;

    for (double i = 0; i < distance; i += dashWidth + dashSpace) {
      final startPoint = Offset.lerp(start, end, i / distance)!;
      final endPoint = Offset.lerp(start, end, (i + dashWidth) / distance)!;
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
