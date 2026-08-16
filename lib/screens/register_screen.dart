import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../services/cv_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Controladores de los datos principales del registro.
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _phoneController;

  File? _documentImage;
  String? _pdfPath;
  String? _pdfFileName;
  bool _isLoading = false;

  // Rol seleccionado para definir el documento requerido.
  String _selectedRole = "Empleado";

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _phoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isPasswordSecure(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*[0-9]).{8,}$');
    return regex.hasMatch(password);
  }

  Future<void> _pickDocumentImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _documentImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _performRegistration() async {
    if (_nameController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty) {
      _showSnackBar("Debes llenar todos los campos");
      return;
    }

    if (!_isPasswordSecure(_passwordController.text.trim())) {
      _showSnackBar(
        "La contraseña debe tener mínimo 8 caracteres, una mayúscula y un número",
      );
      return;
    }

    if (_pdfPath == null) {
      _showSnackBar("Debes subir el documento PDF requerido");
      return;
    }

    if (_documentImage == null) {
      _showSnackBar("Debes subir la foto de tu documento");
      return;
    }

    final username = _usernameController.text.trim().toLowerCase();
    final email = _emailController.text.trim().toLowerCase();

    final telefono = int.tryParse(_phoneController.text.trim());

    if (telefono == null) {
      _showSnackBar('El teléfono debe ser numérico');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Comprueba que el username no esté ocupado.
      final existingUsername = await FirebaseFirestore.instance
          .collection('login_users')
          .doc(username)
          .get();

      if (existingUsername.exists) {
        _showSnackBar("Ese nombre de usuario ya está ocupado");
        return;
      }

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;

      String? cvUrl;
      String? mercantileUrl;
      String? documentUrl;

      // Carga los documentos antes de guardar el perfil completo.
      final uploadUrl = await uploadPdf(_pdfPath!, email);

      if (_selectedRole == "Empresa") {
        mercantileUrl = uploadUrl;
      } else {
        cvUrl = uploadUrl;
      }

      documentUrl = await uploadImage(_documentImage!.path, email);

      final userData = {
        'uid': uid,
        'nombre': _nameController.text.trim(),
        'username': username,
        'email': email,
        'telefono': telefono,
        'role': _selectedRole,
        'cv_url': cvUrl,
        'mercantile_url': mercantileUrl,
        'document_url': documentUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .set(userData);

      // Guarda la relación username-correo usada por el login.
      await FirebaseFirestore.instance
          .collection('login_users')
          .doc(username)
          .set({'uid': uid, 'email': email});

      if (!mounted) return;

      _showSnackBar("Usuario registrado exitosamente");
      Navigator.of(context).pushReplacementNamed('/login');
    } on FirebaseAuthException catch (e) {
      _showSnackBar("Error Auth: ${e.message}");
    } catch (e) {
      _showSnackBar("Error inesperado: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmar"),
        content: const Text(
          "Al continuar aceptas nuestros términos y condiciones. y confirmas que eres mayor de edad.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performRegistration();
            },
            child: const Text("Continuar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Image.asset('assets/logo.png', height: screenHeight * 0.2),
                  const Text(
                    "Te Ubicamos",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  // Card documentos
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Text(
                            _selectedRole == "Empresa"
                                ? "Matrícula Mercantil"
                                : "Hoja de Vida",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ElevatedButton.icon(
                            onPressed: () async {
                              _pdfPath = await pickPdf();
                              if (_pdfPath != null) {
                                setState(
                                  () =>
                                      _pdfFileName = _pdfPath!.split('/').last,
                                );
                              }
                            },
                            icon: const Icon(Icons.picture_as_pdf),
                            label: Text(_pdfFileName ?? "Seleccionar PDF"),
                          ),

                          const SizedBox(height: 10),

                          ElevatedButton.icon(
                            onPressed: _pickDocumentImage,
                            icon: const Icon(Icons.camera_alt),
                            label: Text(
                              _documentImage != null
                                  ? "Imagen cargada"
                                  : "Foto Documento",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Selector rol debajo de documentos
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: "Tipo de cuenta",
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: "Empleado",
                        child: Text("Empleado"),
                      ),
                      DropdownMenuItem(
                        value: "Empresa",
                        child: Text("Empresa"),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedRole = value;

                        // Limpiar archivos al cambiar rol
                        _pdfPath = null;
                        _pdfFileName = null;
                        _documentImage = null;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Campos de texto
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nombre'),
                  ),
                  TextField(
                    controller: _usernameController,
                    autocorrect: false,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      hintText: 'user123',
                    ),
                  ),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                  ),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _showConfirmDialog,
                      child: const Text("Registrarse"),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("¿Ya tienes una cuenta? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacementNamed('/login');
                        },
                        child: const Text(
                          "Inicia sesión",
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
