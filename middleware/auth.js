const jwt = require('jsonwebtoken');
const db = require('../config/db');

exports.protect = async (req, res, next) => {
    let token;

    if (req.headers.authorization && req.headers.authorization.startsWith('Bearer')) {
        try {
            token = req.headers.authorization.split(' ')[1];

            // Decode the token
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            
            // Fetch user from DB to ensure they still exist
            const result = await db.query('SELECT id, user_role, email FROM users WHERE id = $1', [decoded.userId]);
            
            if (result.rows.length === 0) {
                return res.status(401).json({ success: false, error: 'User belonging to this token no longer exists.' });
            }

            // Attach user to request object (force role to lowercase just in case)
            req.user = {
                userId: result.rows[0].id,
                role: (result.rows[0].user_role || '').toLowerCase(),
                email: result.rows[0].email
            };
            
            return next();
        } catch (error) {
            console.error('Auth Middleware Error:', error);
            return res.status(401).json({ success: false, error: 'Not authorized, token failed' });
        }
    }

    if (!token) {
        return res.status(401).json({ success: false, error: 'Not authorized, no token provided' });
    }
};

exports.restrictTo = (...roles) => {
    return (req, res, next) => {
        // Map roles to lowercase for safe comparison
        const safeRoles = roles.map(r => r.toLowerCase());
        
        if (!req.user || !safeRoles.includes(req.user.role)) {
            return res.status(403).json({ success: false, error: "You do not have permission to perform this action" });
        }
        next();
    };
};

exports.isAdmin = (req, res, next) => {
    if (req.user && (req.user.role === 'admin' || req.user.role === 'agency_staff')) {
        next();
    } else {
        res.status(403).json({ success: false, error: 'Access denied. Admin or agency staff role required.' });
    }
};