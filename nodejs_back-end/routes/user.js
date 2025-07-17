const express = require('express');
const router = express.Router();
const db = require('../db');
const bcrypt = require('bcrypt');

// Enregistrement d'un utilisateur (signup)
router.post('/inscrire', (req, res) => {
  const { email, password, nom, prenom, nni, type, etat } = req.body;

  // Vérifie si l'utilisateur existe déjà
  const checkQuery = 'SELECT * FROM utilisateurs WHERE email = ?';
  db.query(checkQuery, [email], async (err, results) => {
    if (err) {
      console.error('Erreur lors de la vérification :', err);
      return res.status(500).json({ message: 'Erreur serveur' });
    }
    if (results.length > 0) {
      return res.status(400).json({ message: 'Cet utilisateur existe déjà.' });
    }

    try {
      // Générer le hash du mot de passe
      const saltRounds = 10;
      const hash = await bcrypt.hash(password, saltRounds);

      // Insère le nouvel utilisateur avec mot de passe hashé
      const insertQuery =
        `INSERT INTO utilisateurs (nni, nom, prenom, email, password, type, etat)
        VALUES (?, ?, ?, ?, ?, ?, ?)`;
      db.query(insertQuery, [nni, nom, prenom, email, hash, type, etat], (err, result) => {
        if (err) {
          console.error('Erreur lors de l\'insertion :', err);
          return res.status(500).json({ message: 'Erreur serveur' });
        }
        console.log('Utilisateur enregistré');
        res.status(201).json({
          message: 'Utilisateur enregistré avec succès',
          user: {
            id: result.insertId,
            email,
            nom,
            prenom,
            nni,
            type,
            etat
          }
        });
      });
    } catch (hashErr) {
      console.error('Erreur hash bcrypt:', hashErr);
      res.status(500).json({ message: 'Erreur lors du hachage du mot de passe' });
    }
  });
});

// Connexion d'un utilisateur (login)
router.post('/seconnecter', (req, res) => {
  const { email, password } = req.body;
  const query = 'SELECT * FROM utilisateurs WHERE email = ?';
  db.query(query, [email], async (err, results) => {
    if (err) {
      console.error('Erreur lors de la connexion :', err);
      return res.status(500).json({ message: 'Erreur serveur' });
    }
    if (results.length > 0) {
      const user = results[0];
      // Comparer le mot de passe entré avec le hash stocké
      const match = await bcrypt.compare(password, user.password);
      if (match) {
        res.json({ message: 'Connexion réussie', user });
      } else {
        res.status(401).json({ message: 'Email ou mot de passe incorrect' });
      }
    } else {
      res.status(401).json({ message: 'Email ou mot de passe incorrect' });
    }
  });
});

// Liste de tous les utilisateurs
router.get('/all', (req, res) => {
  db.query('SELECT * FROM utilisateurs', (err, results) => {
    if (err) {
      console.error('Erreur lors de la récupération :', err);
      return res.status(500).json({ message: 'Erreur serveur' });
    }
    res.json(results);
  });
});

// Modifier utilisateur par ID (hash le mot de passe si modifié)
router.put('/:id', async (req, res) => {
  const { id } = req.params;
  const { email, password, nom, prenom, nni, type, etat } = req.body;

  // On prépare la requête et les paramètres
  let updateQuery = 'UPDATE utilisateurs SET nni=?, nom=?, prenom=?, email=?, type=?, etat=?';
  let params = [nni, nom, prenom, email, type, etat];

  // Si password fourni (non vide), on le hash et on l'inclut
  if (typeof password === 'string' && password.trim().length > 0) {
    try {
      const saltRounds = 10;
      const hash = await bcrypt.hash(password, saltRounds);
      updateQuery += ', password=?';
      params.push(hash);
    } catch (hashErr) {
      console.error('Erreur hash bcrypt:', hashErr);
      return res.status(500).json({ message: 'Erreur lors du hachage du mot de passe' });
    }
  }
  updateQuery += ' WHERE id=?';
  params.push(id);

  db.query(updateQuery, params, (err, result) => {
    if (err) {
      console.error('Erreur lors de la mise à jour:', err);
      return res.status(500).json({ message: 'Erreur lors de la mise à jour' });
    }
    res.status(200).json({ message: 'Utilisateur modifié avec succès' });
  });
});

// Supprimer utilisateur par ID
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  const sql = 'DELETE FROM utilisateurs WHERE id = ?';
  db.query(sql, [id], (err, result) => {
    if (err) {
      console.error('Erreur lors de la suppression:', err);
      return res.status(500).json({ message: 'Erreur lors de la suppression' });
    }
    res.status(200).json({ message: 'Utilisateur supprimé avec succès' });
  });
});

module.exports = router;