import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

import 'screens/login_screen.dart' as login;
import 'screens/register_screen.dart' as register;
import 'screens/calificaciones_page.dart' as calificaciones;
import 'screens/pagos_screen.dart' as pagos;
import 'providers/cart_provider.dart';
import 'screens/feed_screen.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pre-registrar administrador si no existe
  try {
    final adminDoc = await FirebaseFirestore.instance.collection('usuarios').doc('sergioestebanrh@gmail.com').get();
    if (!adminDoc.exists) {
      await FirebaseFirestore.instance.collection('usuarios').doc('sergioestebanrh@gmail.com').set({
        'nombre': 'Sergio Ruiz',
        'email': 'sergioestebanrh@gmail.com',
        'password': 'SeRNinja@06911',
        'telefono': '3224061591',
        'role': 'Administrador',
      });
    }
  } catch (e) {
    print('Error pre-registrando admin: $e');
    // Continuar sin fallar
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CartProvider(),
        ),
        ChangeNotifierProvider(
          create: (_) => UserProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Te Ubicamos',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
      ),
      home: const login.LoginScreen(),
      routes: {
        '/login': (context) => const login.LoginScreen(),
        '/register': (context) => const register.RegisterScreen(),
        '/calificaciones': (context) =>
            calificaciones.CalificacionesPage(usuario: '', trabajos: []),
        '/home': (context) =>
            const MyHomePage(title: 'Te Ubicamos'),
        '/pagos': (context) => const pagos.CheckoutScreen(),
        '/feed': (context) => const FeedScreen(),
      },
    );
  }
}

class MyHomePage extends StatelessWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.pushNamed(context, '/pagos');
          },
          child: const Text("Ir a Pagos"),
        ),
      ),
    );
  }
}