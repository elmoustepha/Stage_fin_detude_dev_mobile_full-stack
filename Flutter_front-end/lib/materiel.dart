import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'historique/parc_tab.dart';
import 'parc.dart';
import 'signup.dart';
import 'historique.dart';
import 'home.dart';

final ValueNotifier<bool> showTechNotifNotifier = ValueNotifier<bool>(false);

class MaterielPage extends StatefulWidget {
  final int? userId;
  final String? userType;

  const MaterielPage({Key? key, this.userId, this.userType}) : super(key: key);

  @override
  _MaterielPageState createState() => _MaterielPageState();
}

class _MaterielPageState extends State<MaterielPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController typeController = TextEditingController();
  final TextEditingController marqueController = TextEditingController();
  final TextEditingController modeleController = TextEditingController();
  final TextEditingController filterTypeController = TextEditingController();

  List materiels = [];
  bool showMaterials = false;
  int? editingId;

  Set<String> allTypes = {};

  int currentPage = 0;
  int itemsPerPage = 4;
  String filterType = "";

  List<String> filterTypesList = [];
  List<String> typesList = [];

  final FocusNode filterTypeFocusNode = FocusNode();

  bool showNotification = false;

  @override
  void initState() {
    super.initState();
    fetchMateriels();
    if (widget.userType == "Chef de parc") {
      checkNotification();
    }
    if (widget.userType == "Technicien") {
      checkTechNotification();
    }
  }

  // Notification Chef du parc
  Future<void> checkNotification() async {
    final res = await http.get(Uri.parse('http://localhost:3000/api/parc/allOperations'));
    if (res.statusCode == 200) {
      List ops = jsonDecode(res.body);
      bool hasPending = ops.any((op) =>
      (op['effectue_par']?.toString()?.toLowerCase() == 'technicien') &&
          (op['etat_validation'] == 'En attente'));
      setState(() {
        showNotification = hasPending;
      });
    }
  }

  // Notification Technicien (pastille rouge vu)
  Future<void> checkTechNotification() async {
    if (widget.userId == null) return;
    final res = await http.get(Uri.parse('http://localhost:3000/api/parc/allOperations?userId=${widget.userId}'));
    if (res.statusCode == 200) {
      List ops = jsonDecode(res.body);
      final nonSeenCount = ops.where((op) =>
      (op['etat_validation'] == 'Validé' || op['etat_validation'] == 'Rejeté') &&
          (op['vu'] == false || op['vu'] == 0 || op['vu'] == null || op['vu'] == '0')).length;
      showTechNotifNotifier.value = nonSeenCount > 0;
    }
  }

  @override
  void dispose() {
    filterTypeFocusNode.dispose();
    filterTypeController.dispose();
    super.dispose();
  }

  void clearForm() {
    typeController.clear();
    marqueController.clear();
    modeleController.clear();
    setState(() {
      editingId = null;
    });
  }

  Future<bool?> showConfirm(String title, String message) async {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Confirmer'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
  }

  void showAlertError(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void showAlertSuccess(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  String capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  String? validateType(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le type';
    }
    if (value.trim().length < 2) {
      return 'Le type doit contenir au moins 2 caractères';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Le type ne doit contenir que des lettres et des espaces';
    }
    return null;
  }

  Future<void> addMateriel() async {
    if (!_formKey.currentState!.validate()) return;

    bool? confirmed = await showConfirm('Confirmation', 'Voulez-vous vraiment ajouter ce matériel ?');
    if (confirmed != true) return;

    final cleanedType = capitalize(typeController.text.trim());

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/materiel/ajouter'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': cleanedType,
        'marque': marqueController.text.trim(),
        'modele': modeleController.text.trim(),
        'userId': widget.userId,
        'typeUtilisateur': widget.userType
      }),
    );

    if (response.statusCode == 201) {
      setState(() {
        allTypes.add(cleanedType);
        filterTypesList = allTypes.toList()..sort();
      });
      await fetchMateriels();
      clearForm();
      setState(() {
        filterType = "";
      });
      showAlertSuccess('Succès', 'Matériel ajouté avec succès');
    } else {
      showAlertError('Erreur', 'Erreur lors de l\'enregistrement');
    }
  }

  Future<void> updateMateriel(int id) async {
    if (!_formKey.currentState!.validate()) return;

    bool? confirmed = await showConfirm('Confirmation', 'Voulez-vous vraiment modifier ce matériel ?');
    if (confirmed != true) return;

    final cleanedType = capitalize(typeController.text.trim());

    final response = await http.put(
      Uri.parse('http://localhost:3000/api/materiel/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'type': cleanedType,
        'marque': marqueController.text.trim(),
        'modele': modeleController.text.trim(),
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        allTypes.add(cleanedType);
        filterTypesList = allTypes.toList()..sort();
      });
      await fetchMateriels();
      clearForm();
      setState(() {
        filterType = "";
      });
      showAlertSuccess('Succès', 'Matériel modifié avec succès');
    } else {
      showAlertError('Erreur', 'Erreur lors de la modification');
    }
  }

  Future<void> fetchMateriels() async {
    setState(() {
      showMaterials = false;
    });

    String url = 'http://localhost:3000/api/materiel/all';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      data.sort((a, b) => (b['id'] as int).compareTo(a['id'] as int));
      setState(() {
        materiels = data;
        showMaterials = true;
        allTypes = data.map<String>((e) => e['type'].toString()).toSet();
        if (allTypes.isEmpty) {
          allTypes = {'Laptop', 'Imprimante', 'Scanner'};
        }
        typesList = data.map<String>((e) => e['type'].toString()).toList();
        filterTypesList = allTypes.toList()..sort();
        currentPage = 0;
      });
    } else {
      setState(() {
        materiels = [];
        showMaterials = true;
        allTypes = {'Laptop', 'Imprimante', 'Scanner'};
        typesList = [];
        filterTypesList = allTypes.toList()..sort();
        currentPage = 0;
      });
    }
  }

  Future<void> deleteMateriel(int id) async {
    final response = await http.delete(Uri.parse('http://localhost:3000/api/materiel/$id'));

    if (response.statusCode == 200) {
      await fetchMateriels();
      showAlertSuccess('Succès', 'Matériel supprimé avec succès');
    }
  }

  void confirmDelete(int id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text("Confirmation", style: TextStyle(color: Colors.red)),
          ],
        ),
        content: Text("Voulez-vous vraiment supprimer ce matériel ?"),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              deleteMateriel(id);
            },
          ),
        ],
      ),
    );
  }

  List get filteredMateriels {
    List filtered = materiels.where((mat) {
      final type = filterType.trim().toLowerCase();
      return (type.isEmpty || mat['type'].toString().toLowerCase().contains(type));
    }).toList();

    int start = currentPage * itemsPerPage;
    int end = start + itemsPerPage;
    if (start > filtered.length) start = filtered.length;
    if (end > filtered.length) end = filtered.length;
    return filtered.sublist(start, end);
  }

  int get pageCount {
    int filteredCount = materiels.where((mat) {
      final type = filterType.trim().toLowerCase();
      return (type.isEmpty || mat['type'].toString().toLowerCase().contains(type));
    }).length;
    return (filteredCount / itemsPerPage).ceil();
  }

  Future<void> goToHistoriqueAsTechnicien() async {
    if (widget.userId != null) {
      await http.patch(
        Uri.parse('http://localhost:3000/api/parc/markSeen?userId=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );
      await checkTechNotification();
    }
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoriquePage(
          userId: widget.userId,
          userType: widget.userType,
          initialTab: 1,
        ),
      ),
    );
    await checkTechNotification();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tableWidth = width * 0.60;
    final colCount = widget.userType == "Chef de parc" ? 4 : 3; // 4 colonnes pour le chef, 3 pour le technicien (sans Actions)
    final colWidth = tableWidth / colCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Gestion des Matériels'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 5,
        actions: [
          if (widget.userType == "Chef de parc") ...[
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  tooltip: 'Voir les nouvelles opérations',
                  onPressed: () async {
                    setState(() {
                      showNotification = false;
                    });
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => HistoriquePage(
                          userId: widget.userId,
                          userType: widget.userType,
                          initialTab: 1,
                        ),
                      ),
                    );
                  },
                ),
                if (showNotification)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (widget.userType == "Technicien")
            ValueListenableBuilder<bool>(
              valueListenable: showTechNotifNotifier,
              builder: (context, value, _) {
                return Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      tooltip: 'Voir vos opérations validées/rejetées',
                      onPressed: goToHistoriqueAsTechnicien,
                    ),
                    if (value)
                      Positioned(
                        right: 12,
                        top: 12,
                        child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
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
              leading: const Icon(Icons.storage),
              title: const Text('Parc', style: TextStyle(fontFamily: 'Cairo')),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
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
                Navigator.push(
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
      body: (widget.userId == null && widget.userType != "Chef de parc")
          ? Center(
        child: Text(
          "Veuillez vous inscrire ou vous connecter pour voir vos matériels.",
          style: TextStyle(fontSize: 18, color: Colors.red, fontFamily: 'Cairo'),
        ),
      )
          : ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Formulaire d'ajout (pour le technicien et le chef) ou modification (pour le chef seulement)
          if (widget.userType == "Chef de parc" || widget.userType == "Technicien")
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.50,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blueGrey.withOpacity(0.12),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Autocomplete<String>(
                              optionsBuilder: (TextEditingValue textEditingValue) {
                                if (textEditingValue.text.isEmpty) {
                                  return allTypes;
                                }
                                return allTypes.where((String option) {
                                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                                });
                              },
                              fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                                controller.text = typeController.text;
                                return SizedBox(
                                  width: constraints.maxWidth,
                                  child: TextFormField(
                                    controller: controller,
                                    focusNode: focusNode,
                                    onEditingComplete: onEditingComplete,
                                    decoration: const InputDecoration(
                                      labelText: 'Type',
                                      hintText: 'Entrez ou choisissez un type',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: validateType,
                                    onChanged: (value) {
                                      typeController.text = capitalize(value.trim());
                                    },
                                  ),
                                );
                              },
                              optionsViewBuilder: (context, onSelected, options) {
                                return Align(
                                  alignment: Alignment.topLeft,
                                  child: Material(
                                    elevation: 4.0,
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: constraints.maxWidth,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.all(8),
                                        itemCount: options.length,
                                        shrinkWrap: true,
                                        itemBuilder: (context, index) {
                                          final option = options.elementAt(index);
                                          return ListTile(
                                            title: Text(option),
                                            onTap: () {
                                              onSelected(option);
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                              onSelected: (String selection) {
                                setState(() {
                                  typeController.text = selection;
                                });
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        buildInput(marqueController, 'Marque'),
                        const SizedBox(height: 12),
                        buildInput(modeleController, 'Modèle'),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: editingId == null ? Colors.blue : Colors.green,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 3,
                              ),
                              icon: Icon(editingId == null ? Icons.add : Icons.save),
                              onPressed: widget.userType == "Technicien" && editingId != null
                                  ? null // Désactiver le bouton de modification pour le technicien
                                  : () {
                                if (editingId == null) {
                                  addMateriel();
                                } else {
                                  updateMateriel(editingId!);
                                }
                              },
                              label: Text(
                                editingId == null ? 'Ajouter' : 'Modifier',
                                style: const TextStyle(fontFamily: 'Cairo'),
                              ),
                            ),
                            if (editingId != null && widget.userType == "Chef de parc") ...[
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 3,
                                ),
                                icon: const Icon(Icons.cancel),
                                onPressed: clearForm,
                                label: const Text('Annuler', style: TextStyle(fontFamily: 'Cairo')),
                              ),
                            ]
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 250,
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return filterTypesList;
                    }
                    return filterTypesList.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: filterTypeController,
                      focusNode: focusNode,
                      enabled: filterTypesList.isNotEmpty,
                      decoration: InputDecoration(
                        labelText: 'Filtrer par type',
                        hintText: filterTypesList.isEmpty ? 'Aucun type disponible' : 'Tapez un type pour filtrer',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.filter_list),
                      ),
                      onChanged: (value) {
                        setState(() {
                          filterType = value;
                          controller.text = value;
                          currentPage = 0;
                        });
                      },
                      onEditingComplete: onEditingComplete,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 250,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(8),
                            itemCount: options.length,
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                title: Text(option),
                                onTap: () {
                                  onSelected(option);
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      filterType = selection;
                      filterTypeController.text = selection;
                      currentPage = 0;
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black54,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  setState(() {
                    filterType = "";
                    filterTypeController.clear();
                    currentPage = 0;
                  });
                  filterTypeFocusNode.unfocus();
                },
                label: const Text('Tout afficher'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (showMaterials)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: tableWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      color: Colors.grey[200],
                      child: Row(
                        children: [
                          headerCell('Type', colWidth),
                          headerCell('Marque', colWidth),
                          headerCell('Modèle', colWidth),
                          if (widget.userType == "Chef de parc")
                            headerCell('Actions', colWidth),
                        ],
                      ),
                    ),
                    Divider(height: 1, thickness: 1, color: Colors.black54),
                    ...List.generate(filteredMateriels.length, (i) {
                      final mat = filteredMateriels[i];
                      return Column(
                        children: [
                          Row(
                            children: [
                              dataCell(mat['type'].toString(), colWidth),
                              dataCell(mat['marque'].toString(), colWidth),
                              dataCell(mat['modele'].toString(), colWidth),
                              if (widget.userType == "Chef de parc")
                                Container(
                                  width: colWidth,
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.green),
                                        tooltip: "Modifier",
                                        onPressed: () {
                                          setState(() {
                                            editingId = mat['id'];
                                            typeController.text = mat['type'];
                                            marqueController.text = mat['marque'];
                                            modeleController.text = mat['modele'];
                                          });
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: "Supprimer",
                                        onPressed: () => confirmDelete(mat['id']),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          if (i != filteredMateriels.length - 1)
                            Divider(height: 1, thickness: 1, color: Colors.black26),
                        ],
                      );
                    }),
                    if (pageCount > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_left),
                              onPressed: currentPage > 0
                                  ? () {
                                setState(() {
                                  currentPage--;
                                });
                              }
                                  : null,
                            ),
                            Text(
                              'Page ${pageCount == 0 ? 1 : currentPage + 1} / ${pageCount == 0 ? 1 : pageCount}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.arrow_right),
                              onPressed: (currentPage < pageCount - 1)
                                  ? () {
                                setState(() {
                                  currentPage++;
                                });
                              }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget headerCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
    );
  }

  Widget dataCell(String text, double width) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(10),
      child: Text(text, style: const TextStyle(fontSize: 16, fontFamily: 'Cairo')),
    );
  }

  Widget buildInput(TextEditingController controller, String label, {IconData? icon}) {
    return TextFormField(
      controller: controller,
      style: const TextStyle(fontSize: 16, fontFamily: 'Cairo'),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => value == null || value.isEmpty ? 'Veuillez entrer $label' : null,
    );
  }
}