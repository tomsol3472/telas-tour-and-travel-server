const db = require('../config/db');

// @desc    Get system health status
// @route   GET /api/maintenance/health
// @access  Admin
exports.getSystemHealth = async (req, res) => {
  try {
    const healthChecks = {};

    // Database connectivity check
    try {
      await db.query('SELECT 1');
      healthChecks.database = { status: 'healthy', message: 'Database connection successful' };
    } catch (dbError) {
      healthChecks.database = { status: 'unhealthy', message: dbError.message };
    }

    // Check critical tables
    try {
      const tableChecks = await Promise.all([
        db.query('SELECT COUNT(*) FROM users'),
        db.query('SELECT COUNT(*) FROM bookings'),
        db.query('SELECT COUNT(*) FROM payments'),
        db.query('SELECT COUNT(*) FROM notifications')
      ]);
      
      healthChecks.tables = {
        status: 'healthy',
        counts: {
          users: parseInt(tableChecks[0].rows[0].count),
          bookings: parseInt(tableChecks[1].rows[0].count),
          payments: parseInt(tableChecks[2].rows[0].count),
          notifications: parseInt(tableChecks[3].rows[0].count)
        }
      };
    } catch (tableError) {
      healthChecks.tables = { status: 'unhealthy', message: tableError.message };
    }

    // Check disk space and performance
    try {
      const performanceResult = await db.query(`
        SELECT 
          metric_name,
          metric_value,
          unit
        FROM system_performance_metrics
        WHERE recorded_at >= NOW() - INTERVAL '5 minutes'
        ORDER BY recorded_at DESC
        LIMIT 10
      `);
      
      healthChecks.performance = {
        status: 'healthy',
        recent_metrics: performanceResult.rows
      };
    } catch (perfError) {
      healthChecks.performance = { status: 'warning', message: 'Performance metrics unavailable' };
    }

    // Overall system status
    const overallStatus = Object.values(healthChecks).every(check => check.status === 'healthy') 
      ? 'healthy' 
      : Object.values(healthChecks).some(check => check.status === 'unhealthy')
      ? 'unhealthy'
      : 'warning';

    res.status(200).json({
      success: true,
      data: {
        overall_status: overallStatus,
        timestamp: new Date().toISOString(),
        checks: healthChecks
      }
    });
  } catch (error) {
    console.error('Error checking system health:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to check system health',
      details: error.message
    });
  }
};

