const db = require('../config/db');

// @desc    Get all system configurations
// @route   GET /api/settings/system
// @access  Admin
exports.getSystemConfigurations = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT id, config_key, config_value, config_type, category, 
             description, is_public, created_at, updated_at
      FROM system_configurations
      ORDER BY category, config_key
    `);

    // Group by category
    const configsByCategory = {};
    result.rows.forEach(config => {
      const cat = config.category || 'uncategorized';
      if (!configsByCategory[cat]) {
        configsByCategory[cat] = [];
      }
      configsByCategory[cat].push(config);
    });

    res.status(200).json({
      success: true,
      data: {
        configurations: result.rows,
        by_category: configsByCategory
      }
    });
  } catch (error) {
    console.error('Error fetching system configurations:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch system configurations',
      details: error.message
    });
  }
};

const notificationController = require('./notificationController');

// @desc    Toggle maintenance mode and notify all users
// @route   PUT /api/settings/system/maintenance
// @access  Admin
exports.toggleMaintenanceMode = async (req, res) => {
  try {
    const { maintenanceMode } = req.body;
    const adminId = req.user.userId;
    const isEnabled = maintenanceMode === 'true' || maintenanceMode === true;

    // Update or insert maintenance_mode config
    await db.query(`
      INSERT INTO system_configurations (config_key, config_value, category, config_type, description, is_public)
      VALUES ('maintenance_mode', $1, 'system', 'boolean', 'System Maintenance Mode', true)
      ON CONFLICT (config_key) 
      DO UPDATE SET config_value = EXCLUDED.config_value, updated_at = CURRENT_TIMESTAMP
    `, [isEnabled.toString()]);

    if (isEnabled) {
      // Fetch all users to notify them
      const usersResult = await db.query('SELECT id FROM users WHERE status = $1', ['active']);
      const message = 'The system is currently undergoing maintenance. Some features may be unavailable. We will be back online shortly.';
      
      // Send notification to all active users
      for (const user of usersResult.rows) {
        try {
          await notificationController.sendNotification(user.id, {
            type: 'system_alert',
            title: '🔧 System Maintenance Mode',
            message: message,
            priority: 'high'
          });
        } catch (e) {
          console.error('Failed to notify user:', user.id, e.message);
        }
      }
      
      console.log(`Notified ${usersResult.rows.length} users about maintenance mode.`);
    }

    res.status(200).json({ success: true, message: `Maintenance mode ${isEnabled ? 'enabled' : 'disabled'} successfully.` });
  } catch (error) {
    console.error('Error toggling maintenance mode:', error);
    res.status(500).json({ success: false, error: 'Failed to toggle maintenance mode', details: error.message });
  }
};

// @desc    Schedule maintenance
// @route   POST /api/settings/system/maintenance/schedule
// @access  Admin
exports.scheduleMaintenance = async (req, res) => {
  try {
    const { message, duration, date, time } = req.body;
    
    await db.query(`
      INSERT INTO system_configurations (config_key, config_value, category, config_type, description, is_public)
      VALUES ('maintenance_schedule', $1, 'system', 'json', 'Scheduled Maintenance', true)
      ON CONFLICT (config_key) 
      DO UPDATE SET config_value = EXCLUDED.config_value, updated_at = CURRENT_TIMESTAMP
    `, [JSON.stringify({ message, duration, date, time })]);

    res.status(200).json({ success: true, message: 'Maintenance scheduled successfully.' });
  } catch (error) {
    console.error('Error scheduling maintenance:', error);
    res.status(500).json({ success: false, error: 'Failed to schedule maintenance', details: error.message });
  }
};

// @desc    Update system configuration
// @route   PUT /api/settings/system/:id
// @access  Admin
exports.updateSystemConfiguration = async (req, res) => {
  try {
    const { id } = req.params;
    const { config_value, description, is_public } = req.body;
    const adminId = req.user.userId;

    const result = await db.query(`
      UPDATE system_configurations
      SET config_value = COALESCE($1, config_value),
          description = COALESCE($2, description),
          is_public = COALESCE($3, is_public),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $4
      RETURNING *
    `, [config_value, description, is_public, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Configuration not found'
      });
    }

    // Log the change
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, entity_id, new_values)
      VALUES ($1, 'UPDATE', 'system_configurations', $2, $3)
    `, [adminId, id, JSON.stringify({ config_value, description, is_public })]);

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Configuration updated successfully'
    });
  } catch (error) {
    console.error('Error updating system configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update configuration',
      details: error.message
    });
  }
};

