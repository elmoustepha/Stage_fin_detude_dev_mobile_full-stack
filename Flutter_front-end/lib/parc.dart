import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:projet/signup.dart';
import 'historique.dart';
import 'materiel.dart';
import 'home.dart';

class ParcPage extends StatefulWidget {
  final int? userId;
  final String? userType;
  const ParcPage({Key? key, this.userId, this.userType}) : super(key: key);

  @override
  _ParcPageState createState() => _ParcPageState();
}

class _ParcPageState extends State<ParcPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController numeroSerieController = TextEditingController();
  final TextEditingController motifController = TextEditingController();
  final TextEditingController filterNumeroSerieController = TextEditingController();

  List parcList = [];
  List materiels = [];
  String? etat;
  String? disponibilite;
  dynamic selectedMateriel;
  int? editingId;

  int currentPage = 0;
  int itemsPerPage = 10;

  List<String> numeroSerieList = [];
  String? filterNumeroSerie;

  final FocusNode filterNumeroSerieFocusNode = FocusNode();

  double? _dropdownMaterielWidth;
  double? _dropdownEtatWidth;
  double? _dropdownDisponibiliteWidth;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  @override
  void dispose() {
    numeroSerieController.dispose();
    motifController.dispose();
    filterNumeroSerieController.dispose();
    filterNumeroSerieFocusNode.dispose();
    super.dispose();
  }

  void clearForm() {
    setState(() {
      numeroSerieController.clear();
      motifController.clear();
      selectedMateriel = null;
      etat = null;
      disponibilite = null;
      editingId = null;
      filterNumeroSerie = null;
      filterNumeroSerieController.clear();
      FocusScope.of(context).unfocus();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
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

  String? validateNumeroSerie(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer le numéro de série';
    }
    if (value.trim().length < 2) {
      return 'Le numéro de série doit contenir au moins 2 caractères';
    }
    return null;
  }

  Future<void> _loadAllData() async {
    await fetchMateriels();
    await fetchParcData();
  }

  Future<void> fetchMateriels() async {
    String url = 'http://localhost:3000/api/materiel/all';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      data.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
      setState(() {
        materiels = data;
      });
    }
  }

  Future<void> fetchParcData() async {
    String url = 'http://localhost:3000/api/parc/all';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      setState(() {
        parcList = data;
        numeroSerieList = parcList
            .map<String>((e) => e['numero_serie']?.toString() ?? '')
            .where((s) => s.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
        print('numeroSerieList: $numeroSerieList'); // Debug print
      });
    } else {
      print('Erreur lors de la récupération des données du parc: ${response.statusCode}');
    }
  }

  List<dynamic> get filteredParcList {
    if (filterNumeroSerie != null && filterNumeroSerie!.isNotEmpty) {
      return parcList
          .where((item) => item['numero_serie']
          .toString()
          .toLowerCase()
          .contains(filterNumeroSerie!.toLowerCase()))
          .toList();
    }
    return parcList;
  }

  List<dynamic> get paginatedParcList {
    final filtered = filteredParcList;
    int start = currentPage * itemsPerPage;
    int end = start + itemsPerPage;
    if (start > filtered.length) start = filtered.length;
    if (end > filtered.length) end = filtered.length;
    return filtered.sublist(start, end);
  }

  int get pageCount {
    final count = filteredParcList.length;
    return (count / itemsPerPage).ceil();
  }

  void showAll() {
    setState(() {
      filterNumeroSerie = null;
      filterNumeroSerieController.clear();
      currentPage = 0;
    });
    filterNumeroSerieFocusNode.unfocus();
  }

  Future<void> _addOperation(Map<String, dynamic> operationData) async {
    operationData.remove('typeMateriel');
    operationData.remove('marque');
    operationData.remove('modele');

    final safeOperationData = {
      'parc_id': operationData['parc_id'] ?? null,
      'userId': operationData['userId'] ?? widget.userId,
      'numero_serie': operationData['numero_serie'] ?? '',
      'materiel_id': operationData['materiel_id'] ?? null,
      'etat': operationData['etat'] ?? '',
      'disponibilite': operationData['disponibilite'] ?? '',
      'action': operationData['action'] ?? '',
      'motif': operationData['motif'] ?? '',
      'effectue_par': operationData['effectue_par'] ?? widget.userType,
      'etat_validation': operationData['etat_validation'] ?? 'En attente',
      'vu': operationData['vu'] ?? (widget.userType?.toLowerCase() == 'chef de parc' ? 1 : 0),
    };

    try {
      print('Envoi de l\'opération: ${jsonEncode(safeOperationData)}');
      final response = await http.post(
        Uri.parse('http://localhost:3000/api/parc/operations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(safeOperationData),
      );

      if (response.statusCode == 201) {
        print('Opération enregistrée avec succès: ${response.body}');
        await fetchParcData();
      }
    } catch (e) {
      print('Exception lors de l\'ajout de l\'opération: $e');
      showAlertError('Erreur', 'Erreur réseau lors de l\'enregistrement: $e');
    }
  }

  Future<void> enregistrerParc() async {
    if (!_formKey.currentState!.validate() || selectedMateriel == null || motifController.text.isEmpty) {
      showAlertError('Erreur', 'Veuillez remplir tous les champs requis');
      return;
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment ajouter cet élément au parc ?'),
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
    if (confirmed != true) return;

    final operationData = {
      'parc_id': null,
      'userId': widget.userId,
      'numero_serie': numeroSerieController.text,
      'materiel_id': selectedMateriel['id'],
      'etat': etat ?? '',
      'disponibilite': disponibilite ?? '',
      'action': 'Ajouter',
      'motif': motifController.text,
      'effectue_par': widget.userType,
      'etat_validation': widget.userType?.toLowerCase() == 'chef de parc' ? 'Validé' : 'En attente',
      'vu': widget.userType?.toLowerCase() == 'chef de parc' ? 1 : 0,
    };

    await _addOperation(operationData);
    clearForm();
    showAlertSuccess('Succès', widget.userType?.toLowerCase() == 'chef de parc'
        ? 'Matériel ajouté avec succès'
        : 'Opération enregistrée, en attente de validation');
  }

  Future<void> modifierParc() async {
    if (editingId == null || !_formKey.currentState!.validate() || selectedMateriel == null || motifController.text.isEmpty) {
      showAlertError('Erreur', 'Veuillez remplir tous les champs requis');
      return;
    }

    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment modifier cet élément du parc ?'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Modifier', style: TextStyle(color: Colors.green)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final parc = parcList.firstWhere((item) => item['id'] == editingId);

    final operationData = {
      'parc_id': editingId,
      'userId': widget.userId,
      'numero_serie': numeroSerieController.text,
      'materiel_id': selectedMateriel['id'],
      'etat': etat ?? '',
      'disponibilite': disponibilite ?? '',
      'action': 'Modifier',
      'motif': motifController.text,
      'effectue_par': widget.userType,
      'etat_validation': widget.userType?.toLowerCase() == 'chef de parc' ? 'Validé' : 'En attente',
      'vu': widget.userType?.toLowerCase() == 'chef de parc' ? 1 : 0,
    };

    await _addOperation(operationData);
    if (widget.userType?.toLowerCase() == 'chef de parc') {
      final updateData = {
        'materiel_id': selectedMateriel['id'],
        'numero_serie': numeroSerieController.text,
        'etat': etat ?? '',
        'disponibilite': disponibilite ?? '',
        'userId': widget.userId,
        'effectue_par': widget.userType,
      };
      final response = await http.put(
        Uri.parse('http://localhost:3000/api/parc/$editingId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updateData),
      );
      if (response.statusCode != 200) {
        print('Erreur lors de la mise à jour directe du parc: ${response.body}');
        showAlertError('Erreur', 'Erreur lors de la mise à jour directe du parc: ${response.body}');
      }
    }
    clearForm();
    showAlertSuccess('Succès', widget.userType?.toLowerCase() == 'chef de parc'
        ? 'Modification enregistrée avec succès'
        : 'Modification enregistrée, en attente de validation');
  }

  Future<void> supprimerParc(int id) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Confirmation'),
        content: Text('Voulez-vous vraiment supprimer cet élément du parc ?'),
        actions: [
          TextButton(
            child: Text('Annuler'),
            onPressed: () => Navigator.pop(context, false),
          ),
          TextButton(
            child: Text('Supprimer', style: TextStyle(color: Colors.red)),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final parc = parcList.firstWhere((item) => item['id'] == id);

    final operationData = {
      'parc_id': id,
      'userId': widget.userId,
      'numero_serie': parc['numero_serie'],
      'materiel_id': parc['materiel_id'],
      'etat': parc['etat'],
      'disponibilite': parc['disponibilite'],
      'action': 'Supprimer',
      'motif': motifController.text.isEmpty ? 'Suppression' : motifController.text,
      'effectue_par': widget.userType,
      'etat_validation': widget.userType?.toLowerCase() == 'chef de parc' ? 'Validé' : 'En attente',
      'vu': widget.userType?.toLowerCase() == 'chef de parc' ? 1 : 0,
    };

    await _addOperation(operationData);
    if (widget.userType?.toLowerCase() == 'chef de parc') {
      final response = await http.delete(
        Uri.parse('http://localhost:3000/api/parc/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        print('Erreur lors de la suppression directe du parc: ${response.body}');
        showAlertError('Erreur', 'Erreur lors de la suppression directe du parc: ${response.body}');
      }
    }
    showAlertSuccess('Succès', widget.userType?.toLowerCase() == 'chef de parc'
        ? 'Suppression effectuée avec succès'
        : 'Suppression enregistrée, en attente de validation');
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
        content: Text("Voulez-vous vraiment supprimer cet élément du parc ?"),
        actions: [
          TextButton(
            child: Text("Annuler"),
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text("Supprimer", style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.pop(context);
              supprimerParc(id);
            },
          ),
        ],
      ),
    );
  }

  void onEdit(Map parc) {
    setState(() {
      editingId = parc['id'];
      numeroSerieController.text = parc['numero_serie'] ?? '';
      etat = parc['etat'] ?? '';
      disponibilite = parc['disponibilite'] ?? '';
      selectedMateriel = materiels.firstWhere(
            (m) => m['id'] == parc['materiel_id'],
        orElse: () => null,
      );
    });
  }

  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} ${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final tableWidth = width * 0.9;
    final colCount = 8;
    final colWidth = tableWidth / colCount;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text('Gestion de Parc'),
        backgroundColor: Colors.blue[800],
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 5,
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
              title: const Text('Déconnexion', style: TextStyle(color: Colors.red, fontFamily: 'Cairo')),
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Formulaire d'ajout ou modification
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
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double fieldWidth = constraints.maxWidth;
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_dropdownMaterielWidth != fieldWidth ||
                            _dropdownEtatWidth != fieldWidth ||
                            _dropdownDisponibiliteWidth != fieldWidth) {
                          setState(() {
                            _dropdownMaterielWidth = fieldWidth;
                            _dropdownEtatWidth = fieldWidth;
                            _dropdownDisponibiliteWidth = fieldWidth;
                          });
                        }
                      });
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Autocomplete<String>(
                            optionsBuilder: (TextEditingValue textEditingValue) {
                              final input = textEditingValue.text.trim().toLowerCase();
                              if (input.isEmpty) {
                                return numeroSerieList.isNotEmpty ? numeroSerieList : ['pc344', 'souris728'];
                              }
                              return numeroSerieList.where((String option) {
                                return option.toLowerCase().contains(input);
                              }).toList();
                            },
                            fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                              controller.text = numeroSerieController.text;
                              return SizedBox(
                                width: fieldWidth,
                                child: TextFormField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  onEditingComplete: onEditingComplete,
                                  decoration: const InputDecoration(
                                    labelText: 'Numéro de série',
                                    hintText: 'Entrez ou choisissez un numéro de série',
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: validateNumeroSerie,
                                  onChanged: (value) {
                                    numeroSerieController.text = value.trim();
                                  },
                                ),
                              );
                            },
                            optionsViewBuilder: (context, onSelected, options) {
                              print('Options disponibles: ${options.length}');
                              if (options.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Align(
                                alignment: Alignment.topLeft,
                                child: Material(
                                  elevation: 4.0,
                                  borderRadius: BorderRadius.circular(8),
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(maxHeight: 200),
                                    child: SizedBox(
                                      width: fieldWidth,
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
                                ),
                              );
                            },
                            onSelected: (String selection) {
                              setState(() {
                                numeroSerieController.text = selection;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: _dropdownMaterielWidth ?? fieldWidth,
                            child: DropdownButtonFormField<dynamic>(
                              value: selectedMateriel,
                              items: materiels
                                  .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                    "Type: ${m['type']} - Marque: ${m['marque']} - Modèle: ${m['modele']}"),
                              ))
                                  .toList(),
                              onChanged: (val) => setState(() => selectedMateriel = val),
                              decoration: const InputDecoration(
                                labelText: 'Sélectionner un matériel',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null ? 'Sélectionner un matériel' : null,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              selectedItemBuilder: (context) => materiels
                                  .map((m) => Container(
                                width: _dropdownMaterielWidth ?? fieldWidth,
                                child: Text(
                                  "Type: ${m['type']} - Marque: ${m['marque']} - Modèle: ${m['modele']}",
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: _dropdownEtatWidth ?? fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: etat,
                              items: ['fonctionnel', 'en panne', 'bonne état', 'neuf']
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: SizedBox(
                                    width: _dropdownEtatWidth ?? fieldWidth, child: Text(e)),
                              ))
                                  .toList(),
                              onChanged: (val) => setState(() => etat = val),
                              decoration: const InputDecoration(
                                labelText: 'État',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              selectedItemBuilder: (context) => ['fonctionnel', 'en panne', 'bonne état', 'neuf']
                                  .map((e) => Container(
                                width: _dropdownEtatWidth ?? fieldWidth,
                                child: Text(e, overflow: TextOverflow.ellipsis),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: _dropdownDisponibiliteWidth ?? fieldWidth,
                            child: DropdownButtonFormField<String>(
                              value: disponibilite,
                              items: ['disponible', 'occupé']
                                  .map((e) => DropdownMenuItem(
                                value: e,
                                child: SizedBox(
                                    width: _dropdownDisponibiliteWidth ?? fieldWidth, child: Text(e)),
                              ))
                                  .toList(),
                              onChanged: (val) => setState(() => disponibilite = val),
                              decoration: const InputDecoration(
                                labelText: 'Disponibilité',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Champ requis' : null,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              selectedItemBuilder: (context) => ['disponible', 'occupé']
                                  .map((e) => Container(
                                width: _dropdownDisponibiliteWidth ?? fieldWidth,
                                child: Text(e, overflow: TextOverflow.ellipsis),
                              ))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: fieldWidth,
                            child: TextFormField(
                              controller: motifController,
                              decoration: const InputDecoration(
                                labelText: 'Motif',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value == null || value.isEmpty ? 'Veuillez saisir le motif' : null,
                            ),
                          ),
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
                                onPressed: () {
                                  if (editingId == null) {
                                    enregistrerParc();
                                  } else {
                                    modifierParc();
                                  }
                                },
                                label: Text(
                                  editingId == null ? 'Ajouter' : 'Modifier',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                              ),
                              if (editingId != null) ...[
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
                              ],
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 270,
                child: RawAutocomplete<String>(
                  textEditingController: filterNumeroSerieController,
                  focusNode: filterNumeroSerieFocusNode,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    final input = textEditingValue.text.trim().toLowerCase();
                    if (input.isEmpty) {
                      return numeroSerieList.isNotEmpty ? numeroSerieList : ['pc344', 'souris728'];
                    }
                    return numeroSerieList.where((String option) {
                      return option.toLowerCase().contains(input);
                    }).toList();
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return SizedBox(
                      width: 270,
                      child: TextFormField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        decoration: const InputDecoration(
                          labelText: 'Filtrer par numéro de série',
                          hintText: 'Entrez un numéro ou choisissez',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.filter_list),
                        ),
                        onChanged: (value) {
                          setState(() {
                            filterNumeroSerie = value;
                            currentPage = 0;
                          });
                        },
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    print('Options disponibles: ${options.length}');
                    if (options.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4.0,
                        borderRadius: BorderRadius.circular(8),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: SizedBox(
                            width: 270,
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
                      ),
                    );
                  },
                  onSelected: (String selection) {
                    setState(() {
                      filterNumeroSerieController.text = selection;
                      filterNumeroSerie = selection;
                      currentPage = 0;
                    });
                    filterNumeroSerieFocusNode.unfocus();
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
                onPressed: showAll,
                label: const Text('Tout afficher', style: TextStyle(fontFamily: 'Cairo')),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                        headerCell('N° Série', colWidth),
                        headerCell('Type', colWidth),
                        headerCell('Marque', colWidth),
                        headerCell('Modèle', colWidth),
                        headerCell('État', colWidth),
                        headerCell('Disponibilité', colWidth),
                        headerCell('Date', colWidth),
                        headerCell('Actions', colWidth),
                      ],
                    ),
                  ),
                  Divider(height: 1, thickness: 1, color: Colors.black26),
                  ...List.generate(paginatedParcList.length, (i) {
                    final parc = paginatedParcList[i];
                    return Column(
                      children: [
                        Row(
                          children: [
                            dataCell(parc['numero_serie']?.toString() ?? '', colWidth),
                            dataCell(parc['typeMateriel']?.toString() ?? '', colWidth),
                            dataCell(parc['marque']?.toString() ?? '', colWidth),
                            dataCell(parc['modele']?.toString() ?? '', colWidth),
                            dataCell(parc['etat']?.toString() ?? '', colWidth),
                            dataCell(parc['disponibilite']?.toString() ?? '', colWidth),
                            dataCell(formatDateTime(parc['date']), colWidth),
                            Container(
                              width: colWidth,
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.green),
                                    tooltip: "Modifier",
                                    onPressed: () => onEdit(parc),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    tooltip: "Supprimer",
                                    onPressed: () => confirmDelete(parc['id']),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (i != paginatedParcList.length - 1)
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
                            style: const TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo'),
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
}