const express = require('express');
const router = express.Router();
const db = require('../../config/db');
const authenticateTenant = require('../../../middleware/tenantAuth');

// GET /api/tenant/expenses/roommates
router.get('/roommates', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const roomId = req.tenant.room_id;

  if (!roomId) {
    return res.status(400).json({ success: false, message: 'You are not assigned to a room yet.' });
  }

  db.query(
    `SELECT id, name, email FROM tenants WHERE room_id = ? AND id != ?`,
    [roomId, tenantId],
    (err, roommates) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      db.query(
        `SELECT r.room_no, p.pg_name FROM rooms r JOIN pgs p ON p.id = r.pg_id WHERE r.id = ?`,
        [roomId],
        (err, roomInfo) => {
          if (err) return res.status(500).json({ success: false, message: 'DB error' });

          return res.status(200).json({
            success: true,
            data: {
              room: roomInfo[0] || {},
              roommates,
              total_in_room: roommates.length + 1
            },
          });
        }
      );
    }
  );
});

// GET /api/tenant/expenses
router.get('/', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const roomId = req.tenant.room_id;

  if (!roomId) {
    return res.status(200).json({
      success: true,
      data: { pending: [], settled: [], summary: { my_pending: 0, my_paid: 0 } }
    });
  }

  db.query(
    `SELECT e.id, e.title, e.total_amount, e.expense_date, e.status AS expense_status, 
            e.created_by, t.name AS created_by_name
     FROM expenses e JOIN tenants t ON t.id = e.created_by
     WHERE e.room_id = ? ORDER BY e.expense_date DESC`,
    [roomId],
    (err, expenses) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      if (expenses.length === 0) {
        return res.status(200).json({
          success: true,
          data: { pending: [], settled: [], summary: { my_pending: 0, my_paid: 0 } }
        });
      }

      let completed = 0;
      const result = [];

      expenses.forEach((exp) => {
        db.query(
          `SELECT es.id, es.tenant_id, es.amount, es.status, es.paid_at, t.name AS tenant_name
           FROM expense_splits es JOIN tenants t ON t.id = es.tenant_id 
           WHERE es.expense_id = ?`,
          [exp.id],
          (err, splits) => {
            if (err) splits = [];

            const mySplit = splits.find(s => s.tenant_id === tenantId);
            result.push({
              ...exp,
              splits,
              my_share: mySplit?.amount || 0,
              my_status: mySplit?.status || 'pending',
              my_split_id: mySplit?.id,
            });

            completed++;
            if (completed === expenses.length) {
              const myExpenses = result.filter(e => e.my_split_id);
              const pending = myExpenses.filter(e => e.my_status === 'pending');
              const settled = myExpenses.filter(e => e.my_status === 'paid');

              return res.status(200).json({
                success: true,
                data: {
                  summary: {
                    my_pending: pending.reduce((s, e) => s + parseFloat(e.my_share), 0).toFixed(2),
                    my_paid: settled.reduce((s, e) => s + parseFloat(e.my_share), 0).toFixed(2),
                  },
                  pending,
                  settled,
                },
              });
            }
          }
        );
      });
    }
  );
});

