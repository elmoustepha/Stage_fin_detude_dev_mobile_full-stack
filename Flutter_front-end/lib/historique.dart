import 'package:flutter/material.dart';
import 'package:projet/historique/parc_tab.dart';
import 'historique/utilisateurs_tab.dart';
import 'materiel.dart';
import 'parc.dart';
import 'signup.dart';
import 'home.dart';

class HistoriquePage extends StatefulWidget {
  final int? userId;
  final String? userType;
  final int? initialTab;

  const HistoriquePage({Key? key, this.userId, this.userType, this.initialTab}) : super(key: key);

  @override
  _HistoriquePageState createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab ?? 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print("userId: ${widget.userId} | userType: ${widget.userType}");
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historique"),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              child: Text(
                "Gestion des utilisateurs",
                style: TextStyle(color: Colors.white),
              ),
            ),
            Tab(
              child: Text(
                "Gestion de parc",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
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
                  widget.userType == "Chef de parc"
                      ? "Menu Chef de parc"
                      : (widget.userType == "Technicien"
                      ? "Menu Technicien"
                      : "Menu"),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
            // Chef de parc uniquement: Créer un compte
            if (widget.userType == "Chef de parc") ...[
              ListTile(
                leading: const Icon(Icons.person_add),
                title: const Text('Créer un compte', style: TextStyle(fontFamily: 'Cairo')),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => Inscrire(
                        userId: widget.userId,
                        userType: widget.userType,
                      ),
                    ),
                  );
                },
              ),
            ],
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
      body: TabBarView(
        controller: _tabController,
        children: [
          UtilisateursTab(
              userId: widget.userId,
              userType: widget.userType),

          ParcTab(
              userId: widget.userId,
              userType: widget.userType),
        ],
      ),
    );
  }
}