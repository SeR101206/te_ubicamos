import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Pantalla principal de inicio de sesión.
///
/// Permite autenticarse usando:
/// - Correo electrónico.
/// - Nombre de usuario.
///
/// Firebase Auth siempre recibe un correo internamente.
/// Cuando el usuario escribe un username, primero se busca
/// su correo asociado en Firestore.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controla el campo que puede contener correo o username.
  late final TextEditingController _identifierController;

  // Controla el campo de contraseña.
  late final TextEditingController _passwordController;

  // Indica si se está ejecutando una operación de autenticación.
  bool _isLoading = false;

  // false: login por correo.
  // true: login por username.
  bool _loginWithUsername = false;

  @override
  void initState() {
    super.initState();

    // Inicializa los controladores una sola vez.
    _identifierController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    // Libera los controladores para evitar fugas de memoria.
    _identifierController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  /// Normaliza el username antes de guardarlo o buscarlo.
  String _normalizeUsername(String value) {
    return value.trim().toLowerCase();
  }

  /// Muestra mensajes de forma segura.
  ///
  /// La validación de [mounted] evita usar el contexto
  /// si la pantalla ya fue destruida.
  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Obtiene el correo asociado al username para poder
  /// autenticar al usuario mediante Firebase Auth.
  Future<String?> _getEmailFromUsername(String username) async {
    final normalizedUsername = username.trim().toLowerCase();

    // Cada documento usa el username como identificador.
    final result = await FirebaseFirestore.instance
        .collection('login_users')
        .doc(normalizedUsername)
        .get();

    if (!result.exists) {
      return null;
    }

    // Devuelve el correo que Firebase Auth necesita.
    final data = result.data();
    final email = data?['email'];

    return email is String ? email : null;
  }

  /// Obtiene los datos del usuario usando su UID de Firebase Auth.
  Future<Map<String, dynamic>?> _loadUserData({
    required String uid,
  }) async {
    final userByUid = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get();

    // El documento debe existir como usuarios/{uid}.
    return userByUid.exists ? userByUid.data() : null;
  }

  /// Guarda los datos mínimos de la sesión local.
  ///
  /// SharedPreferences permite recuperar información básica
  /// del usuario en otras pantallas sin consultar Firestore
  /// nuevamente para cada dato.
  Future<void> _saveSession({
    required String uid,
    required String email,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Se comprueba el tipo de cada valor antes de guardarlo.
    final nombre = userData['nombre'] is String
        ? userData['nombre'] as String
        : '';

    final storedEmail = userData['email'] is String
        ? userData['email'] as String
        : email;

    final role = userData['role'] is String
        ? userData['role'] as String
        : '';

    // Las operaciones locales se ejecutan juntas.
    await Future.wait([
      prefs.setString('usuario_uid', uid),
      prefs.setString('usuario_actual', nombre),
      prefs.setString('usuario_email', storedEmail),
      prefs.setString('usuario_role', role),
    ]);
  }

  /// Ejecuta todo el flujo de autenticación.
  ///
  /// Flujo:
  /// 1. Valida los campos.
  /// 2. Si se eligió username, busca su correo.
  /// 3. Autentica con Firebase Auth.
  /// 4. Carga los datos adicionales desde Firestore.
  /// 5. Guarda la sesión local.
  /// 6. Navega al feed.
  Future<void> _login() async {
    // El identificador puede ser un correo o un username.
    final identifier = _identifierController.text.trim();

    // No se debe usar trim() en la contraseña porque podría modificarla.
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      _showMessage('Debes completar todos los campos');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String emailForAuth;

      if (_loginWithUsername) {
        // Convierte el username en el correo usado por Firebase Auth.
        final username = _normalizeUsername(identifier);
        final resolvedEmail = await _getEmailFromUsername(username);

        if (resolvedEmail == null || resolvedEmail.isEmpty) {
          _showMessage('Usuario o contraseña incorrectos');
          return;
        }

        emailForAuth = resolvedEmail;
      } else {
        // En este modo el usuario ya proporciona directamente su correo.
        emailForAuth = identifier.toLowerCase();
      }

      // Firebase Auth valida el correo y la contraseña.
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailForAuth,
        password: password,
      );

      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        _showMessage('No fue posible identificar al usuario');
        return;
      }

      final uid = firebaseUser.uid;
      final email = firebaseUser.email ?? emailForAuth;

      // Se cargan los datos adicionales guardados en Firestore.
      final userData = await _loadUserData(
        uid: uid,
      );

      if (userData == null) {
        _showMessage(
          'No existe información del usuario en Firestore',
        );
        return;
      }

      // Se guarda la sesión para que otras pantallas
      // puedan recuperar los datos básicos del usuario.
      await _saveSession(
        uid: uid,
        email: email,
        userData: userData,
      );

      if (!mounted) return;

      // Reemplaza el login para evitar volver a él
      // al presionar el botón atrás.
      Navigator.of(context).pushReplacementNamed('/feed');
    } on FirebaseAuthException catch (error) {
      // Se utiliza un mensaje genérico para no revelar
      // si el correo está registrado o no.
      var message = 'Usuario o contraseña incorrectos';

      if (error.code == 'invalid-email') {
        message = 'El correo electrónico no es válido';
      }

      _showMessage(message);
    } catch (error) {
      // Error inesperado de Firestore, red o configuración.
      _showMessage('Error inesperado al iniciar sesión');
    } finally {
      // El indicador de carga se oculta siempre,
      // incluso si ocurre un error o se usa return.
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sesión'),
        automaticallyImplyLeading: false,
      ),

      // Evita que el usuario vuelva atrás desde el login.
      body: PopScope(
        canPop: false,
        child: SafeArea(
          // Permite desplazarse cuando aparece el teclado.
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              // Limita el ancho en tablets y pantallas grandes.
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                ),
                child: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.only(top: 200),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 200,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(height: 16),

                          const Text(
                            'Te Ubicamos',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Permite elegir correo o username.
                          SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment<bool>(
                                value: false,
                                label: Text('Correo'),
                                icon: Icon(Icons.email),
                              ),
                              ButtonSegment<bool>(
                                value: true,
                                label: Text('Usuario'),
                                icon: Icon(Icons.person),
                              ),
                            ],
                            selected: <bool>{_loginWithUsername},
                            onSelectionChanged: (selection) {
                              setState(() {
                                _loginWithUsername = selection.first;

                                // Evita que un correo quede escrito
                                // al cambiar al modo username.
                                _identifierController.clear();
                              });
                            },
                          ),

                          const SizedBox(height: 20),

                          // Campo para correo o username.
                          TextField(
                            controller: _identifierController,
                            keyboardType: _loginWithUsername
                                ? TextInputType.text
                                : TextInputType.emailAddress,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: _loginWithUsername
                                  ? 'Nombre de usuario'
                                  : 'Correo electrónico',
                              hintText: _loginWithUsername
                                  ? 'Ejemplo: sergio123'
                                  : 'Ejemplo: correo@dominio.com',
                              prefixIcon: Icon(
                                _loginWithUsername
                                    ? Icons.person
                                    : Icons.email,
                              ),
                              border: const OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Campo independiente para la contraseña.
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                          ),

                          const SizedBox(height: 25),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text('Continuar'),
                            ),
                          ),

                          const SizedBox(height: 10),

                          const Text(
                            'Términos de servicio • Política de privacidad',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12),
                          ),

                          const SizedBox(height: 20),

                          // TextButton aporta mejor accesibilidad
                          // que GestureDetector para una acción textual.
                          TextButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pushNamed('/register');
                            },
                            child: const Text('Crea una cuenta'),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
