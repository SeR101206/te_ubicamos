import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes escribir el correo y la contraseña")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1) LOGIN CON FIREBASE AUTH
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String uid = userCredential.user!.uid;
      String email = userCredential.user!.email ?? _emailController.text.trim();

      // 2) BUSCAR USUARIO EN FIRESTORE POR UID
      final docUid = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      Map<String, dynamic>? userData;

      if (docUid.exists) {
        userData = docUid.data();
      } else {
        // 3) SI NO EXISTE POR UID, BUSCAR POR EMAIL (usuarios viejos)
        final query = await FirebaseFirestore.instance
            .collection('usuarios')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();

        if (query.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text("No existe información del usuario en Firestore")),
          );
          return;
        }

        final oldDoc = query.docs.first;
        userData = oldDoc.data();

        // 4) MIGRAR AUTOMÁTICAMENTE: GUARDAR EL DOC CON UID
        userData['uid'] = uid;
        userData['email'] = email;

        await FirebaseFirestore.instance
            .collection('usuarios')
            .doc(uid)
            .set(userData);

        // Opcional: eliminar el documento viejo si era doc(email)
        // await FirebaseFirestore.instance
        //     .collection('usuarios')
        //     .doc(oldDoc.id)
        //     .delete();
      }

      if (userData == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Error cargando datos del usuario")),
        );
        return;
      }

      // 5) GUARDAR EN SHARED PREFERENCES
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString("usuario_uid", uid);
      await prefs.setString("usuario_actual", userData['nombre'] ?? "");
      await prefs.setString("usuario_email", userData['email'] ?? email);
      await prefs.setString("usuario_role", userData['role'] ?? "");

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/feed');
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al iniciar sesión";

      if (e.code == "user-not-found") {
        mensaje = "Usuario no encontrado";
      } else if (e.code == "wrong-password") {
        mensaje = "Contraseña incorrecta";
      } else if (e.code == "invalid-email") {
        mensaje = "Correo inválido";
      } else if (e.code == "invalid-credential") {
        mensaje = "Credenciales inválidas";
      } else {
        mensaje = e.message ?? "Error desconocido";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error inesperado: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Iniciar Sesión"),
        automaticallyImplyLeading: false,
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: _isLoading
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        height: 250,
                      ),
                      const Text(
                        "Te Ubicamos",
                        style: TextStyle(
                            fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),

                      TextField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "Correo electrónico",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                          border: OutlineInputBorder(),
                        ),
                      ),

                      const SizedBox(height: 25),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: _login,
                          child: const Text(
                            "Continuar",
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Text(
                        "Términos de servicio • Política de privacidad",
                        style: TextStyle(fontSize: 12),
                      ),

                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushNamed('/register');
                        },
                        child: const Text(
                          "Crea una cuenta",
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}