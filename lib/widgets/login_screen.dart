import 'package:clima/controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Definimos un color principal para el tema
const Color primaryColor = Color(0xFF4A90E2);
const Color accentColor = Color(0xFF63B8FF);

class LoginRegisterScreen extends StatelessWidget {
  final WeatherController _weatherController = Get.find<WeatherController>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final RxBool _isLogin =
      true.obs; // Observable para alternar entre Login/Registro

  LoginRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Extiende el cuerpo detrás de la barra
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: Obx(
          () => Text(
            _isLogin.value ? 'Bienvenido' : 'Crear Cuenta',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Container(
        // Fondo con gradiente inspirado en el cielo
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [primaryColor, accentColor],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono grande de la aplicación (o logo)
                const Icon(Icons.cloud, color: Colors.white, size: 100),
                const SizedBox(height: 30),

                // Tarjeta de Contenido (Login/Registro)
                Obx(() => _buildFormCard(context)),

                const SizedBox(height: 20),

                // Botón para alternar entre Login y Registro
                Obx(() {
                  return TextButton(
                    onPressed: () {
                      _isLogin.value = !_isLogin.value;
                      _emailController.clear();
                      _passwordController.clear();
                    },
                    child: Text(
                      _isLogin.value
                          ? '¿No tienes una Cuenta? Regístrate'
                          : '¿Ya tienes una cuenta? Inicia Sesión',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    final bool isLogin = _isLogin.value;
    final theme = Theme.of(context);

    return Card(
      color: Colors.white.withValues(
        alpha: 0.95,
      ), // Fondo ligeramente transparente
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            Text(
              isLogin ? 'Iniciar Sesión' : 'Registro',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 25),

            _buildTextField(
              controller: _emailController,
              label: 'Correo Electrónico',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            _buildTextField(
              controller: _passwordController,
              label: 'Contraseña',
              icon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 30),

            Obx(() {
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _weatherController.isLoading.value
                      ? null
                      : () {
                          if (isLogin) {
                            _weatherController.login(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          } else {
                            _weatherController.register(
                              _emailController.text.trim(),
                              _passwordController.text.trim(),
                            );
                          }
                        },
                  child: _weatherController.isLoading.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          isLogin ? 'ACCEDER' : 'REGISTRARME',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 10,
        ),
      ),
    );
  }
}
