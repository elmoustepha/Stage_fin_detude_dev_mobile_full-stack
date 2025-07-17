import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'materiel.dart';


class SeConnecter extends StatefulWidget {
  const SeConnecter({super.key});

  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SeConnecter> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  Future<void> _submitLogin() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/user/seconnecter'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': _emailController.text,
            'password': _passwordController.text,
          }),
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          String userType = responseData['user']['type'] ?? '';
          int userId = responseData['user']['id'];

          // Navigation selon le type d'utilisateur
          if (userType == 'Technicien') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MaterielPage(
                  userId: userId,
                  userType: userType, // Passe le vrai type ici !
                ),
              ),
            );
          } else if (userType == 'Chef de parc') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => MaterielPage(userId: userId, userType: userType),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Type d'utilisateur inconnu")),
            );
          }
        } else {
          String error = 'Erreur inconnue';
          try {
            error = jsonDecode(response.body)['message'];
          } catch (e) {
            // ignore error
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur : $error')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'envoi : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 250, 249, 249),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.6,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.07),
                  blurRadius: 18,
                  spreadRadius: 5,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_open, color: Colors.blue, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Connexion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  champText(_emailController, 'Email', TextInputType.emailAddress, icon: Icons.email),
                  champText(
                    _passwordController,
                    'Mot de passe',
                    TextInputType.text,
                    icon: Icons.lock,
                    obscure: _obscurePassword,
                    isPassword: true,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 150,
                    height: 40,
                    child: ElevatedButton.icon(
                      onPressed: _submitLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.login, size: 18),
                      label: const Text("Se connecter", style: TextStyle(fontSize: 14, fontFamily: 'Cairo')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget champText(
      TextEditingController controller,
      String label,
      TextInputType type, {
        IconData? icon,
        bool obscure = false,
        bool isPassword = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? (icon == Icons.email
              ? Icon(icon, color: Colors.blue[800])
              : icon == Icons.lock
              ? Icon(icon, color: Colors.blue[800])
              : Icon(icon))
              : null,
          border: const OutlineInputBorder(),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.red,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          )
              : null,
        ),
        validator: validator ??
                (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer $label';
              }
              return null;
            },
      ),
    );
  }
}