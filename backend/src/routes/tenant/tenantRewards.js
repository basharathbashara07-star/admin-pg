const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const authenticateTenant = require('../../../middleware/tenantAuth');

// Helper — add points (called internally)
const addPoints = (tenantId, points, reason) => {
  db.query('UPDATE tenants SET reward_points = reward_points + ? WHERE id = ?', [points, tenantId]);
  db.query(
    'INSERT INTO reward_history (tenant_id, points, reason, type) VALUES (?, ?, ?, "earned")',
    [tenantId, points, reason]
  );
};

// GET /api/tenant/rewards
router.get('/', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;

  db.query('SELECT reward_points FROM tenants WHERE id = ?', [tenantId], (err, tenantRows) => {
    if (err) return res.status(500).json({ success: false, message: 'DB error' });

    const totalPoints = tenantRows[0]?.reward_points || 0;

    db.query(
      `SELECT * FROM reward_history WHERE tenant_id = ? ORDER BY created_at DESC LIMIT 20`,
      [tenantId],
      (err, history) => {
        if (err) return res.status(500).json({ success: false, message: 'DB error' });

        const earned = history.filter(r => r.type === 'earned').reduce((s, r) => s + r.points, 0);
        const redeemed = history.filter(r => r.type === 'redeemed').reduce((s, r) => s + r.points, 0);

        db.query(
          'SELECT status, payment_date, due_date FROM payments WHERE tenant_id = ? ORDER BY created_at DESC',
          [tenantId],
          (err, payments) => {
            if (err) return res.status(500).json({ success: false, message: 'DB error' });

            const totalPaid = payments.filter(p => p.status === 'paid').length;
            const onTimePaid = payments.filter(p => {
              if (p.status !== 'paid' || !p.payment_date || !p.due_date) return false;
              return new Date(p.payment_date) <= new Date(p.due_date);
            }).length;

            const badges = [
              {
                name: 'On-Time Payer',
                icon: '⭐',
                description: 'Paid rent on time 3 months in a row',
                earned: onTimePaid >= 3,
              },
              {
                name: 'Super Tenant',
                icon: '🏆',
                description: 'Paid rent on time 6 months in a row',
                earned: onTimePaid >= 6,
              },
              {
                name: 'Early Bird',
                icon: '🌅',
                description: 'Paid rent 5 days before due date',
                earned: totalPaid >= 1,
              },
              {
                name: 'Loyal Tenant',
                icon: '✨',
                description: 'Paid rent for 3+ months total',
                earned: totalPaid >= 3,
              },
              {
                name: 'Community Star',
                icon: '🌟',
                description: 'Registered 3 visitors',
                earned: false,
              },
            ];

            return res.status(200).json({
              success: true,
              data: {
                total_points: totalPoints,
                earned,
                redeemed,
                history,
                badges,
              },
            });
          }
        );
      }
    );
  });
});

// POST /api/tenant/rewards/redeem
router.post('/redeem', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { points, reason } = req.body;

  if (!points || !reason) {
    return res.status(400).json({ success: false, message: 'points and reason are required.' });
  }

  db.query('SELECT reward_points FROM tenants WHERE id = ?', [tenantId], (err, rows) => {
    if (err) return res.status(500).json({ success: false, message: 'DB error' });

    const currentPoints = rows[0]?.reward_points || 0;

    if (currentPoints < points) {
      return res.status(400).json({ success: false, message: `Not enough points. You have ${currentPoints} pts.` });
    }

    db.query(
      'UPDATE tenants SET reward_points = reward_points - ? WHERE id = ?',
      [points, tenantId],
      (err) => {
        if (err) return res.status(500).json({ success: false, message: 'DB error' });

        db.query(
          'INSERT INTO reward_history (tenant_id, points, reason, type) VALUES (?, ?, ?, "redeemed")',
          [tenantId, points, reason],
          (err) => {
            if (err) return res.status(500).json({ success: false, message: 'DB error' });

            return res.status(200).json({
              success: true,
              message: `Redeemed ${points} points for ${reason}!`,
              data: { remaining_points: currentPoints - points },
            });
          }
        );
      }
    );
  });
});

module.exports = { router, addPoints };