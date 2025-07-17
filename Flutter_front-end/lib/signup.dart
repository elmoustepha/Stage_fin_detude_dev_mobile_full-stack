import 'package:flutter/material.dart';
import 'materiel.dart';
import 'parc.dart';
import 'historique.dart';
import 'home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Inscrire extends StatefulWidget {
  final int? userId;
  final String? userType;
  const Inscrire({Key? key, this.userId, this.userType}) : super(key: key);

  @override
  State<Inscrire> createState() => _InscrireState();
}

class _InscrireState extends State<Inscrire> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nniController = TextEditingController();
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _selectedType;
  String? _selectedEtat;
  bool _obscurePassword = true;

  int? userId;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('http://localhost:3000/api/user/inscrire'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'nni': _nniController.text,
            'nom': _nomController.text,
            'prenom': _prenomController.text,
            'email': _emailController.text,
            'password': _passwordController.text,
            'type': _selectedType,
            'etat': _selectedEtat,
          }),
        );

        if (response.statusCode == 201) {
          final data = jsonDecode(response.body);
          userId = (data is Map && data.containsKey('user'))
              ? data['user']['id']
              : data['id'];

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Succès'),
              content: const Text("Utilisateur enregistré avec succès."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterielPage(
                          userId: userId,
                          userType: _selectedType,
                        ),
                      ),
                    );
                  },
                  child: const Text('Suivant'),
                )
              ],
            ),
          );
        } else {
          String error = 'Erreur inconnue';
          try {
            error = jsonDecode(response.body)['message'];
          } catch (_) {}
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
    String menuTitle = (widget.userType == "Chef de parc")
        ? "Menu Chef du parc"
        : (widget.userType == "Technicien")
        ? "Menu Technicien"
        : "Menu";

    final width = MediaQuery.of(context).size.width;
    final formWidth = width * 0.50; 
    final fieldWidth = formWidth * 0.50;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Créer un utilisateur", style: TextStyle(fontFamily: 'Cairo')),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[800],
              ),
              child: Center(
                child: Text(
                  menuTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.devices),
              title: const Text('Matériel', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MaterielPage(
                      userId: widget.userId,
                      userType: widget.userType,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.storage),
              title: const Text('Parc', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ParcPage(
                      userId: widget.userId,
                      userType: widget.userType,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historique', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoriquePage(
                      userId: widget.userId,
                      userType: widget.userType,
                    ),
                  ),
                );
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.exit_to_app, color: Colors.red),
              title: const Text('Déconnecter', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const HomePage()),
                      (Route<dynamic> route) => false,
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      backgroundColor: const Color.fromARGB(255, 250, 249, 249),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: formWidth,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.09),
                  blurRadius: 20,
                  spreadRadius: 5,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_alt_1, color: Colors.blue, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    'Créer un utilisateur',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[900],
                      fontFamily: 'Cairo',
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: fieldWidth, 
                    child: champText(_nniController, 'NNI', TextInputType.number, icon: Icons.badge),
                  ),
                  SizedBox(
                    width: fieldWidth, 
                    child: champText(_nomController, 'Nom', TextInputType.text, icon: Icons.person),
                  ),
                  SizedBox(
                    width: fieldWidth, 
                    child: champText(_prenomController, 'Prénom', TextInputType.text, icon: Icons.person_outline),
                  ),
                  SizedBox(
                    width: fieldWidth, 
                    child: champText(
                      _emailController,
                      'Email',
                      TextInputType.emailAddress,
                      icon: Icons.email,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Veuillez entrer une adresse email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[cC][oO][mM]$').hasMatch(value)) {
                          return 'Adresse email invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth, // عرض حقل Mot de passe
                    child: champText(
                      _passwordController,
                      'Mot de passe',
                      TextInputType.text,
                      icon: Icons.lock,
                      obscure: _obscurePassword,
                      isPassword: true,
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth, 
                    child: dropdownField(
                      label: 'Type',
                      value: _selectedType,
                      items: ['Chef de parc', 'Technicien'],
                      icon: Icons.account_circle,
                      onChanged: (value) => setState(() => _selectedType = value),
                    ),
                  ),
                  SizedBox(
                    width: fieldWidth, 
                    child: dropdownField(
                      label: 'État',
                      value: _selectedEtat,
                      items: ['Actif', 'Suspendu'],
                      icon: Icons.verified_user,
                      onChanged: (value) => setState(() => _selectedEtat = value),
                    ),
                  ),
                  const SizedBox(height: 3),
                  SizedBox(
                    width: 140,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 8, 77, 236),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.check_circle, size: 19),
                      label: const Text("S'inscrire", style: TextStyle(fontSize: 17, fontFamily: 'Cairo')),
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
          prefixIcon: icon != null ? Icon(icon, color: Colors.blue[800]) : null,
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

  Widget dropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.blue[800]),
          border: const OutlineInputBorder(),
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Veuillez sélectionner $label';
          }
          return null;
        },
      ),
    );
  }
}