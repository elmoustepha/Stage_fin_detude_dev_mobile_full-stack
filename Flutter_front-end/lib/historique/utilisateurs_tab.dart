import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class UtilisateursTab extends StatefulWidget {
  final int? userId;
  final String? userType;

  const UtilisateursTab({
    Key? key,
    this.userId,
    this.userType,
  }) : super(key: key);

  @override
  State<UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<UtilisateursTab> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nniController = TextEditingController();
  final TextEditingController nomController = TextEditingController();
  final TextEditingController prenomController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool obscurePassword = true;
  String? type;
  String? etat;
  int? editingId;
  List utilisateurs = [];

  @override
  void initState() {
    super.initState();
    fetchUtilisateurs();
  }

  Future<void> fetchUtilisateurs() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/user/all'));
    if (response.statusCode == 200) {
      setState(() {
        utilisateurs = jsonDecode(response.body);
      });
    }
  }

  Future<void> ajouterUtilisateur() async {
    if (!_formKey.currentState!.validate()) return;
    final response = await http.post(
      Uri.parse('http://localhost:3000/api/user/inscrire'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nni": nniController.text,
        "nom": nomController.text,
        "prenom": prenomController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "type": type,
        "etat": etat,
      }),
    );
    if (response.statusCode == 201) {
      await fetchUtilisateurs();
      clearForm();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur ajouté avec succès')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ajout')),
      );
    }
  }

  Future<void> modifierUtilisateur(int id) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/user/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "nni": nniController.text,
        "nom": nomController.text,
        "prenom": prenomController.text,
        "email": emailController.text,
        "password": passwordController.text,
        "type": type,
        "etat": etat,
      }),
    );
    if (response.statusCode == 200) {
      await fetchUtilisateurs();
      clearForm();
      showConfigurationAlert();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la modification')),
      );
    }
  }

  Future<void> supprimerUtilisateur(int id) async {
    final response = await http.delete(
      Uri.parse('http://localhost:3000/api/user/$id'),
    );
    if (response.statusCode == 200) {
      await fetchUtilisateurs();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Utilisateur supprimé')),
      );
    }
  }

  void remplirForm(Map user) {
    setState(() {
      editingId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
      nniController.text = user['nni']?.toString() ?? '';
      nomController.text = user['nom'] ?? '';
      prenomController.text = user['prenom'] ?? '';
      emailController.text = user['email'] ?? '';
      passwordController.text = user['password'] ?? '';
      type = user['type'];
      etat = user['etat'];
      obscurePassword = true;
    });
  }

  void clearForm() {
    setState(() {
      editingId = null;
      nniController.clear();
      nomController.clear();
      prenomController.clear();
      emailController.clear();
      passwordController.clear();
      type = null;
      etat = null;
      obscurePassword = true;
    });
  }

  void showConfigurationAlert() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Configuration"),
        content: const Text("Les informations ont été modifiées avec succès !"),
        actions: [
          TextButton(
            child: const Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String? emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Champ requis';
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(value)) return 'E-mail invalide';
    return null;
  }

  String? numberValidator(String? value) {
    if (value == null || value.isEmpty) return 'Champ requis';
    if (!RegExp(r'^\d+$').hasMatch(value)) return 'Numéro invalide';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool isChef = ((widget.userType ?? '').trim().toLowerCase() == 'chef de parc');
    final width = MediaQuery.of(context).size.width;
    final formWidth = width > 800 ? width * 0.5 : double.infinity;
    final tableWidth = width * 0.78;
    final colCount = isChef ? 7 : 6;
    final colWidth = tableWidth / colCount;

    final List displayedUsers = isChef
        ? utilisateurs
        : utilisateurs.where((u) {
      int? userId = u['id'] is int ? u['id'] : int.tryParse(u['id'].toString());
      return userId == widget.userId;
    }).toList();

    // Fond de l'écran avec la couleur demandée
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isChef)
              Container(
                width: formWidth,
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: nniController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'NNI',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.badge, color: Colors.blue),
                              ),
                              validator: numberValidator,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: nomController,
                              decoration: const InputDecoration(
                                labelText: 'Nom',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person, color: Colors.blue),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: prenomController,
                              decoration: const InputDecoration(
                                labelText: 'Prénom',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.person_outline, color: Colors.blue),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email, color: Colors.blue),
                              ),
                              validator: emailValidator,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: passwordController,
                              obscureText: obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.red,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                                ),
                              ),
                              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: type,
                              decoration: const InputDecoration(
                                labelText: 'Type',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.account_circle, color: Colors.blue),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Chef de parc', child: Text('Chef de parc')),
                                DropdownMenuItem(value: 'Technicien', child: Text('Technicien')),
                              ],
                              onChanged: (val) => setState(() => type = val),
                              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: etat,
                              decoration: const InputDecoration(
                                labelText: 'État',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.verified_user, color: Colors.blue),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'Actif', child: Text('Actif')),
                                DropdownMenuItem(value: 'Suspendu', child: Text('Suspendu')),
                              ],
                              onChanged: (val) => setState(() => etat = val),
                              validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(
                              editingId == null ? Icons.add : Icons.save,
                              color: Colors.white,
                            ),
                            onPressed: editingId == null
                                ? ajouterUtilisateur
                                : () => modifierUtilisateur(editingId!),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: editingId == null ? Colors.blue : Colors.greenAccent,
                              foregroundColor: Colors.white,
                            ),
                            label: Text(editingId == null ? "Créer" : "Mettre à jour"),
                          ),
                          if (editingId != null) const SizedBox(width: 16),
                          if (editingId != null)
                            ElevatedButton.icon(
                              icon: const Icon(Icons.cancel, color: Colors.white),
                              onPressed: clearForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              label: const Text("Annuler"),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            if (isChef) const SizedBox(height: 23),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: tableWidth,
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('NNI', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Nom', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Prénom', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Email', textAlign: TextAlign.center)),
                    DataColumn(label: Text('Type', textAlign: TextAlign.center)),
                    DataColumn(label: Text('État', textAlign: TextAlign.center)),
                    if (isChef) DataColumn(label: Text('Actions', textAlign: TextAlign.center)),
                  ],
                  rows: displayedUsers.map<DataRow>((user) {
                    int? userId = user['id'] is int ? user['id'] : int.tryParse(user['id'].toString());
                    return DataRow(
                      cells: [
                        DataCell(Text(user['nni']?.toString() ?? '', textAlign: TextAlign.center)),
                        DataCell(Text(user['nom'] ?? '', textAlign: TextAlign.center)),
                        DataCell(Text(user['prenom'] ?? '', textAlign: TextAlign.center)),
                        DataCell(Text(user['email'] ?? '', textAlign: TextAlign.center)),
                        DataCell(Text(user['type'] ?? '', textAlign: TextAlign.center)),
                        DataCell(Text(user['etat']?.toString() ?? '', textAlign: TextAlign.center)),
                        if (isChef)
                          DataCell(Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.greenAccent),
                                tooltip: "Modifier",
                                onPressed: () => remplirForm(user),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Supprimer",
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (_) => AlertDialog(
                                      title: const Text("Configuration"),
                                      content: const Text("Voulez-vous supprimer cet utilisateur ?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Annuler"),
                                          onPressed: () => Navigator.pop(context, false),
                                        ),
                                        TextButton(
                                          child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                                          onPressed: () => Navigator.pop(context, true),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && userId != null) supprimerUtilisateur(userId);
                                },
                              ),
                            ],
                          )),
                      ],
                    );
                  }).toList(),
                  headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
                  dataRowColor: MaterialStateProperty.all(Colors.white),
                  columnSpacing: 24,
                  horizontalMargin: 12,
                  dividerThickness: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}