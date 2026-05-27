const express = require('express');
const router = express.Router();
// IMPORTANT: adjust this path depending on where your database connection file is located
const db = require('../config/db'); 

// Fetch upcoming tours
router.get('/upcoming', async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM upcoming_tours_view');
    res.json(result.rows);
  } catch (error) {
    console.error('Error in /upcoming:', error);
    res.status(500).json({ error: error.message });
  }
});

module.exports = router;