// backend/src/routes/admin/adminRewards.js

const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const authenticateAdmin = require('../../../middleware/auth');

// GET /api/admin/rewards/leaderboard
router.get('/leaderboard', authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT t.id, t.name, t.reward_points, r.room_no,
      (SELECT COUNT(*) FROM reward_history rh WHERE rh.tenant_id = t.id AND rh.type = 'earned') as total_earned_count,
      (SELECT COUNT(*) FROM reward_history rh WHERE rh.tenant_id = t.id AND rh.type = 'redeemed') as total_redeemed_count
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    WHERE t.pg_id = ? AND t.status = 'active'
    ORDER BY t.reward_points DESC
  `;

  db.query(query, [pgId], (err, rows) => {
    if (err) {
      console.error('leaderboard error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    return res.json({ success: true, leaderboard: rows });
  });
});

// GET /api/admin/rewards/history/:tenantId
router.get('/history/:tenantId', authenticateAdmin, (req, res) => {
  const tenantId = req.params.tenantId;

  const query = `
    SELECT id, points, reason, type, created_at
    FROM reward_history
    WHERE tenant_id = ?
    ORDER BY created_at DESC
    LIMIT 30
  `;

  db.query(query, [tenantId], (err, rows) => {
    if (err) {
      console.error('history error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    return res.json({ success: true, history: rows });
  });
});

// POST /api/admin/rewards/adjust  → manually add or deduct points
router.post('/adjust', authenticateAdmin, (req, res) => {
  const { tenant_id, points, reason } = req.body;
  // points can be negative for deduction

  const type = points >= 0 ? 'earned' : 'redeemed';
  const absPoints = Math.abs(points);

  const updateQuery = `UPDATE tenants SET reward_points = GREATEST(0, reward_points + ?) WHERE id = ?`;
  db.query(updateQuery, [points, tenant_id], (err) => {
    if (err) {
      console.error('adjust points error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }

    const historyQuery = `INSERT INTO reward_history (tenant_id, points, reason, type) VALUES (?, ?, ?, ?)`;
    db.query(historyQuery, [tenant_id, absPoints, reason || 'Manual adjustment by admin', type], (err) => {
      if (err) console.error('adjust history error:', err);
    });

    return res.json({ success: true, message: 'Points adjusted successfully' });
  });
});

module.exports = router;