// @desc    Get backup history
// @route   GET /api/maintenance/backups
// @access  Admin
exports.getBackupHistory = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        id, backup_type, file_name, file_size_bytes, 
        status, created_at, initiated_by
      FROM backup_history
      ORDER BY created_at DESC
      LIMIT 50
    `);

    // Calculate backup statistics
    const stats = await db.query(`
      SELECT 
        status,
        COUNT(*) as count,
        AVG(file_size_bytes) as avg_size_bytes
      FROM backup_history
      WHERE created_at >= NOW() - INTERVAL '30 days'
      GROUP BY status
    `);

    res.status(200).json({
      success: true,
      data: {
        backups: result.rows,
        statistics: stats.rows
      }
    });
  } catch (error) {
    console.error('Error fetching backup history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch backup history',
      details: error.message
    });
  }
};

// @desc    Trigger database backup
// @route   POST /api/maintenance/backup
// @access  Admin
exports.triggerBackup = async (req, res) => {
  try {
    const { backup_type = 'manual' } = req.body;
    const adminId = req.user.userId;

    // Insert backup record
    const backupResult = await db.query(`
      INSERT INTO backup_history (backup_type, status, initiated_by)
      VALUES ($1, 'in_progress', $2)
      RETURNING id
    `, [backup_type, adminId]);

    const backupId = backupResult.rows[0].id;

    const { exec } = require('child_process');
    const path = require('path');
    const fs = require('fs');

    const backupDir = path.join(__dirname, '../backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir);
    }

    const fileName = `telas_${backup_type}_${Date.now()}.sql`;
    const filePath = path.join(backupDir, fileName);

    const dbUser = process.env.DB_USER || 'postgres';
    const dbPass = process.env.DB_PASS || 'postgres';
    const dbHost = process.env.DB_HOST || 'localhost';
    const dbPort = process.env.DB_PORT || 5432;
    const dbName = process.env.DB_NAME || 'TelasUpdateDB';

    const env = { ...process.env, PGPASSWORD: dbPass };
    const command = `pg_dump -U ${dbUser} -h ${dbHost} -p ${dbPort} -F c -f "${filePath}" ${dbName}`;

    exec(command, { env }, async (error, stdout, stderr) => {
      if (error) {
        console.error('Backup failed:', error);
        await db.query(`
          UPDATE backup_history
          SET status = 'failed'
          WHERE id = $1
        `, [backupId]);
        return;
      }
      
      try {
        const stats = fs.statSync(filePath);
        await db.query(`
          UPDATE backup_history
          SET status = 'completed',
              file_name = $1,
              file_size_bytes = $2
          WHERE id = $3
        `, [fileName, stats.size, backupId]);

        // Log the backup
        await db.query(`
          INSERT INTO audit_logs (user_id, action, entity_type, entity_id, new_values)
          VALUES ($1, 'BACKUP', 'backup_history', $2, '{"status": "completed"}')
        `, [adminId, backupId]);

      } catch (updateError) {
        console.error('Error updating backup status:', updateError);
        await db.query(`
          UPDATE backup_history
          SET status = 'failed'
          WHERE id = $1
        `, [backupId]);
      }
    });

    res.status(202).json({
      success: true,
      data: {
        backup_id: backupId,
        status: 'in_progress'
      },
      message: 'Backup initiated successfully'
    });
  } catch (error) {
    console.error('Error triggering backup:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to trigger backup',
      details: error.message
    });
  }
};

// @desc    Clean up old logs
// @route   POST /api/maintenance/cleanup
// @access  Admin
exports.cleanupLogs = async (req, res) => {
  try {
    const { days_to_keep = 30, log_types = ['system_app_logs', 'web_traffic_logs'] } = req.body;
    const adminId = req.user.userId;

    const results = {};

    // Map table names to their timestamp columns
    const tableTimestampMap = {
      'system_app_logs': 'timestamp',
      'web_traffic_logs': 'timestamp',
      'audit_logs': 'created_at'
    };

    for (const logType of log_types) {
      const timestampCol = tableTimestampMap[logType] || 'created_at';
      try {
        const deleteResult = await db.query(`
          DELETE FROM ${logType}
          WHERE ${timestampCol} < NOW() - INTERVAL '${parseInt(days_to_keep)} days'
        `);
        results[logType] = {
          status: 'success',
          deleted_count: deleteResult.rowCount
        };
      } catch (tableError) {
        results[logType] = {
          status: 'error',
          message: tableError.message
        };
      }
    }

    // Log the cleanup action
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, new_values)
      VALUES ($1, 'CLEANUP', 'maintenance', $2)
    `, [adminId, JSON.stringify({ days_to_keep, results })]);

    res.status(200).json({
      success: true,
      data: {
        cleanup_results: results,
        days_kept: days_to_keep
      },
      message: 'Log cleanup completed'
    });
  } catch (error) {
    console.error('Error cleaning up logs:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to cleanup logs',
      details: error.message
    });
  }
};

// @desc    Get database statistics
// @route   GET /api/maintenance/database/stats
// @access  Admin
exports.getDatabaseStats = async (req, res) => {
  try {
    // Get database size
    const dbSize = await db.query(`
      SELECT pg_size_pretty(pg_database_size(current_database())) as database_size
    `);

    // Get table row counts and sizes
    const tableStats = await db.query(`
      SELECT 
        relname as table_name,
        n_live_tup as row_count,
        pg_size_pretty(pg_total_relation_size(relid)) as total_size
      FROM pg_stat_user_tables
      WHERE schemaname = 'public'
      ORDER BY n_live_tup DESC
    `);

    // Get active connections
    const connections = await db.query(`
      SELECT 
        COUNT(*) as total_connections,
        COUNT(CASE WHEN state = 'active' THEN 1 END) as active_connections,
        COUNT(CASE WHEN state = 'idle' THEN 1 END) as idle_connections
      FROM pg_stat_activity
      WHERE datname = current_database()
    `);

    // Get cache hit ratio
    const cacheStats = await db.query(`
      SELECT 
        ROUND(
          100.0 * sum(heap_blks_hit) / NULLIF(sum(heap_blks_hit) + sum(heap_blks_read), 0),
          2
        ) as cache_hit_ratio
      FROM pg_statio_user_tables
    `);

    res.status(200).json({
      success: true,
      data: {
        database_size: dbSize.rows[0].database_size,
        connections: connections.rows[0],
        cache_hit_ratio: cacheStats.rows[0]?.cache_hit_ratio || 0,
        table_statistics: tableStats.rows
      }
    });
  } catch (error) {
    console.error('Error fetching database stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch database statistics',
      details: error.message
    });
  }
};

