// backend/src/routes/tenant/tenantRewards.js

const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const tenantAuth = require('../../../middleware/tenantAuth');

// GET /api/tenant/rewards
router.get('/', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;

  const pointsQuery = `SELECT reward_points FROM tenants WHERE id = ?`;
  db.query(pointsQuery, [tenantId], (err, tenantRows) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });
    if (tenantRows.length === 0) return res.status(404).json({ success: false, message: 'Tenant not found' });

    const totalPoints = tenantRows[0].reward_points || 0;

    const historyQuery = `
      SELECT points, reason, type, created_at
      FROM reward_history
      WHERE tenant_id = ?
      ORDER BY created_at DESC
      LIMIT 20
    `;
    db.query(historyQuery, [tenantId], (err, history) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });

      const earned = history.filter(h => h.type === 'earned').reduce((s, h) => s + h.points, 0);
      const redeemed = history.filter(h => h.type === 'redeemed').reduce((s, h) => s + h.points, 0);

      const badges = _getBadges(totalPoints, history);

      return res.json({
        success: true,
        data: {
          total_points: totalPoints,
          earned,
          redeemed,
          history,
          badges,
        }
      });
    });
  });
});

// POST /api/tenant/rewards/redeem
router.post('/redeem', tenantAuth, (req, res) => {
  const tenantId = req.tenant.id;
  const { points, reason } = req.body;

  const checkQuery = `SELECT reward_points FROM tenants WHERE id = ?`;
  db.query(checkQuery, [tenantId], (err, rows) => {
    if (err) return res.status(500).json({ success: false, message: 'Server error' });

    const current = rows[0].reward_points || 0;
    if (current < points) {
      return res.json({ success: false, message: 'Not enough points!' });
    }

    const updateQuery = `UPDATE tenants SET reward_points = reward_points - ? WHERE id = ?`;
    db.query(updateQuery, [points, tenantId], (err) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });

      const historyQuery = `INSERT INTO reward_history (tenant_id, points, reason, type) VALUES (?, ?, ?, 'redeemed')`;
      db.query(historyQuery, [tenantId, points, reason], (err) => {
        if (err) console.error('redeem history error:', err);
      });

      return res.json({ success: true, message: `${points} points redeemed successfully!` });
    });
  });
});

function _getBadges(totalPoints, history) {
  const onTimeCount = history.filter(h => h.reason && h.reason.includes('on time')).length;
  const earlyCount = history.filter(h => h.reason && h.reason.includes('early')).length;
  const bonusCount = history.filter(h => h.reason && h.reason.includes('consecutive')).length;

  return [
    {
      name: 'On-Time Payer',
      icon: '⏰',
      description: 'Pay rent on time',
      earned: onTimeCount >= 1,
    },
    {
      name: 'Early Bird',
      icon: '🐦',
      description: 'Pay 5+ days early',
      earned: earlyCount >= 1,
    },
    {
      name: 'Streak Master',
      icon: '🔥',
      description: '3 months on time',
      earned: bonusCount >= 1,
    },
    {
      name: 'Point Collector',
      icon: '⭐',
      description: 'Earn 50+ points',
      earned: totalPoints >= 50,
    },
    {
      name: 'Gold Tenant',
      icon: '🏆',
      description: 'Earn 100+ points',
      earned: totalPoints >= 100,
    },
    {
      name: 'Redeemer',
      icon: '🎁',
      description: 'Redeem points once',
      earned: history.some(h => h.type === 'redeemed'),
    },
  ];
}

module.exports = { router };