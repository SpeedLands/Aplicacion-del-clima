import 'package:clima/data.dart';
import 'package:flutter/material.dart';

// (Pega la clase RainData de arriba aquí)

class RainProbabilityCard extends StatelessWidget {
  // Lista de datos que el widget mostrará
  final List<RainData> hourlyData;

  // Colores para personalización (opcional)
  final Color backgroundColor;
  final Color barColor;
  final Color trackColor; // Color de fondo de la barra

  const RainProbabilityCard({
    super.key,
    required this.hourlyData,
    this.backgroundColor = const Color(0x4CD0BCFF), // Morado muy claro
    this.barColor = const Color(0xFF6A3DE8), // Morado intenso
    this.trackColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min, // Para que la tarjeta se ajuste al contenido
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila del Título: "Probabilidad de Lluvia"
          _buildHeader(),
          const SizedBox(height: 16),
          // Construye una fila por cada dato en la lista
          ...hourlyData.map((data) => _buildRainChanceRow(data)),
        ],
      ),
    );
  }

  // Widget para el encabezado
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.cloudy_snowing, // Icono que se parece al de lluvia
            color: Colors.grey[700],
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Probabilidad de Lluvia',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Color(0xFF333333),
          ),
        ),
      ],
    );
  }

  // Widget para cada fila de la barra de probabilidad
  Widget _buildRainChanceRow(RainData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // 1. Etiqueta de la hora
          SizedBox(
            width: 65, // Ancho fijo para alinear las barras
            child: Text(
              data.time,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF555555),
              ),
            ),
          ),

          // 2. Barra de progreso
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Stack(
                children: [
                  // Fondo de la barra
                  Container(height: 22, color: trackColor),
                  // Barra de progreso llenada según el porcentaje
                  FractionallySizedBox(
                    widthFactor: data.percentage / 100.0,
                    child: Container(
                      height: 22,
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Etiqueta del porcentaje
          SizedBox(
            width: 50, // Ancho fijo para alinear
            child: Text(
              '${data.percentage}%',
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF555555),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
