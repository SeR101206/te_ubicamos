import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:te_ubicamos/screens/calificaciones_page.dart';
import 'package:te_ubicamos/screens/dm.dart';
import 'package:te_ubicamos/screens/feed_screen.dart';

// Modelo de datos para empresas
class Empresa {
  final String nombre;
  final double calificacion;
  final String ubicacion;
  final List<String> resenas;
  final LatLng posicion;

  Empresa({
    required this.nombre,
    required this.calificacion,
    required this.ubicacion,
    required this.resenas,
    required this.posicion,
  });
}

class MapScreen extends StatefulWidget {
  final String usuarioActual;
  const MapScreen({super.key, this.usuarioActual = ''});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Map<String, dynamic>> mensajes = [];
  late GoogleMapController mapController;

  final LatLng _initialPosition = const LatLng(4.6097, -74.0817); // Bogotá

  // Lista de empresas de ejemplo
  late final List<Empresa> empresas = [
    Empresa(
      nombre: "Restaurante El Sabor",
      calificacion: 4.5,
      ubicacion: "Cra 7 #100-50",
      resenas: [
        "Excelente comida, muy recomendado",
        "Buen servicio y ambiente acogedor",
        "Precios muy competitivos"
      ],
      posicion: const LatLng(4.6097, -74.0817),
    ),
    Empresa(
      nombre: "Café Aroma",
      calificacion: 4.8,
      ubicacion: "Cra 11 #85-30",
      resenas: [
        "Café delicioso, los mejores postres",
        "Lugar perfecto para trabajar",
        "Atención excepcional"
      ],
      posicion: const LatLng(4.6150, -74.0800),
    ),
    Empresa(
      nombre: "Pizzería La Tradición",
      calificacion: 4.2,
      ubicacion: "Cra 5 #72-15",
      resenas: [
        "Pizzas auténticas y deliciosas",
        "Entrega rápida",
        "Personal amable y puntual"
      ],
      posicion: const LatLng(4.6050, -74.0850),
    ),
    Empresa(
      nombre: "Heladería Fría",
      calificacion: 4.6,
      ubicacion: "Cra 9 #95-20",
      resenas: [
        "Helados artesanales de alta calidad",
        "Variedad de sabores deliciosos",
        "Lugar limpio y bien organizado"
      ],
      posicion: const LatLng(4.6120, -74.0780),
    ),
  ];

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    backgroundColor: Colors.white,

    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text("Te Ubicamos - Negocios Cercanos"),
      backgroundColor: const Color.fromARGB(255, 139, 231, 127),
      centerTitle: true,
    ),

    body: GoogleMap(
      onMapCreated: _onMapCreated,
      initialCameraPosition: CameraPosition(
        target: _initialPosition,
        zoom: 14,
      ),

      markers: {
        Marker(
          markerId: const MarkerId("inicio"),
          position: _initialPosition,
          infoWindow: const InfoWindow(title: "Tu ubicación"),
        ),

        ...empresas.map((empresa) {
          return Marker(
            markerId: MarkerId(empresa.nombre),
            position: empresa.posicion,
            infoWindow: InfoWindow(
              title: empresa.nombre,
              snippet: "⭐ ${empresa.calificacion}",
            ),
          );
        }).toSet(),
      },
    ),

    bottomNavigationBar: BottomNavigationBar(
      currentIndex: 1, // Mapa activo

      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.grey,

     onTap: (index) async {
  if (index == 4) {
    final navigator = Navigator.of(context);
    final usuarioActual = widget.usuarioActual;
    if (!mounted) return;
    navigator.push(
      MaterialPageRoute(builder: (_) => CalificacionesPage(usuario: usuarioActual, trabajos: [],)),
    );
  } else if (index == 2) {
    // Ir a mensajes (DM)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) =>  DMPage(
        nombre: widget.usuarioActual,
        mensajes: mensajes,
      )),
    );
  } else if (index == 0) {
    // Ir a inicio (Feed)
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FeedScreen()),
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
  );
}
}