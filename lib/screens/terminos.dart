import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Te Ubicamos',
      home: const LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controla la aceptación de los documentos legales.
  bool aceptarTerminos = false;

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5EFEF),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Text(
              "Te Ubicamos",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                hintText: "Correo electrónico",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 15),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "Contraseña",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Checkbox(
                  value: aceptarTerminos,
                  onChanged: (value) {
                    setState(() {
                      aceptarTerminos = value!;
                    });
                  },
                ),

                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [

                        const TextSpan(text: "Acepto los "),

                        TextSpan(
                          text: "Términos de servicio",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const TermsScreen(),
                                ),
                              );
                            },
                        ),

                        const TextSpan(text: " y la "),

                        TextSpan(
                          text: "Política de privacidad",
                          style: const TextStyle(
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const PrivacyScreen(),
                                ),
                              );
                            },
                        ),

                        const TextSpan(
                          text:
                              " y autorizo el tratamiento de mis datos personales.",
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: aceptarTerminos
                    ? () {
                        // Esta pantalla legal todavía no ejecuta el login.
                      }
                    : null,
                child: const Text("Continuar"),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

// Muestra los términos que el usuario debe aceptar.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Términos de Servicio")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            """
Al utilizar esta aplicación aceptas los términos y condiciones del servicio.

1. Uso del servicio
La aplicación permite gestionar servicios de ubicación y comunicación entre usuarios.

2. Responsabilidad
El usuario es responsable del uso de su cuenta.

3. Protección de datos
Los datos serán tratados de acuerdo con la política de privacidad de la aplicación.
            """,
          ),
        ),
      ),
    );
  }
}

// Muestra la política de privacidad de la aplicación.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Política de Privacidad")),
      body: const Padding(
        padding: EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Text(
            """
Política de Privacidad

Recopilamos información como:

* Correo electrónico
* Datos de ubicación
* Información de uso de la aplicación

Estos datos se utilizan únicamente para:

* Mejorar el servicio
* Gestionar la cuenta del usuario
* Seguridad de la plataforma

No compartimos información personal con terceros sin consentimiento.
            """,
          ),
        ),
      ),
    );
  }
}
