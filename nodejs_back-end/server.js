const express = require('express');
const cors = require('cors');
const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// استيراد ملفات التوجيه
const userRoutes = require('./routes/user');
const materielRoutes = require('./routes/materiel');
const parcRoutes = require('./routes/parc');

// استخدام الملفات
app.use('/api/user', userRoutes);
app.use('/api/materiel', materielRoutes);
app.use('/api/parc', parcRoutes); 

app.listen(PORT, 'localhost', () => {
  console.log(`Serveur Node.js sur http://localhost:${PORT}`);
});