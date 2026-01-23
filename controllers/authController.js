const db = require('../config/db');
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// Helper to create token
const signToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '30d' });
};

// --- REGISTER FUNCTION (THIS WAS MISSING/UNDEFINED) ---
exports.register = async (req, res) => {
  const { email, phone, password, role, first_name, last_name } = req.body;

  try {
    // 1. Validate Input
    if (!email || !phone || !password || !role) {
      return res.status(400).json({ error: "Missing required fields" });
    }

    // 2. Start Transaction
    await db.query('BEGIN');

    // 3. Hash Password
    const hashedPassword = await bcrypt.hash(password, 10);

    // 4. Create User
    const userRes = await db.query(
      `INSERT INTO users (user_role, email, phone, password_hash, status) 
       VALUES ($1, $2, $3, $4, 'active') RETURNING id`,
      [role, email, phone, hashedPassword]
    );
    const userId = userRes.rows[0].id;

    // 5. Create Profile
    await db.query(
      `INSERT INTO user_profiles (user_id, first_name, last_name) VALUES ($1, $2, $3)`,
      [userId, first_name, last_name]
    );

    // 6. Create Role Entry (Tourist)
    if (role === 'tourist') {
      await db.query(`INSERT INTO tourists (user_id) VALUES ($1)`, [userId]);
    }

    await db.query('COMMIT');

    const token = signToken(userId);
    res.status(201).json({ success: true, token, userId });

  } catch (error) {
    await db.query('ROLLBACK');
    console.error(error);
    res.status(500).json({ error: 'Registration failed. Email or Phone might already exist.' });
  }
};

// --- LOGIN FUNCTION ---
exports.login = async (req, res) => {
  const { identifier, password } = req.body; 

  try {
    const result = await db.query(
      "SELECT * FROM users WHERE email = $1 OR phone = $1", 
      [identifier]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const user = result.rows[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    
    if (!isMatch) {
      return res.status(400).json({ error: "Invalid credentials" });
    }

    const token = signToken(user.id);
    res.json({ success: true, token, role: user.user_role });

  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "Login error" });
  }
};