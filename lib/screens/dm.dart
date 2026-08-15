import 'package:flutter/material.dart';
import 'package:te_ubicamos/screens/map_screen.dart';
import 'package:te_ubicamos/screens/calificaciones_page.dart';
import 'package:te_ubicamos/screens/feed_screen.dart';
import 'package:te_ubicamos/screens/pagos_screen.dart';

class DMPage extends StatefulWidget {
  final String nombre;
  final List<Map<String, dynamic>> mensajes;

  const DMPage({
    super.key,
    required this.nombre,
    required this.mensajes,
  });

  @override
  State<DMPage> createState() => _DMPageState();
}

class _DMPageState extends State<DMPage> {
  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  

  late List<Map<String, dynamic>> mensajes;
    List<Map<String, dynamic>> trabajos = [];
  
  
  String nombreUsuario = "";

  @override
  void initState() {
    super.initState();
    mensajes = widget.mensajes;
    nombreUsuario = widget.nombre;
  }

  String obtenerHoraActual() {
    final now = TimeOfDay.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _enviarMensaje() {
    if (_mensajeController.text.isNotEmpty) {
      setState(() {
        mensajes.add({
          "texto": _mensajeController.text,
          "esUsuario": true,
          "hora": obtenerHoraActual(),
          "leido": true,
        });
      });

      _mensajeController.clear();

      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Widget burbujaMensaje(Map<String, dynamic> mensaje) {
    bool esUsuario = mensaje["esUsuario"] == true;

    return Container(
      alignment:
          esUsuario ? Alignment.centerRight : Alignment.centerLeft,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: esUsuario ? Colors.green : Colors.grey.shade300,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              mensaje["texto"],
              style: TextStyle(
                color: esUsuario ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  mensaje["hora"],
                  style: TextStyle(
                    fontSize: 11,
                    color: esUsuario
                        ? Colors.white70
                        : Colors.black54,
                  ),
                ),
                const SizedBox(width: 4),
                if (esUsuario)
                  Icon(
                    mensaje["leido"]
                        ? Icons.done_all
                        : Icons.done,
                    size: 16,
                    color: mensaje["leido"]
                        ? Colors.blue
                        : Colors.white70,
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Text(
              widget.nombre,
              style: const TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        onTap: (index) {

          if(index == 0){
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FeedScreen()),
            );
          }


          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => MapScreen(usuarioActual: widget.nombre)),
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
              MaterialPageRoute(builder: (_) => CheckoutScreen(usuarioActual: widget.nombre)),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalificacionesPage(
                  usuario: widget.nombre,
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

      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: mensajes.length,
              itemBuilder: (context, index) {
                return burbujaMensaje(mensajes[index]);
              },
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      hintText: "Mensaje...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.green),
                  onPressed: _enviarMensaje,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}