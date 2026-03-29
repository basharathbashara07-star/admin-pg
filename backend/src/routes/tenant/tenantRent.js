const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const crypto = require('crypto');
const authenticateTenant = require('../../../middleware/tenantAuth');
const { addPoints } = require('./tenantRewards');

// GET /api/tenant/rent/current
router.get('/current', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const now = new Date();
  const monthName = now.toLocaleString('default', { month: 'long' });
  const year = now.getFullYear();
  const monthStr = `${monthName} ${year}`;

  db.query(
    `SELECT p.*, t.name, t.phone, r.room_no, pg.pg_name
     FROM payments p
     JOIN tenants t ON t.id = p.tenant_id
     LEFT JOIN rooms r ON r.id = t.room_id
     LEFT JOIN pgs pg ON pg.id = t.pg_id
     WHERE p.tenant_id = ? AND p.month = ?
     LIMIT 1`,
    [tenantId, monthStr],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'No rent record for this month' });
      return res.status(200).json({ success: true, data: rows[0] });
    }
  );
});

// GET /api/tenant/rent/history
router.get('/history', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;

  db.query(
    `SELECT p.id, p.amount, p.month, p.status,
            p.payment_date, p.payment_mode,
            p.created_at
     FROM payments p
     WHERE p.tenant_id = ?
     ORDER BY p.created_at DESC`,
    [tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      const paid = rows.filter(r => r.status === 'paid').length;
      const pending = rows.filter(r => r.status === 'pending').length;

      return res.status(200).json({
        success: true,
        data: {
          summary: { paid, pending, total: rows.length },
          history: rows,
        },
      });
    }
  );
});

// POST /api/tenant/rent/pay
router.post('/pay', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { payment_id, payment_method, transaction_id } = req.body;

  if (!payment_id || !payment_method) {
    return res.status(400).json({ success: false, message: 'payment_id & payment_method required' });
  }

  db.query(
    'SELECT * FROM payments WHERE id = ? AND tenant_id = ?',
    [payment_id, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Payment not found' });
      if (rows[0].status === 'paid') return res.status(400).json({ success: false, message: 'Already paid' });

      const receiptNumber = `RCP-${tenantId}-${Date.now()}`;
      const txnId = transaction_id || `TXN-${Date.now()}`;

      db.query(
        `UPDATE payments 
         SET status='paid',
             payment_date=CURDATE(),
             payment_mode=?,
             created_at=NOW()
         WHERE id=? AND tenant_id=?`,
        [payment_method, payment_id, tenantId],
        (err) => {
          if (err) return res.status(500).json({ success: false, message: 'DB error' });

          // Add reward points
          addPoints(tenantId, 10, 'Rent paid');

          return res.status(200).json({
            success: true,
            message: 'Rent paid successfully!',
            data: {
              receipt_number: receiptNumber,
              transaction_id: txnId,
              payment_method,
              paid_on: new Date().toISOString().split('T')[0],
            },
          });
        }
      );
    }
  );
});

// GET /api/tenant/rent/receipt/:paymentId
router.get('/receipt/:paymentId', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { paymentId } = req.params;

  db.query(
    `SELECT p.*, t.name, t.email, r.room_no, pg.pg_name, pg.address
     FROM payments p
     JOIN tenants t ON t.id = p.tenant_id
     LEFT JOIN rooms r ON r.id = t.room_id
     LEFT JOIN pgs pg ON pg.id = t.pg_id
     WHERE p.id = ? AND p.tenant_id = ? AND p.status='paid'`,
    [paymentId, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Receipt not found' });
      return res.status(200).json({ success: true, data: { receipt: rows[0] } });
    }
  );
});

// GET /api/tenant/rent/insights
router.get('/insights', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;

  db.query(
    `SELECT status FROM payments WHERE tenant_id = ?`,
    [tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      const total = rows.length;
      const paid = rows.filter(r => r.status === 'paid').length;
      const pending = rows.filter(r => r.status === 'pending').length;
      const score = total > 0 ? Math.round((paid / total) * 100) : 0;

      const insights = [];
      if (paid === total && total > 0) {
        insights.push('🌟 Perfect record! You have always paid rent on time!');
      } else {
        insights.push(`✅ You have paid ${paid} out of ${total} months.`);
      }
      if (pending > 0) insights.push(`⚠️ You have ${pending} pending payment(s).`);
      insights.push(`📊 Payment Score: ${score}/100 — ${score >= 80 ? 'Excellent' : score >= 50 ? 'Good' : 'Needs Improvement'}`);

      return res.status(200).json({
        success: true,
        data: { score, paid, pending, total, insights },
      });
    }
  );
});

module.exports = router;