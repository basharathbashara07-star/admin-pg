const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const crypto = require('crypto');
const authenticateTenant = require('../../../middleware/tenantAuth');

// GET /api/tenant/visitors
router.get('/', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;

  db.query(
    `SELECT * FROM visitors WHERE tenant_id = ? ORDER BY created_at DESC`,
    [tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      return res.status(200).json({ success: true, data: rows });
    }
  );
});

// POST /api/tenant/visitors
router.post('/', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;
  const { name, phone, purpose, visit_date } = req.body;

  if (!name || !visit_date) {
    return res.status(400).json({ success: false, message: 'name and visit_date are required.' });
  }

  const qrCode = `VIS-${tenantId}-${Date.now()}-${crypto.randomBytes(4).toString('hex').toUpperCase()}`;

  db.query(
    `INSERT INTO visitors (tenant_id, pg_id, name, phone, purpose, visit_date, status, qr_code)
     VALUES (?, ?, ?, ?, ?, ?, 'pending', ?)`,
    [tenantId, pgId, name, phone || null, purpose || null, visit_date, qrCode],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      return res.status(201).json({
        success: true,
        message: 'Visitor registered! Awaiting warden approval.',
        data: {
          id: result.insertId,
          name, phone, purpose, visit_date,
          status: 'pending',
          qr_code: qrCode,
        },
      });
    }
  );
});

// DELETE /api/tenant/visitors/:id
router.delete('/:id', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { id } = req.params;

  db.query(
    'SELECT * FROM visitors WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      if (rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Visitor not found.' });
      }

      if (rows[0].status !== 'pending') {
        return res.status(400).json({ success: false, message: 'Cannot cancel — visitor already processed.' });
      }

      db.query('DELETE FROM visitors WHERE id = ?', [id], (err) => {
        if (err) return res.status(500).json({ success: false, message: 'DB error' });
        return res.status(200).json({ success: true, message: 'Visitor cancelled.' });
      });
    }
  );
});

module.exports = router;