// @desc    Create new system configuration
// @route   POST /api/settings/system
// @access  Admin
exports.createSystemConfiguration = async (req, res) => {
  try {
    const { config_key, config_value, description, category, config_type } = req.body;
    const adminId = req.user.userId;

    if (!config_key || !config_value) {
      return res.status(400).json({
        success: false,
        error: 'config_key and config_value are required'
      });
    }

    const result = await db.query(`
      INSERT INTO system_configurations (config_key, config_value, description, category, config_type, created_by)
      VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *
    `, [config_key, config_value, description, category, config_type, adminId]);

    // Log the creation
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, entity_id, new_values)
      VALUES ($1, 'CREATE', 'system_configurations', $2, $3)
    `, [adminId, result.rows[0].id, JSON.stringify(result.rows[0])]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Configuration created successfully'
    });
  } catch (error) {
    console.error('Error creating system configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create configuration',
      details: error.message
    });
  }
};

// @desc    Delete system configuration
// @route   DELETE /api/settings/system/:id
// @access  Admin
exports.deleteSystemConfiguration = async (req, res) => {
  try {
    const { id } = req.params;
    const adminId = req.user.userId;

    const existing = await db.query('SELECT * FROM system_configurations WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Configuration not found'
      });
    }

    await db.query('DELETE FROM system_configurations WHERE id = $1', [id]);

    // Log the deletion
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, entity_id, old_values)
      VALUES ($1, 'DELETE', 'system_configurations', $2, $3)
    `, [adminId, id, JSON.stringify(existing.rows[0])]);

    res.status(200).json({
      success: true,
      message: 'Configuration deleted successfully'
    });
  } catch (error) {
    console.error('Error deleting system configuration:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete configuration',
      details: error.message
    });
  }
};

