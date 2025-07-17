import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ParcTab extends StatefulWidget {
  final int? userId;
  final String? userType;

  const ParcTab({Key? key, this.userId, this.userType = ''}) : super(key: key);

  @override
  State<ParcTab> createState() => _ParcTabState();
}

class _ParcTabState extends State<ParcTab> {
  List<Map<String, dynamic>> parcList = [];
  List<Map<String, dynamic>> operations = [];

  int parcRowsPerPage = 5;
  int parcCurrentPage = 0;
  int opRowsPerPage = 5;
  int opCurrentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _markOperationsSeenIfTechnicien();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _fetchParc(),
      _fetchOperations(),
    ]);
  }

  Future<void> _markOperationsSeenIfTechnicien() async {
    if (widget.userType?.toLowerCase() == "technicien" && widget.userId != null) {
      final response = await http.patch(
        Uri.parse('http://localhost:3000/api/parc/markSeen?userId=${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode != 200) {
        print('Erreur lors du marquage des opérations comme vues: ${response.body}');
      }
    }
  }

  Future<void> _fetchParc() async {
    final response = await http.get(Uri.parse('http://localhost:3000/api/parc/all'));
    if (response.statusCode == 200) {
      setState(() {
        parcList = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print('Erreur lors de la récupération des données du parc: ${response.statusCode} - ${response.body}');
    }
  }

  Future<void> _fetchOperations() async {
    String url = 'http://localhost:3000/api/parc/allOperations?includeAll=true';
    if (widget.userId != null && widget.userType?.toLowerCase() == 'technicien') {
      url += '&userId=${widget.userId}';
    }
    try {
      print('Récupération des opérations depuis: $url');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        setState(() {
          operations = List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        print('Erreur lors de la récupération des opérations: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Exception lors de la récupération des opérations: $e');
    }
  }

  List<Map<String, dynamic>> get filteredOperations => operations;

  Future<void> _updateEtatValidation(int id, String etatValidation) async {
    final response = await http.put(
      Uri.parse('http://localhost:3000/api/parc/operations/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'etat_validation': etatValidation}),
    );

    if (response.statusCode == 200) {
      final operation = operations.firstWhere((op) => op['id'] == id, orElse: () => {});
      if (operation.isEmpty) {
        print('Opération introuvable pour l\'ID: $id');
        return;
      }

      if (etatValidation == 'Validé') {
        if (operation['action'] == 'Ajouter' && operation['parc_id'] == null) {
          final parcData = {
            'materiel_id': operation['materiel_id'],
            'numero_serie': operation['numero_serie'],
            'etat': operation['etat'],
            'disponibilite': operation['disponibilite'],
            'date': DateTime.now().toIso8601String(),
            'userId': operation['userId'],
          };
          final parcResponse = await http.post(
            Uri.parse('http://localhost:3000/api/parc/enregistrer'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(parcData),
          );
          if (parcResponse.statusCode == 201) {
            final newParcId = jsonDecode(parcResponse.body)['id'];
            await http.put(
              Uri.parse('http://localhost:3000/api/parc/operations/$id'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'etat_validation': 'Validé', 'parc_id': newParcId}),
            );
          } else {
            print('Erreur lors de l\'ajout dans le parc: ${parcResponse.body}');
          }
        } else if (operation['action'] == 'Modifier') {
          final parcData = {
            'materiel_id': operation['materiel_id'],
            'numero_serie': operation['numero_serie'],
            'etat': operation['etat'],
            'disponibilite': operation['disponibilite'],
            'userId': operation['userId'],
          };
          final parcResponse = await http.put(
            Uri.parse('http://localhost:3000/api/parc/${operation['parc_id']}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(parcData),
          );
          if (parcResponse.statusCode != 200) {
            print('Erreur lors de la modification du parc: ${parcResponse.body}');
          }
        } else if (operation['action'] == 'Supprimer') {
          final parcResponse = await http.delete(
            Uri.parse('http://localhost:3000/api/parc/${operation['parc_id']}?userId=${widget.userId}'),
          );
          if (parcResponse.statusCode != 200) {
            print('Erreur lors de la suppression du parc: ${parcResponse.body}');
          }
        }
      } else if (etatValidation == 'Rejeté' && operation['action'] == 'Ajouter' && operation['parc_id'] != null) {
        
      }

      await _fetchOperations();
      await _fetchParc();
      setState(() {});
    } else {
      print('Erreur lors de la mise à jour de l\'état de validation: ${response.body}');
    }
  }

  String formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString).toLocal();
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} ${date.hour.toString().padLeft(2, '0')}:"
          "${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return dateString;
    }
  }

  Widget buildEtatValidationCell(Map<String, dynamic> op) {
    if (widget.userType?.toLowerCase() == "chef de parc" &&
        op['effectue_par']?.toLowerCase() == "technicien" &&
        op['etat_validation'] == "En attente") {
      return Row(
        children: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            onPressed: () async {
              await _updateEtatValidation(op['id'], 'Validé');
            },
            child: const Text('Valider', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            ),
            onPressed: () async {
              await _updateEtatValidation(op['id'], 'Rejeté');
            },
            child: const Text('Rejeter', style: TextStyle(fontSize: 12)),
          ),
        ],
      );
    }
    return Text(op['etat_validation'] ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final parcTotalPages = (parcList.length / parcRowsPerPage).ceil();
    final parcStart = parcCurrentPage * parcRowsPerPage;
    final parcEnd = (parcStart + parcRowsPerPage).clamp(0, parcList.length);
    final parcRows = parcList.sublist(parcStart, parcEnd);

    final filteredOps = filteredOperations;
    final opTotalPages = (filteredOps.length / opRowsPerPage).ceil();
    final opStart = opCurrentPage * opRowsPerPage;
    final opEnd = (opStart + opRowsPerPage).clamp(0, filteredOps.length);
    final opRows = filteredOps.sublist(opStart, opEnd);

    // Fond de l'écran avec la couleur demandée
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 20),
              const Text('Liste des matériels', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              buildParcTable(parcRows, parcTotalPages),
              const SizedBox(height: 28),
              const Text('Historique des opérations', style: TextStyle(fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              buildOperationsTable(opRows, opTotalPages),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildParcTable(List<Map<String, dynamic>> rows, int totalPages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
          dataRowColor: MaterialStateProperty.all(Colors.white),
          columns: const [
            DataColumn(label: Text('Numéro de série', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('Type', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('Marque', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('Modèle', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('État', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('Disponibilité', style: TextStyle(fontFamily: 'Cairo'))),
            DataColumn(label: Text('Date', style: TextStyle(fontFamily: 'Cairo'))),
          ],
          rows: rows.map((row) {
            return DataRow(
              color: MaterialStateProperty.all(
                rows.indexOf(row).isEven ? Colors.white : Colors.grey.shade50,
              ),
              cells: [
                DataCell(Text(row['numero_serie']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(row['typeMateriel']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(row['marque']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(row['modele']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(row['etat']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(row['disponibilite']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                DataCell(Text(formatDateTime(row['date']), style: TextStyle(fontFamily: 'Cairo'))),
              ],
            );
          }).toList(),
        ),
        if (parcList.length > parcRowsPerPage)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: parcCurrentPage > 0 ? () => setState(() => parcCurrentPage--) : null,
              ),
              Text('Page ${parcCurrentPage + 1} / $totalPages', style: TextStyle(fontFamily: 'Cairo')),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: parcCurrentPage < totalPages - 1 ? () => setState(() => parcCurrentPage++) : null,
              ),
            ],
          ),
      ],
    );
  }

  Widget buildOperationsTable(List<Map<String, dynamic>> rows, int totalPages) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(Colors.grey.shade300),
            dataRowColor: MaterialStateProperty.all(Colors.white),
            columns: const [
              DataColumn(label: Text('Numéro de série', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('État', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('Disponibilité', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('Action', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('Motif', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('Effectué par', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text('État de validation', style: TextStyle(fontFamily: 'Cairo'))),
              DataColumn(label: Text("Date de l'opération", style: TextStyle(fontFamily: 'Cairo'))),
            ],
            rows: rows.map((op) {
              return DataRow(
                color: MaterialStateProperty.all(
                  rows.indexOf(op).isEven ? Colors.white : Colors.grey.shade50,
                ),
                cells: [
                  DataCell(Text(op['numero_serie']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(Text(op['etat']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(Text(op['disponibilite']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(Text(op['action']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(Text(op['motif']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(Text(op['effectue_par']?.toString() ?? '', style: TextStyle(fontFamily: 'Cairo'))),
                  DataCell(buildEtatValidationCell(op)),
                  DataCell(Text(formatDateTime(op['date_action'] ?? op['date']), style: TextStyle(fontFamily: 'Cairo'))),
                ],
              );
            }).toList(),
          ),
        ),
        if (filteredOperations.length > opRowsPerPage)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_left),
                onPressed: opCurrentPage > 0 ? () => setState(() => opCurrentPage--) : null,
              ),
              Text('Page ${opCurrentPage + 1} / $totalPages', style: TextStyle(fontFamily: 'Cairo')),
              IconButton(
                icon: const Icon(Icons.arrow_right),
                onPressed: opCurrentPage < totalPages - 1 ? () => setState(() => opCurrentPage++) : null,
              ),
            ],
          ),
      ],
    );
  }
}