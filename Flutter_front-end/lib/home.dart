import 'package:flutter/material.dart';
import 'package:projet/signin.dart';
import 'package:projet/materiel.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userType;
  int? userId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(32.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.blueGrey.withOpacity(0.09),
                  blurRadius: 30,
                  spreadRadius: 7,
                  offset: const Offset(0, 18),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: Colors.blue[100],
                  child: Icon(Icons.handshake, color: Colors.blue[800], size: 40),
                ),
                const SizedBox(height: 18),
                Text(
                  'Bienvenue',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Application de gestion du parc',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 32),
                if (userType == null) ...[
                  SizedBox(
                    width: 170,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 3,
                      ),
                      icon: const Icon(Icons.login, size: 22),
                      label: const Text("Se connecter", style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SeConnecter()),
                        );
                        if (result != null && result is Map<String, dynamic>) {
                          setState(() {
                            userType = result['userType'];
                            userId = result['userId'];
                          });

                          // Nouveau: TOUS les utilisateurs vont à MaterielPage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MaterielPage(userId: userId!, userType: userType!),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}