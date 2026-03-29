const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const tenantAuth = require('../../../middleware/tenantAuth');

// GET all complaints
router.get('/', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  db.query(
    `SELECT * FROM complaints WHERE tenant_id = ? ORDER BY created_at DESC`,
    [tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });
      const active = rows.filter(r => r.status !== 'resolved');
      const resolved = rows.filter(r => r.status === 'resolved');
      return res.status(200).json({
        success: true,
        data: {
          summary: { total: rows.length, active: active.length, resolved: resolved.length },
          active,
          resolved,
        },
      });
    }
  );
});

// POST create complaint
router.post('/', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  const { title, description, category, priority, image_url } = req.body;
  if (!title || !description) return res.status(400).json({ success: false, message: 'title and description required' });
  db.query(
    `INSERT INTO complaints (tenant_id, title, description, category, priority, image_url, status) VALUES (?, ?, ?, ?, ?, ?, 'open')`,
    [tenantId, title, description, category || 'General', priority || 'low', image_url || null],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });
      return res.status(201).json({ success: true, message: 'Complaint raised!', data: { complaint_id: result.insertId } });
    }
  );
});

// GET single complaint
router.get('/:id', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  const { id } = req.params;
  db.query(
    'SELECT * FROM complaints WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Complaint not found' });
      return res.status(200).json({ success: true, data: rows[0] });
    }
  );
});

// PUT update complaint (only if open)
router.put('/:id', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  const { id } = req.params;
  const { title, description, category, priority } = req.body;
  db.query(
    'SELECT * FROM complaints WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });
      if (rows[0].status !== 'open') return res.status(400).json({ success: false, message: 'Cannot edit — already being processed' });
      db.query(
        `UPDATE complaints SET title = ?, description = ?, category = ?, priority = ? WHERE id = ? AND tenant_id = ?`,
        [title || rows[0].title, description || rows[0].description, category || rows[0].category, priority || rows[0].priority, id, tenantId],
        (err) => {
          if (err) return res.status(500).json({ success: false, message: 'Server error' });
          return res.status(200).json({ success: true, message: 'Complaint updated' });
        }
      );
    }
  );
});

// DELETE complaint (only if open)
router.delete('/:id', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  const { id } = req.params;
  db.query(
    'SELECT * FROM complaints WHERE id = ? AND tenant_id = ?',
    [id, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Not found' });
      if (rows[0].status !== 'open') return res.status(400).json({ success: false, message: 'Cannot delete — already being processed' });
      db.query('DELETE FROM complaints WHERE id = ?', [id], (err) => {
        if (err) return res.status(500).json({ success: false, message: 'Server error' });
        return res.status(200).json({ success: true, message: 'Deleted' });
      });
    }
  );
});

module.exports = router;