// backend/src/controllers/tenant/emergencyController.js

const db = require('../../config/db');

// POST /api/tenantFrontend/emergency/sos
const triggerSOS = (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;
  const message = req.body.message || 'SOS Alert triggered!';

  // Check if already active
  const checkQuery = `SELECT id FROM sos_alerts WHERE tenant_id = ? AND status = 'active' LIMIT 1`;

  db.query(checkQuery, [tenantId], (err, existing) => {
    if (err) {
      console.error('triggerSOS check error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    if (existing.length > 0) {
      return res.json({ success: true, message: 'SOS already active', alertId: existing[0].id });
    }

    const insertQuery = `INSERT INTO sos_alerts (tenant_id, pg_id, message, status) VALUES (?, ?, ?, 'active')`;

    db.query(insertQuery, [tenantId, pgId, message], (err, result) => {
      if (err) {
        console.error('triggerSOS insert error:', err);
        return res.status(500).json({ success: false, message: 'Failed to send SOS' });
      }

      return res.json({ success: true, message: 'SOS alert sent!', alertId: result.insertId });
    });
  });
};

// POST /api/tenantFrontend/emergency/cancel
const cancelSOS = (req, res) => {
  const tenantId = req.tenant.id;

  const query = `UPDATE sos_alerts SET status = 'resolved' WHERE tenant_id = ? AND status = 'active'`;

  db.query(query, [tenantId], (err) => {
    if (err) {
      console.error('cancelSOS error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    return res.json({ success: true, message: 'Alert cancelled' });
  });
};

// GET /api/admin/emergency/alerts
const getAlerts = (req, res) => {
  const adminPgId = req.admin.pg_id;

  const query = `
    SELECT
      sa.id,
      sa.message,
      sa.status,
      sa.created_at,
      t.name AS tenant_name,
      r.room_no AS room_number
    FROM sos_alerts sa
    JOIN tenants t ON sa.tenant_id = t.id
    LEFT JOIN rooms r ON t.room_id = r.id
    WHERE sa.pg_id = ?
    ORDER BY
      CASE WHEN sa.status = 'active' THEN 0 ELSE 1 END,
      sa.created_at DESC
    LIMIT 50
  `;

  db.query(query, [adminPgId], (err, rows) => {
    if (err) {
      console.error('getAlerts error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    return res.json({ success: true, alerts: rows });
  });
};

// POST /api/admin/emergency/resolve/:alertId
const resolveAlert = (req, res) => {
  const alertId = req.params.alertId;
  const adminPgId = req.admin.pg_id;

  const query = `
    UPDATE sos_alerts
    SET status = 'resolved'
    WHERE id = ? AND pg_id = ? AND status = 'active'
  `;

  db.query(query, [alertId, adminPgId], (err, result) => {
    if (err) {
      console.error('resolveAlert error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Alert not found or already resolved' });
    }

    return res.json({ success: true, message: 'Alert resolved' });
  });
};

module.exports = { triggerSOS, cancelSOS, getAlerts, resolveAlert };