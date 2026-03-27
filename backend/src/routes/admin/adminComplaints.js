const express = require('express');
const router = express.Router();
const db = require('../../config/db');

// GET all complaints with tenant name and room
router.get('/', (req, res) => {
  const sql = `
    SELECT c.*, t.name AS tenant_name, r.room_no
    FROM complaints c
    LEFT JOIN tenants t ON c.tenant_id = t.id
    LEFT JOIN rooms r ON t.room_id = r.id
    ORDER BY c.created_at DESC
  `;
  db.query(sql, (err, results) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json(results);
  });
});

// PUT update complaint status
router.put('/:id', (req, res) => {
  
  const { status, admin_response, due_date } = req.body;

  const resolvedAt = status === 'resolved' ? new Date() : null;
  const sql = `UPDATE complaints SET status = ?, admin_response = ?, due_date = ?, resolved_at = ? WHERE id = ?`;
  db.query(sql, [status, admin_response || null, due_date || null, resolvedAt, req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Updated successfully' });
  });
});

//Delete Complaint Route
router.delete('/:id', (req, res) => {
  db.query('DELETE FROM complaints WHERE id = ?', [req.params.id], (err) => {
    if (err) return res.status(500).json({ error: err.message });
    res.json({ message: 'Deleted successfully' });
  });
});

module.exports = router;