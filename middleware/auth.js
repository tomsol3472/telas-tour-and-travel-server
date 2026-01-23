const jwt = require('jsonwebtoken');
const db = require('../config/db');

exports.protect = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];

            // Decode the token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            
            // --- THE FIX IS HERE ---
            // We use 'decoded.id' because that is how we signed it in authController
            const result = await db.query('SELECT id, user_role, email FROM users WHERE id = $1', [decoded.id]);
            
            if (result.rows.length === 0) {
                return res.status(401).json({ error: 'User belonging to this token no longer exists.' });
            }

            req.user = {
                userId: result.rows[0].id,
                role: result.rows[0].user_role,
                email: result.rows[0].email
            };
            
            next();
        } catch (error) {
            console.error(error);
            return res.status(401).json({ error: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ error: 'Not authorized, no token' });
    }
};