// POST /api/tenant/expenses
router.post('/', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const roomId = req.tenant.room_id;
  const { title, total_amount, expense_date, selected_ids } = req.body;

  if (!title || !total_amount || !expense_date) {
    return res.status(400).json({ success: false, message: 'title, total_amount, and expense_date are required.' });
  }

  if (!roomId) {
    return res.status(400).json({ success: false, message: 'You are not assigned to a room yet.' });
  }

  const getSplitIds = (callback) => {
    if (selected_ids && selected_ids.length > 0) {
      const splitIds = [...new Set([tenantId, ...selected_ids.map(Number)])];
      callback(splitIds);
    } else {
      db.query('SELECT id FROM tenants WHERE room_id = ?', [roomId], (err, everyone) => {
        if (err) return res.status(500).json({ success: false, message: 'DB error' });
        callback(everyone.map(r => r.id));
      });
    }
  };

  getSplitIds((splitIds) => {
    if (splitIds.length === 0) {
      return res.status(400).json({ success: false, message: 'No people selected.' });
    }

    const perPerson = (parseFloat(total_amount) / splitIds.length).toFixed(2);
    const placeholders = splitIds.map(() => '?').join(',');

    db.query(
      `SELECT id, name FROM tenants WHERE id IN (${placeholders})`,
      splitIds,
      (err, people) => {
        if (err) return res.status(500).json({ success: false, message: 'DB error' });

        db.query(
          `INSERT INTO expenses (title, total_amount, created_by, room_id, expense_date, status) 
           VALUES (?, ?, ?, ?, ?, 'pending')`,
          [title, total_amount, tenantId, roomId, expense_date],
          (err, expResult) => {
            if (err) {
                console.log('EXPENSE ERROR:', err.message);
                return res.status(500).json({ success: false, message: 'DB error' });
            }

            const expenseId = expResult.insertId;
            const splitValues = splitIds.map(id => [expenseId, id, perPerson, 'pending']);

            db.query(
              'INSERT INTO expense_splits (expense_id, tenant_id, amount, status) VALUES ?',
              [splitValues],
              (err) => {
                if (err) {
                    console.log('SPLITS ERROR:', err.message);
                    return res.status(500).json({ success: false, message: 'DB error' });
                }
                return res.status(201).json({
                  success: true,
                  message: `Split Rs.${perPerson} each among ${splitIds.length} people.`,
                  data: {
                    expense_id: expenseId,
                    title, total_amount,
                    split_count: splitIds.length,
                    per_person: perPerson,
                    people: people.map(r => r.name),
                  },
                });
              }
            );
          }
        );
      }
    );
  });
});

// POST /api/tenant/expenses/pay/:expenseId
router.post('/pay/:expenseId', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { expenseId } = req.params;

  db.query(
    `SELECT es.*, e.title FROM expense_splits es 
     JOIN expenses e ON e.id = es.expense_id 
     WHERE es.expense_id = ? AND es.tenant_id = ?`,
    [expenseId, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Expense not found.' });
      if (rows[0].status === 'paid') return res.status(400).json({ success: false, message: 'Already paid.' });

      db.query(
        `UPDATE expense_splits SET status = 'paid', paid_at = NOW() 
         WHERE expense_id = ? AND tenant_id = ?`,
        [expenseId, tenantId],
        (err) => {
          if (err) return res.status(500).json({ success: false, message: 'DB error' });

          db.query(
            'SELECT status FROM expense_splits WHERE expense_id = ?',
            [expenseId],
            (err, allSplits) => {
              if (err) return res.status(500).json({ success: false, message: 'DB error' });

              const allPaid = allSplits.every(s => s.status === 'paid');
              if (allPaid) {
                db.query("UPDATE expenses SET status = 'settled' WHERE id = ?", [expenseId]);
              }

              return res.status(200).json({
                success: true,
                message: `Paid Rs.${rows[0].amount} for "${rows[0].title}"!`,
                data: { expense_fully_settled: allPaid, amount_paid: rows[0].amount }
              });
            }
          );
        }
      );
    }
  );
});

// DELETE /api/tenant/expenses/:expenseId
router.delete('/:expenseId', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const { expenseId } = req.params;

  db.query(
    'SELECT * FROM expenses WHERE id = ? AND created_by = ?',
    [expenseId, tenantId],
    (err, rows) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });
      if (rows.length === 0) return res.status(404).json({ success: false, message: 'Not found or not your expense.' });

      db.query(
        "SELECT id FROM expense_splits WHERE expense_id = ? AND status = 'paid'",
        [expenseId],
        (err, paid) => {
          if (err) return res.status(500).json({ success: false, message: 'DB error' });
          if (paid.length > 0) return res.status(400).json({ success: false, message: 'Cannot delete — someone already paid.' });

          db.query('DELETE FROM expenses WHERE id = ?', [expenseId], (err) => {
            if (err) return res.status(500).json({ success: false, message: 'DB error' });
            return res.status(200).json({ success: true, message: 'Expense deleted.' });
          });
        }
      );
    }
  );
});

module.exports = router;