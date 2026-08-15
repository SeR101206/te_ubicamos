import 'package:flutter/material.dart';
import 'package:te_ubicamos/screens/calificaciones_page.dart';
import 'package:te_ubicamos/screens/feed_screen.dart';
import 'package:te_ubicamos/screens/map_screen.dart';
import 'package:te_ubicamos/screens/dm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CheckoutScreen(),
    );
  }
}

class CheckoutScreen extends StatefulWidget {
  final String usuarioActual;
  const CheckoutScreen({super.key, this.usuarioActual = ''});


  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<Map<String, dynamic>> mensajes = [];

    String nombreUsuario = "";
  List trabajos = [];

  Widget metodoPago(String nombre, IconData icono){

    bool seleccionado = nombreUsuario == nombre;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: seleccionado ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: seleccionado ? Colors.blue : Colors.grey.shade300,
          width: 2,
        ),
      ),

      child: ListTile(

        leading: Icon(icono,size:30),

        title: Text(
          nombre,
          style: const TextStyle(fontSize:18),
        ),

        trailing: seleccionado
            ? const Icon(Icons.check_circle,color:Colors.blue)
            : null,

        onTap: (){
          setState(() {
            nombreUsuario = nombre;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Pasarela de Pago"),
        centerTitle: true,
      ),
            bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
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
              MaterialPageRoute(builder: (_) => MapScreen(usuarioActual: widget.usuarioActual)),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => DMPage(
                nombre: widget.usuarioActual,
                mensajes: mensajes,
              )),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => CheckoutScreen(usuarioActual: widget.usuarioActual)),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CalificacionesPage(
                  usuario: widget.usuarioActual,
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
      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          children: [

            const SizedBox(height:20),

            const Text(
              "Selecciona tu método de pago",
              style: TextStyle(
                fontSize:22,
                fontWeight:FontWeight.bold,
              ),
            ),

            const SizedBox(height:30),

            metodoPago("PSE", Icons.account_balance),
            metodoPago("Nequi", Icons.phone_android),
            metodoPago("Daviplata", Icons.account_balance_wallet),
            metodoPago("Tarjeta de Crédito", Icons.credit_card),

            const Spacer(),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(18),
                ),

                onPressed: (){

                  if(nombreUsuario.isEmpty){
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Selecciona un método de pago"),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:(context)=>ConfirmacionPago(
                        metodo: nombreUsuario,
                      ),
                    ),
                  );
                },

                child: const Text(
                  "Continuar",
                  style: TextStyle(fontSize:18),
                ),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class ConfirmacionPago extends StatelessWidget {

  final String metodo;

  const ConfirmacionPago({super.key, required this.metodo});

  Future registrarPago() async{

    await FirebaseFirestore.instance.collection("pagos").add({

      "metodo": metodo,
      "fecha": DateTime.now(),
      "estado": "completado"

    });

  }

  @override
  Widget build(BuildContext context){

    return Scaffold(

      appBar: AppBar(
        title: const Text("Confirmar Pago"),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.payment,
              size:100,
              color:Colors.blue,
            ),

            const SizedBox(height:20),

            const Text(
              "Método seleccionado:",
              style: TextStyle(fontSize:18),
            ),

            const SizedBox(height:10),

            Text(
              metodo,
              style: const TextStyle(
                fontSize:24,
                fontWeight:FontWeight.bold,
              ),
            ),

            const SizedBox(height:40),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(

                onPressed: () async {

                  await registrarPago();

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder:(context)=>const PagoExitoso(),
                    ),
                  );

                },

                child: const Text("Confirmar Pago"),
              ),
            )

          ],
        ),
      ),
    );
  }
}

class PagoExitoso extends StatelessWidget {

  const PagoExitoso({super.key});

  @override
  Widget build(BuildContext context){

    return Scaffold(

      body: Center(

        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,

          children: [

            const Icon(
              Icons.check_circle,
              size:120,
              color:Colors.green,
            ),

            const SizedBox(height:20),

            const Text(
              "Pago realizado con éxito",
              style: TextStyle(
                fontSize:24,
                fontWeight:FontWeight.bold,
              ),
            ),

            const SizedBox(height:10),

            const Text(
              "Gracias por tu compra",
              style: TextStyle(fontSize:16),
            ),

            const SizedBox(height:40),

            ElevatedButton(

              onPressed: (){
                Navigator.pop(context);
              },

              child: const Text("Volver"),
            )

          ],
        ),
      ),
    );
  }
}