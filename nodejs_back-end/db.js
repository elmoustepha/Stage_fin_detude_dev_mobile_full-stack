// db.js
const mysql = require('mysql2');

const connection = mysql.createConnection({
  host: 'localhost',
  user: 'root',          // mets ton utilisateur MySQL
  password: '',          // ton mot de passe MySQL (vide si aucun)
  database: 'monbd'      // le nom de ta base de données
});

connection.connect((err) => {
  if (err) {
    console.error('Erreur de connexion à MySQL :', err);
    return;
  }
  console.log('Connecté à la base de données MySQL');
});

module.exports = connection;
