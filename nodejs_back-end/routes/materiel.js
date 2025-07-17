const express = require('express');
const router = express.Router();
const db = require('../db');

// Ajouter matériel (مع الربط بـ userId)
router.post('/ajouter', (req, res) => {
  const { type, marque, modele, userId } = req.body;
  if (!userId) {
    return res.status(400).json({ error: 'userId est requis' });
  }
  const sql = 'INSERT INTO materiel (type, marque, modele, userId) VALUES (?, ?, ?, ?)';
  db.query(sql, [type, marque, modele, userId], (err, result) => {
    if (err) return res.status(500).json({ error: 'Erreur serveur' });
    res.status(201).json({ message: 'Matériel ajouté avec succès' });
  });
});

// Afficher tous les matériels (مع إمكانية التصفية حسب userId)
router.get('/all', (req, res) => {
  const { userId } = req.query;
  let sql = 'SELECT * FROM materiel';
  let params = [];
  if (userId) {
    sql += ' WHERE userId = ?';
    params.push(userId);
  }
  db.query(sql, params, (err, results) => {
    if (err) return res.status(500).json({ error: 'Erreur serveur' });
    res.status(200).json(results);
  });
});

// Modifier matériel par ID (بدون تغيير userId)
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { type, marque, modele } = req.body;
  const sql = 'UPDATE materiel SET type = ?, marque = ?, modele = ? WHERE id = ?';
  db.query(sql, [type, marque, modele, id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Erreur lors de la mise à jour' });
    res.status(200).json({ message: 'Matériel mis à jour avec succès' });
  });
});

// Supprimer matériel par ID
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const sql = 'DELETE FROM materiel WHERE id = ?';
  db.query(sql, [id], (err, result) => {
    if (err) return res.status(500).json({ error: 'Erreur lors de la suppression' });
    res.status(200).json({ message: 'Matériel supprimé avec succès' });
  });
});

module.exports = router;