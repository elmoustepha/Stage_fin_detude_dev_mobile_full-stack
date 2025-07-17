const express = require('express');
const router = express.Router();
const db = require('../db');

// Ajouter un nouveau matériel dans le parc (pour le chef de parc uniquement)
router.post('/enregistrer', (req, res) => {
  const { materiel_id, numero_serie, etat, disponibilite, date, userId, effectue_par } = req.body;
  if (!materiel_id || !numero_serie || !etat || !disponibilite || !date || !userId || !effectue_par) {
    return res.status(400).json({ message: 'Champs manquants' });
  }

  if (effectue_par.toLowerCase() !== 'chef de parc') {
    return res.status(403).json({ message: 'Seul le chef de parc peut ajouter directement un matériel' });
  }

  // Vérifier si numero_serie existe déjà
  db.query('SELECT id FROM parc WHERE numero_serie = ?', [numero_serie], (err, rows) => {
    if (err) {
      console.error('Erreur lors de la vérification de numero_serie:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
    if (rows.length > 0) {
      return res.status(400).json({ message: 'Numéro de série déjà existant' });
    }

    // Récupérer les informations de materiel
    db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [materiel_id], (err, materielRows) => {
      if (err || materielRows.length === 0) {
        return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
      }
      const { type, marque, modele } = materielRows[0];

      // Insérer dans parc avec les nouvelles colonnes
      const query = `
        INSERT INTO parc (materiel_id, numero_serie, etat, disponibilite, date, userId, type, marque, modele)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
      `;
      db.query(query, [materiel_id, numero_serie, etat, disponibilite, date, userId, type, marque, modele], (err, result) => {
        if (err) {
          console.error('Erreur lors de l\'ajout dans le parc:', err);
          return res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }

        // Enregistrer une opération dans l'historique pour le chef de parc
        const operationQuery = `
          INSERT INTO operations_historique 
          (parc_id, userId, numero_serie, materiel_id, etat, disponibilite, action, motif, effectue_par, etat_validation, date_action, vu)
          VALUES (?, ?, ?, ?, ?, ?, 'Ajouter', '', 'Chef de parc', 'Validé', NOW(), 1)
        `;
        db.query(operationQuery, [result.insertId, userId, numero_serie, materiel_id, etat, disponibilite], (err) => {
          if (err) {
            console.error('Erreur lors de l\'enregistrement de l\'opération pour le chef:', err);
          }
          res.status(201).json({ message: 'Enregistrement créé', id: result.insertId });
        });
      });
    });
  });
});

// Récupérer tous les matériels dans le parc (uniquement validés)
router.get('/all', (req, res) => {
  const query = `
    SELECT 
      parc.id, parc.userId, parc.numero_serie, parc.etat, parc.disponibilite, parc.date, parc.materiel_id,
      parc.type AS typeMateriel, parc.marque, parc.modele
    FROM parc
    INNER JOIN operations_historique oh ON parc.id = oh.parc_id
    WHERE oh.etat_validation = 'Validé'
    ORDER BY parc.date DESC
  `;
  db.query(query, (err, rows) => {
    if (err) {
      console.error('Erreur lors de la récupération des matériels:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
    res.json(rows);
  });
});

// Modifier un matériel dans le parc
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { materiel_id, numero_serie, etat, disponibilite, userId, effectue_par } = req.body;
  if (!materiel_id || !numero_serie || !etat || !disponibilite || !userId || !effectue_par) {
    return res.status(400).json({ message: 'Champs manquants' });
  }

  // Vérifier si numero_serie existe déjà pour un autre matériel
  db.query('SELECT id FROM parc WHERE numero_serie = ? AND id != ?', [numero_serie, id], (err, rows) => {
    if (err) {
      console.error('Erreur lors de la vérification de numero_serie:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
    if (rows.length > 0) {
      return res.status(400).json({ message: 'Numéro de série déjà existant' });
    }

    // Récupérer les informations de materiel
    db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [materiel_id], (err, materielRows) => {
      if (err || materielRows.length === 0) {
        return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
      }
      const { type, marque, modele } = materielRows[0];

      const query = `
        UPDATE parc
        SET materiel_id = ?, numero_serie = ?, etat = ?, disponibilite = ?, userId = ?, type = ?, marque = ?, modele = ?
        WHERE id = ?
      `;
      db.query(query, [materiel_id, numero_serie, etat, disponibilite, userId, type, marque, modele, id], (err) => {
        if (err) {
          console.error('Erreur lors de la modification du parc:', err);
          return res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
        res.json({ message: 'Modification réussie' });
      });
    });
  });
});

// Supprimer un matériel du parc
router.delete('/:id', (req, res) => {
  const { id } = req.params;
  db.query('DELETE FROM parc WHERE id = ?', [id], (err, result) => {
    if (err) {
      console.error('Erreur lors de la suppression du parc:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
    if (result.affectedRows === 0) {
      return res.status(404).json({ message: 'Matériel non trouvé' });
    }
    res.json({ message: 'Suppression réussie' });
  });
});

// Récupérer toutes les opérations
router.get('/allOperations', (req, res) => {
  const { userId, includeAll } = req.query;
  let sql = `
    SELECT
      h.id, h.userId, h.parc_id, h.numero_serie, h.materiel_id, h.etat, h.disponibilite, h.action, h.motif,
      h.effectue_par, h.etat_validation, h.date_action, h.vu
    FROM operations_historique h
  `;
  const params = [];

  if (userId && !includeAll) {
    sql += ' WHERE h.userId = ?';
    params.push(userId);
  }

  sql += ' ORDER BY h.date_action DESC';

  db.query(sql, params, (err, results) => {
    if (err) {
      console.error('Erreur lors de la récupération des opérations:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }

    if (userId && includeAll) {
      const updateSql = `
        UPDATE operations_historique
        SET vu = 1
        WHERE userId = ? AND vu = 0 AND etat_validation IN ('Validé', 'Rejeté')
      `;
      db.query(updateSql, [userId], (err) => {
        if (err) {
          console.error('Erreur lors de la mise à jour du champ vu:', err);
        }
      });
    }

    res.json(results);
  });
});

// Enregistrer une opération dans l'historique
router.post('/operations', (req, res) => {
  const {
    parc_id, userId, numero_serie, materiel_id, etat, disponibilite, action,
    motif = '', effectue_par, etat_validation = 'En attente'
  } = req.body;

  // Vérification des champs obligatoires
  if (!userId || !numero_serie || !materiel_id || !etat || !disponibilite || !action || !effectue_par) {
    console.error('Champs manquants dans la requête:', req.body);
    return res.status(400).json({ message: 'Champs obligatoires manquants' });
  }

  // Déterminer si l'utilisateur est un technicien ou un chef de parc
  const isTechnicien = effectue_par.toLowerCase() === 'technicien';
  const finalEtatValidation = isTechnicien ? 'En attente' : 'Validé';

  // Fonction pour insérer l'opération dans operations_historique
  const insertOperation = (parcId) => {
    const sql = `
      INSERT INTO operations_historique 
      (parc_id, userId, numero_serie, materiel_id, etat, disponibilite, action, motif, effectue_par, etat_validation, date_action, vu)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, NOW(), ?)
    `;
    const vu = isTechnicien ? 0 : 1;
    const params = [
      parcId || null, userId, numero_serie, materiel_id, etat, disponibilite, action, motif, effectue_par, finalEtatValidation, vu
    ];

    db.query(sql, params, (err, result) => {
      if (err) {
        console.error('Erreur lors de l\'enregistrement de l\'opération:', err);
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      db.query('SELECT * FROM operations_historique WHERE id = ?', [result.insertId], (err, rows) => {
        if (err) {
          console.error('Erreur lors de la récupération de l\'opération après insertion:', err);
          return res.status(500).json({ message: 'Erreur serveur', error: err.message });
        }
        res.status(201).json({ message: 'Opération enregistrée avec succès', id: result.insertId, operation: rows[0] });
      });
    });
  };

  // Si c'est un ajout, insérer d'abord dans parc uniquement si ce n'est pas un technicien
  if (action.toLowerCase() === 'ajouter') {
    if (!isTechnicien) {
      // Vérification supplémentaire pour les champs requis pour l'insertion dans parc
      if (!materiel_id || !numero_serie || !etat || !disponibilite || !userId) {
        console.error('Champs manquants pour l\'ajout dans parc:', { materiel_id, numero_serie, etat, disponibilite, userId });
        return res.status(400).json({ message: 'Champs requis pour l\'ajout manquants' });
      }

      // Récupérer les informations de materiel
      db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [materiel_id], (err, materielRows) => {
        if (err || materielRows.length === 0) {
          return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
        }
        const { type, marque, modele } = materielRows[0];

        // Vérifier si numero_serie existe déjà
        db.query('SELECT id FROM parc WHERE numero_serie = ?', [numero_serie], (err, rows) => {
          if (err) {
            console.error('Erreur lors de la vérification de numero_serie:', err);
            return res.status(500).json({ message: 'Erreur serveur', error: err.message });
          }
          if (rows.length > 0) {
            return res.status(400).json({ message: 'Numéro de série déjà existant' });
          }

          // Insérer dans parc
          const parcQuery = `
            INSERT INTO parc (materiel_id, numero_serie, etat, disponibilite, date, userId, type, marque, modele)
            VALUES (?, ?, ?, ?, NOW(), ?, ?, ?, ?)
          `;
          db.query(parcQuery, [materiel_id, numero_serie, etat, disponibilite, userId, type, marque, modele], (err, result) => {
            if (err) {
              console.error('Erreur lors de l\'ajout dans le parc:', err);
              return res.status(500).json({ message: 'Erreur lors de l\'ajout dans le parc', error: err.message });
            }
            insertOperation(result.insertId);
          });
        });
      });
    } else {
      // Pour le technicien, ne pas insérer dans parc, utiliser parc_id = NULL
      insertOperation(null);
    }
  } else if (action.toLowerCase() === 'modifier' || action.toLowerCase() === 'supprimer') {
    // Pour le chef de parc, mettre à jour ou supprimer directement dans parc
    if (!isTechnicien && parc_id) {
      if (action.toLowerCase() === 'modifier') {
        // Récupérer les informations de materiel
        db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [materiel_id], (err, materielRows) => {
          if (err || materielRows.length === 0) {
            return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
          }
          const { type, marque, modele } = materielRows[0];

          const updateSql = `
            UPDATE parc SET materiel_id = ?, numero_serie = ?, etat = ?, disponibilite = ?, userId = ?, type = ?, marque = ?, modele = ?
            WHERE id = ?
          `;
          db.query(updateSql, [materiel_id, numero_serie, etat, disponibilite, userId, type, marque, modele, parc_id], (err) => {
            if (err) {
              console.error('Erreur lors de la modification directe du parc:', err);
              return res.status(500).json({ message: 'Erreur lors de la modification du parc', error: err.message });
            }
            insertOperation(parc_id);
          });
        });
      } else if (action.toLowerCase() === 'supprimer') {
        const deleteSql = `DELETE FROM parc WHERE id = ?`;
        db.query(deleteSql, [parc_id], (err, result) => {
          if (err) {
            console.error('Erreur lors de la suppression directe du parc:', err);
            return res.status(500).json({ message: 'Erreur lors de la suppression du parc', error: err.message });
          }
          if (result.affectedRows === 0) {
            return res.status(404).json({ message: 'Matériel non trouvé pour suppression' });
          }
          // Pour le chef de parc, définir parc_id comme NULL après la suppression
          insertOperation(null);
        });
      }
    } else {
      // Pour le technicien ou si parc_id est manquant
      if (!parc_id) {
        console.error('parc_id manquant pour l\'action:', action);
        return res.status(400).json({ message: 'parc_id requis pour les actions autres que Ajouter' });
      }
      insertOperation(parc_id);
    }
  }
});

// Mettre à jour l'état de validation d'une opération
router.put('/operations/:id', (req, res) => {
  const { id } = req.params;
  const { etat_validation } = req.body;

  if (!etat_validation) {
    return res.status(400).json({ message: 'Champ etat_validation requis' });
  }

  db.query('SELECT * FROM operations_historique WHERE id = ?', [id], (err, rows) => {
    if (err || rows.length === 0) {
      console.error('Erreur lors de la récupération de l\'opération:', err || 'Opération introuvable');
      return res.status(404).json({ message: 'Opération introuvable' });
    }

    const operation = rows[0];

    db.query('UPDATE operations_historique SET etat_validation = ? WHERE id = ?', [etat_validation, id], (err) => {
      if (err) {
        console.error('Erreur lors de la mise à jour de l\'état de validation:', err);
        return res.status(500).json({ message: 'Erreur serveur', error: err.message });
      }

      if (etat_validation === 'Validé') {
        if (operation.action === 'Ajouter' && !operation.parc_id) {
          // Récupérer les informations de materiel
          db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [operation.materiel_id], (err, materielRows) => {
            if (err || materielRows.length === 0) {
              return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
            }
            const { type, marque, modele } = materielRows[0];

            // Insérer dans parc uniquement si parc_id est NULL (ajout par technicien validé)
            const parcQuery = `
              INSERT INTO parc (materiel_id, numero_serie, etat, disponibilite, date, userId, type, marque, modele)
              VALUES (?, ?, ?, ?, NOW(), ?, ?, ?, ?)
            `;
            db.query(parcQuery, [operation.materiel_id, operation.numero_serie, operation.etat, operation.disponibilite, operation.userId, type, marque, modele], (err, result) => {
              if (err) {
                console.error('Erreur lors de l\'ajout dans le parc:', err);
                return res.status(500).json({ message: 'Erreur lors de l\'ajout dans le parc', error: err.message });
              }
              // Mettre à jour parc_id dans operations_historique
              db.query('UPDATE operations_historique SET parc_id = ? WHERE id = ?', [result.insertId, id], (err) => {
                if (err) {
                  console.error('Erreur lors de la mise à jour de parc_id:', err);
                }
                res.json({ message: 'Opération validée et matériel ajouté' });
              });
            });
          });
        } else if (operation.action === 'Modifier') {
          // Récupérer les informations de materiel
          db.query('SELECT type, marque, modele FROM materiel WHERE id = ?', [operation.materiel_id], (err, materielRows) => {
            if (err || materielRows.length === 0) {
              return res.status(500).json({ message: 'Erreur lors de la récupération des détails du matériel' });
            }
            const { type, marque, modele } = materielRows[0];

            const updateSql = `
              UPDATE parc SET materiel_id = ?, numero_serie = ?, etat = ?, disponibilite = ?, type = ?, marque = ?, modele = ?
              WHERE id = ?
            `;
            db.query(updateSql, [operation.materiel_id, operation.numero_serie, operation.etat, operation.disponibilite, type, marque, modele, operation.parc_id], (err) => {
              if (err) {
                console.error('Erreur lors de la modification du parc:', err);
                return res.status(500).json({ message: 'Erreur lors de la modification du parc', error: err.message });
              }
              res.json({ message: 'Opération validée et matériel modifié' });
            });
          });
        } else if (operation.action === 'Supprimer') {
          const deleteSql = `DELETE FROM parc WHERE id = ?`;
          db.query(deleteSql, [operation.parc_id], (err, result) => {
            if (err) {
              console.error('Erreur lors de la suppression du parc:', err);
              return res.status(500).json({ message: 'Erreur lors de la suppression du parc', error: err.message });
            }
            if (result.affectedRows === 0) {
              return res.status(404).json({ message: 'Matériel non trouvé pour suppression' });
            }
            res.json({ message: 'Opération validée et matériel supprimé' });
          });
        } else {
          res.json({ message: 'Opération validée' });
        }
      } else if (etat_validation === 'Rejeté' && operation.action === 'Ajouter' && !operation.parc_id) {
        // Ne rien faire pour le parc si parc_id est NULL (ajout rejeté par technicien)
        res.json({ message: 'Opération rejetée' });
      } else {
        res.json({ message: 'État de validation mis à jour' });
      }
    });
  });
});

// Marquer les opérations comme vues (pour le technicien)
router.patch('/markSeen', (req, res) => {
  const { userId } = req.query;
  if (!userId) {
    return res.status(400).json({ message: 'userId est requis' });
  }

  const sql = `
    UPDATE operations_historique
    SET vu = TRUE
    WHERE userId = ? AND (etat_validation = 'Validé' OR etat_validation = 'Rejeté')
    AND (vu IS NULL OR vu = FALSE)
  `;
  db.query(sql, [userId], (err) => {
    if (err) {
      console.error('Erreur lors du marquage des opérations comme vues:', err);
      return res.status(500).json({ message: 'Erreur serveur', error: err.message });
    }
    res.json({ message: 'Opérations marquées comme vues' });
  });
});

module.exports = router;