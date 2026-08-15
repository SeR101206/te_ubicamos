import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:te_ubicamos/screens/calificaciones_page.dart';
import 'package:te_ubicamos/screens/dm.dart';
import 'package:te_ubicamos/screens/map_screen.dart';
import 'package:te_ubicamos/screens/pagos_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen>
    with TickerProviderStateMixin {

  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> mensajes = [];
  List<Map<String, dynamic>> trabajos = [];
  
  
  String nombreUsuario = "";
  String? userRole;

  @override
  void initState() {
    super.initState();
    cargarUsuario();
    cargarDatos();
  }
  Future<void> cargarUsuario() async {

  final prefs = await SharedPreferences.getInstance();

  String? usuario = prefs.getString("usuario_actual");
  String? email = prefs.getString("usuario_email");

  setState(() {
    nombreUsuario = usuario ?? "Usuario";
  });

  if (email != null) {
    final doc = await FirebaseFirestore.instance.collection('usuarios').doc(email).get();
    if (doc.exists) {
      setState(() {
        userRole = doc.data()!['role'];
      });
    }
  }

}

  Future<void> guardarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString("trabajos", jsonEncode(trabajos));
  }

  Future<void> cargarDatos() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString("trabajos");

    if (data != null) {
      setState(() {
        trabajos = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  Future<void> subirImagen() async {
    final XFile? imagen =
        await _picker.pickImage(source: ImageSource.gallery);

    if (imagen == null) return;

    TextEditingController descripcionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Agregar descripción"),
          content: TextField(
            controller: descripcionController,
            decoration: const InputDecoration(
              hintText: "Escribe una descripción...",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () async {
                final bytes = await imagen.readAsBytes();
                final base64Str = base64Encode(bytes);

                setState(() {
                  trabajos.insert(0, {
                    "usuario": nombreUsuario,
                    "imagen": base64Str,
                    "descripcion": descripcionController.text,
                    "likes": 0,
                    "liked": false,
                    "comentarios": [],
                  });
                });

                guardarDatos();

                Navigator.pop(context);
              },
              child: const Text("Publicar"),
            ),
          ],
        );
      },
    );
  }

  void toggleLike(int index) {
    setState(() {
      trabajos[index]["liked"] = !trabajos[index]["liked"];

      trabajos[index]["likes"] += trabajos[index]["liked"] ? 1 : -1;
    });

    guardarDatos();
  }

  void agregarComentario(int index, String comentario) {
    setState(() {
      trabajos[index]["comentarios"].add({
        "usuario": nombreUsuario,
        "texto": comentario,
      });
    });

    guardarDatos();
  }

  void mostrarDialogoComentario(int index) {
    TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Agregar comentario"),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: "Escribe tu comentario"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                agregarComentario(index, controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Publicar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text("Trabajos"),
        automaticallyImplyLeading: false,
        actions: userRole != "Empleado" ? [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            onPressed: subirImagen,
          )
        ] : null,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {

          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapScreen(usuarioActual: nombreUsuario)),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DMPage(
                  nombre: nombreUsuario,
                  mensajes: mensajes,
              )),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckoutScreen(usuarioActual: nombreUsuario)),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalificacionesPage(
                  usuario: nombreUsuario,
                  trabajos: trabajos,
                ),
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
        onPopInvokedWithResult: (didPop, result) {
          // Bloquea completamente la navegación hacia atrás
        },
        child: trabajos.isEmpty
            ? const Center(child: Text("No hay trabajos aún"))
            : ListView.builder(
              itemCount: trabajos.length,
              itemBuilder: (context, index) {

                final trabajo = trabajos[index];

                return Card(
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [

                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CalificacionesPage(
                                      usuario: trabajo["usuario"],
                                      trabajos: trabajos,
                                    ),
                                  ),
                                );
                              },
                              child: const CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, color: Colors.white),
                              ),
                            ),

                            const SizedBox(width: 8),

                            Text(trabajo["usuario"] ?? "Usuario",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Image.memory(
                        base64Decode(trabajo["imagen"]),
                        fit: BoxFit.cover,
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        child: Text(
                          "${trabajo["usuario"] ?? "Usuario"} ${trabajo["descripcion"] ?? ""}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [

                            AnimatedScale(
                              duration: const Duration(milliseconds: 200),
                              scale: trabajo["liked"] ? 1.3 : 1.0,
                              child: IconButton(
                                icon: Icon(
                                  trabajo["liked"]
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: trabajo["liked"]
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: () {
                                  toggleLike(index);
                                },
                              ),
                            ),

                            Text("${trabajo["likes"]}"),

                            const SizedBox(width: 20),

                            IconButton(
                              icon: const Icon(Icons.comment),
                              onPressed: () {
                                mostrarDialogoComentario(index);
                              },
                            ),

                            Text("${(trabajo["comentarios"] ?? []).length}")
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            trabajo["comentarios"].length,
                            (i) {

                              final comentario =
                                  trabajo["comentarios"][i];

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "${comentario["usuario"] ?? "Usuario"}: ${comentario["texto"] ?? ""}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              );
                            },
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                    ],
                  ),
                );
              },
            ),
        ),
    );
  }
}

