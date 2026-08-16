import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:te_ubicamos/screens/feed_screen.dart';
import 'package:te_ubicamos/screens/map_screen.dart';
import 'package:te_ubicamos/screens/dm.dart';
import 'package:te_ubicamos/screens/pagos_screen.dart';
import 'package:flutter/services.dart';

class CalificacionesPage extends StatefulWidget {
  final String usuario;
  final List trabajos;

  const CalificacionesPage({
    super.key,
    required this.usuario,
    required this.trabajos,
  });

  @override
  State<CalificacionesPage> createState() => _CalificacionesPageState();
}

class _CalificacionesPageState extends State<CalificacionesPage> {
  // Datos temporales de la pantalla y del perfil activo.
  List<Map<String, dynamic>> mensajes = [];

  String nombreUsuario = "";
  File? _imagenPerfil;

  String? userPhone;

  late TextEditingController _nombreController;
  final TextEditingController _bioController = TextEditingController();

  String? userRole;
  String? cvUrl;
  bool isOwnProfile = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.usuario);
    nombreUsuario = widget.usuario;
    _loadUserData();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Carga el perfil desde el documento asociado al UID autenticado.
  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getString("usuario_uid");
    final currentUser = prefs.getString("usuario_actual");

    if (!mounted) return;

    setState(() {
      isOwnProfile = widget.usuario == currentUser;
    });

    if (uid != null) {
      final doc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get();

      if (doc.exists && mounted) {
        final data = doc.data()!;

        // Firestore guarda telefono como entero.
        final telefono = data['telefono'] as int?;

        setState(() {
          userRole = data['role'] as String?;
          cvUrl = data['cv_url'] as String?;
          // Se convierte a texto únicamente para mostrarlo
          // dentro del TextEditingController.
          userPhone = telefono?.toString();
        });
      }
    }
  }

  // ======================
  // TRABAJOS DEL USUARIO
  // ======================
  List get trabajosUsuario =>
      widget.trabajos.where((t) => t["usuario"] == widget.usuario).toList();

  // ======================
  // MENU PERFIL
  // ======================
  void _mostrarDialogoEdicion() {
    final formKey = GlobalKey<FormState>();
    final tempNombre = TextEditingController(text: _nombreController.text);
    final tempTelefono = TextEditingController(text: userPhone ?? '');
    final tempEmail = TextEditingController();
    final tempPasswordActual = TextEditingController();
    final tempPassword = TextEditingController();
    final tempBio = TextEditingController(text: _bioController.text);

    //REAUNTETICACION MOD (Email, Password)
    Future<bool> reautenticar(String passwordActual) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      try {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: passwordActual,
        );
        await user.reauthenticateWithCredential(credential);
        return true;
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                e.code == 'wrong-password' || e.code == 'invalid-credential'
                    ? "Contraseña actual incorrecta."
                    : "No se pudo verificar tu identidad: ${e.message}",
              ),
            ),
          );
        }
        return false;
      }
    }

    bool obscurePassword = true;
    bool obscurePasswordActual = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text("Editar perfil"),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: tempNombre,
                        decoration: const InputDecoration(labelText: 'Nombre'),
                      ),
                      TextFormField(
                        controller: tempTelefono,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Teléfono',
                        ),
                      ),
                      TextFormField(
                        controller: tempEmail,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      TextFormField(
                        controller: tempPasswordActual,
                        obscureText: obscurePasswordActual,
                        decoration: InputDecoration(
                          labelText: 'Contraseña actual',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePasswordActual
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setDialogState(() {
                              obscurePasswordActual = !obscurePasswordActual;
                            }),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: tempPassword,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          suffixIcon: IconButton(
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setDialogState(() {
                              obscurePassword = !obscurePassword;
                            }),
                          ),
                        ),
                      ),
                      TextFormField(
                        controller: tempBio,
                        decoration: const InputDecoration(
                          labelText: 'Biografía',
                        ),
                        maxLines: 3,
                      ),
                      if (userRole == "Empleado") ...[
                        const SizedBox(height: 10),
                        if (cvUrl != null)
                          ElevatedButton(
                            onPressed: () async {
                              final uri = Uri.parse(cvUrl!);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri);
                              }
                            },
                            child: const Text("Ver HV"),
                          ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;

                    final authChange =
                        tempEmail.text.isNotEmpty ||
                        tempPassword.text.isNotEmpty;

                    if (authChange) {
                      final reauthenticated = await reautenticar(
                        tempPasswordActual.text,
                      );
                      if (!reauthenticated) return;

                      try {
                        final user = FirebaseAuth.instance.currentUser!;
                        bool emailPending = false;

                        if (tempEmail.text.isNotEmpty) {
                          await user.verifyBeforeUpdateEmail(tempEmail.text);
                          emailPending = true;
                        }

                        if (tempPassword.text.isNotEmpty) {
                          await user.updatePassword(tempPassword.text);
                        }

                        if (context.mounted && emailPending) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Revisa el correo de verificación.",
                              ),
                              duration: Duration(seconds: 5),
                            ),
                          );
                        }
                      } on FirebaseAuthException catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                "Error al actualizar: ${e.message}",
                              ),
                            ),
                          );
                        }
                        return;
                      }
                    }

                    setState(() {
                      _nombreController.text = tempNombre.text;
                      _bioController.text = tempBio.text;
                      userPhone = tempTelefono.text;
                    });

                    final prefs = await SharedPreferences.getInstance();
                    final uid = prefs.getString("usuario_uid");
                    final telefono = int.tryParse(tempTelefono.text.trim());

                    if (telefono == null) {
                      _showSnackBar('El teléfono debe ser numérico');
                      return;
                    }

                    if (uid != null) {
                      await FirebaseFirestore.instance
                          .collection('usuarios')
                          .doc(uid)
                          .update({
                            'nombre': tempNombre.text,
                            'telefono': telefono,
                            'bio': tempBio.text,
                          });
                    }

                    if (!context.mounted) return;
                    Navigator.pop(context);
                  },
                  child: const Text("Guardar"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ======================
  // UI
  // ======================
  @override
  Widget build(BuildContext context) {
    bool isEmpresa = userRole == "Empresa";
    bool isEmpleado = userRole == "Empleado";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Perfil"),
        automaticallyImplyLeading: false,
        actions: isOwnProfile
            ? [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _mostrarDialogoEdicion,
                ),
                IconButton(
                  icon: const Icon(Icons.exit_to_app),
                  color: Colors.red,
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text("Cerrar sesión"),
                        content: const Text(
                          "¿Estás seguro de que quieres cerrar sesión?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () async {
                              final prefs =
                                  await SharedPreferences.getInstance();
                              await FirebaseAuth.instance.signOut();
                              await prefs.remove("usuario_actual");
                              await prefs.remove("usuario_email");
                              await prefs.remove("usuario_uid");
                              await prefs.remove("usuario_role");

                              if (context.mounted) {
                                Navigator.of(
                                  context,
                                ).pushReplacementNamed('/login');
                              }
                            },
                            child: const Text(
                              "Cerrar sesión",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ]
            : null,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedScreen()),
            );
          }

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => MapScreen(usuarioActual: widget.usuario),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    DMPage(nombre: widget.usuario, mensajes: mensajes),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CheckoutScreen(usuarioActual: widget.usuario),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.location_pin), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.messenger), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: ''),
        ],
      ),
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {},
        child: DefaultTabController(
          length: isEmpresa ? 2 : 1,
          child: Column(
            children: [
              const SizedBox(height: 20),
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage: _imagenPerfil != null
                    ? FileImage(_imagenPerfil!)
                    : null,
                child: _imagenPerfil == null
                    ? const Icon(Icons.person, size: 40, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 10),
              Text(
                _nombreController.text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  _bioController.text.isEmpty
                      ? "Biografía"
                      : _bioController.text,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 20),

              // Botón descargar HV si es empleado
              if (isEmpleado && cvUrl != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final uri = Uri.parse(cvUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    },
                    icon: const Icon(Icons.download),
                    label: const Text("Descargar mi hoja de vida"),
                  ),
                ),

              const SizedBox(height: 20),

              // Tabs
              TabBar(
                tabs: isEmpresa
                    ? const [Tab(text: "Publicaciones"), Tab(text: "Historial")]
                    : const [Tab(text: "Historial")],
              ),

              Expanded(
                child: TabBarView(
                  children: isEmpresa
                      ? [
                          // PUBLICACIONES (solo empresa)
                          trabajosUsuario.isEmpty
                              ? const Center(
                                  child: Text("No hay publicaciones"),
                                )
                              : GridView.builder(
                                  itemCount: trabajosUsuario.length,
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 4,
                                        mainAxisSpacing: 4,
                                      ),
                                  itemBuilder: (context, index) {
                                    final trabajo = trabajosUsuario[index];
                                    return Image.memory(
                                      base64Decode(trabajo["imagen"]),
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),

                          // HISTORIAL
                          const Center(
                            child: Text("Historial de empleos (próximamente)"),
                          ),
                        ]
                      : [
                          // HISTORIAL (solo empleado)
                          const Center(
                            child: Text("Historial de empleos (próximamente)"),
                          ),
                        ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