// @desc    Optimize database
// @route   POST /api/maintenance/database/optimize
// @access  Admin
exports.optimizeDatabase = async (req, res) => {
  try {
    const adminId = req.user.userId;
    const results = {};

    // Run VACUUM ANALYZE on major tables
    const majorTables = ['users', 'bookings', 'payments', 'notifications', 'system_app_logs'];
    
    for (const table of majorTables) {
      try {
        await db.query(`VACUUM ANALYZE ${table}`);
        results[table] = { status: 'optimized' };
      } catch (tableError) {
        results[table] = { status: 'error', message: tableError.message };
      }
    }

    // Log the optimization
    await db.query(`
      INSERT INTO audit_logs (user_id, action, entity_type, new_values)
      VALUES ($1, 'OPTIMIZE', 'database', $2)
    `, [adminId, JSON.stringify(results)]);

    res.status(200).json({
      success: true,
      data: {
        optimization_results: results
      },
      message: 'Database optimization completed'
    });
  } catch (error) {
    console.error('Error optimizing database:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to optimize database',
      details: error.message
    });
  }
};

// @desc    Get system alerts
// @route   GET /api/maintenance/alerts
// @access  Admin
exports.getSystemAlerts = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT 
        ea.id, ea.booking_id, ea.alert_time, ea.status,
        ea.resolution_notes,
        b.booking_code,
        u.email as triggered_by_email
      FROM emergency_alerts ea
      LEFT JOIN bookings b ON ea.booking_id = b.id
      LEFT JOIN users u ON ea.triggered_by = u.id
      ORDER BY ea.alert_time DESC
      LIMIT 50
    `);

    // Count alerts by status
    const statusCounts = await db.query(`
      SELECT 
        status,
        COUNT(*) as count
      FROM emergency_alerts
      GROUP BY status
    `);

    res.status(200).json({
      success: true,
      data: {
        alerts: result.rows,
        status_counts: statusCounts.rows
      }
    });
  } catch (error) {
    console.error('Error fetching system alerts:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch system alerts',
      details: error.message
    });
  }
};

// @desc    Create system alert
// @route   POST /api/maintenance/alerts
// @access  Admin
exports.createSystemAlert = async (req, res) => {
  try {
    const { booking_id, resolution_notes } = req.body;
    const adminId = req.user.userId;

    const result = await db.query(`
      INSERT INTO emergency_alerts (booking_id, triggered_by, status)
      VALUES ($1, $2, 'active')
      RETURNING *
    `, [booking_id || null, adminId]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'System alert created successfully'
    });
  } catch (error) {
    console.error('Error creating system alert:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create system alert',
      details: error.message
    });
  }
};

// @desc    Resolve system alert
// @route   PUT /api/maintenance/alerts/:id/resolve
// @access  Admin
exports.resolveSystemAlert = async (req, res) => {
  try {
    const { id } = req.params;
    const { resolution_notes } = req.body;
    const adminId = req.user.userId;

    const result = await db.query(`
      UPDATE emergency_alerts
      SET status = 'resolved', resolved_by = $1, resolution_notes = $2
      WHERE id = $3
      RETURNING *
    `, [adminId, resolution_notes || null, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Alert not found'
      });
    }

    res.status(200).json({
      success: true,
      data: result.rows[0],
      message: 'Alert resolved successfully'
    });
  } catch (error) {
    console.error('Error resolving system alert:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to resolve alert',
      details: error.message
    });
  }
};

module.exports = exports;