// @desc    Get system performance metrics
// @route   GET /api/settings/performance
// @access  Admin
exports.getPerformanceMetrics = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        total_bookings,
        pending_bookings,
        recent_bookings,
        active_users,
        active_connections,
        db_size_formatted,
        uptime_seconds
      FROM system_performance_metrics
      LIMIT 1
    `);

    // If no metrics exist, create basic ones
    if (result.rows.length === 0) {
      // Get basic metrics from actual tables
      const basicMetrics = await db.query(`
        SELECT 
          (SELECT COUNT(*) FROM bookings) as total_bookings,
          (SELECT COUNT(*) FROM bookings WHERE status = 'pending') as pending_bookings,
          (SELECT COUNT(*) FROM bookings WHERE created_at >= NOW() - INTERVAL '24 hours') as recent_bookings,
          (SELECT COUNT(*) FROM users WHERE status = 'active') as active_users,
          (SELECT COUNT(*) FROM pg_stat_activity WHERE datname = current_database()) as active_connections,
          (SELECT pg_size_pretty(pg_database_size(current_database()))) as db_size_formatted
      `);

      return res.status(200).json({
        success: true,
        data: {
          metrics: basicMetrics.rows[0],
          source: 'calculated'
        }
      });
    }

    res.status(200).json({
      success: true,
      data: {
        metrics: result.rows[0],
        source: 'stored'
      }
    });
  } catch (error) {
    console.error('Error fetching performance metrics:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch performance metrics',
      details: error.message
    });
  }
};

// @desc    Get web traffic logs
// @route   GET /api/settings/traffic
// @access  Admin
exports.getWebTrafficLogs = async (req, res) => {
  try {
    const { limit = 100, offset = 0, timeframe = '24h' } = req.query;
    
    let timeCondition = "created_at >= NOW() - INTERVAL '24 hours'";
    if (timeframe === '7d') timeCondition = "created_at >= NOW() - INTERVAL '7 days'";
    if (timeframe === '30d') timeCondition = "created_at >= NOW() - INTERVAL '30 days'";

    const result = await db.query(`
      SELECT 
        id, session_id, user_id, event_type, path_visited,
        ip_address, device_type, created_at
      FROM web_traffic_logs
      WHERE ${timeCondition}
      ORDER BY created_at DESC
      LIMIT $1 OFFSET $2
    `, [parseInt(limit), parseInt(offset)]);

    // Get summary statistics
    const statsResult = await db.query(`
      SELECT 
        COUNT(*) as total_events,
        COUNT(DISTINCT session_id) as unique_sessions,
        COUNT(DISTINCT ip_address) as unique_visitors,
        COUNT(DISTINCT user_id) as logged_in_users
      FROM web_traffic_logs
      WHERE ${timeCondition}
    `);

    res.status(200).json({
      success: true,
      data: {
        logs: result.rows,
        statistics: statsResult.rows[0],
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset),
          timeframe
        }
      }
    });
  } catch (error) {
    console.error('Error fetching web traffic logs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch web traffic logs',
      details: error.message
    });
  }
};

// @desc    Get audit logs
// @route   GET /api/settings/audit
// @access  Admin
exports.getAuditLogs = async (req, res) => {
  try {
    const { limit = 100, offset = 0, user_id, action, entity_type } = req.query;
    
    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    if (user_id) {
      whereConditions.push(`al.user_id = $${paramIndex}`);
      params.push(user_id);
      paramIndex++;
    }

    if (action) {
      whereConditions.push(`al.action = $${paramIndex}`);
      params.push(action);
      paramIndex++;
    }

    if (entity_type) {
      whereConditions.push(`al.entity_type = $${paramIndex}`);
      params.push(entity_type);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(`
      SELECT 
        al.id, al.user_id, al.action, al.entity_type, al.entity_id,
        al.old_values, al.new_values, al.ip_address, al.created_at,
        u.email as user_email
      FROM audit_logs al
      LEFT JOIN users u ON al.user_id = u.id
      ${whereClause}
      ORDER BY al.created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `, params);

    res.status(200).json({
      success: true,
      data: {
        logs: result.rows,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        },
        filters: { user_id, action, entity_type }
      }
    });
  } catch (error) {
    console.error('Error fetching audit logs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch audit logs',
      details: error.message
    });
  }
};

// @desc    Get system app logs
// @route   GET /api/settings/system/logs
// @access  Admin
exports.getSystemLogs = async (req, res) => {
  try {
    const { limit = 100, offset = 0, level, category } = req.query;
    
    let whereConditions = [];
    let params = [];
    let paramIndex = 1;

    if (level) {
      whereConditions.push(`level = $${paramIndex}::log_level_enum`);
      params.push(level);
      paramIndex++;
    }

    if (category) {
      whereConditions.push(`category = $${paramIndex}`);
      params.push(category);
      paramIndex++;
    }

    const whereClause = whereConditions.length > 0 ? `WHERE ${whereConditions.join(' AND ')}` : '';

    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(`
      SELECT id, level, category, message, user_id, created_at
      FROM system_app_logs
      ${whereClause}
      ORDER BY created_at DESC
      LIMIT $${paramIndex} OFFSET $${paramIndex + 1}
    `, params);

    // Get log level counts
    const statsResult = await db.query(`
      SELECT 
        level,
        COUNT(*) as count
      FROM system_app_logs
      WHERE created_at >= NOW() - INTERVAL '24 hours'
      GROUP BY level
      ORDER BY count DESC
    `);

    res.status(200).json({
      success: true,
      data: {
        logs: result.rows,
        statistics: statsResult.rows,
        pagination: {
          limit: parseInt(limit),
          offset: parseInt(offset)
        },
        filters: { level, category }
      }
    });
  } catch (error) {
    console.error('Error fetching system logs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch system logs',
      details: error.message
    });
  }
};

// @desc    Create system app log
// @route   POST /api/settings/system/logs
// @access  Admin
exports.createSystemLog = async (req, res) => {
  try {
    const { level, category, message } = req.body;
    const userId = req.user.userId;

    const result = await db.query(`
      INSERT INTO system_app_logs (level, category, message, user_id)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `, [level || 'INFO', category || 'SYSTEM', message, userId]);

    res.status(201).json({
      success: true,
      data: result.rows[0]
    });
  } catch (error) {
    console.error('Error creating system log:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create system log',
      details: error.message
    });
  }
};

// @desc    Clear all system app logs
// @route   DELETE /api/settings/system/logs
// @access  Admin
exports.clearSystemLogs = async (req, res) => {
  try {
    const adminId = req.user.userId;

    await db.query('TRUNCATE TABLE system_app_logs');

    // Log the action in audit logs
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, new_values)
      VALUES ($1, 'CLEAR', 'system_logs', '{"status": "cleared"}')
    `, [adminId]);

    res.status(200).json({
      success: true,
      message: 'System logs cleared successfully'
    });
  } catch (error) {
    console.error('Error clearing system logs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to clear system logs',
      details: error.message
    });
  }
};

module.exports = exports;