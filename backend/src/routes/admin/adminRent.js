const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");


// GET /api/admin/rent/summary
router.get("/summary", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  console.log('RENT SUMMARY - pgId:', pgId);

  const query = `
    SELECT
      COALESCE((
        SELECT SUM(p.amount) 
        FROM payments p
        JOIN tenants t ON p.tenant_id = t.id
        WHERE t.pg_id = ? 
        AND p.status = 'paid'
        AND YEAR(p.payment_date) = YEAR(CURDATE())
        AND MONTH(p.payment_date) = MONTH(CURDATE())
      ), 0) AS collected,
      COALESCE((
        SELECT SUM(t.rent_amount)
        FROM tenants t
        WHERE t.pg_id = ? AND t.status = 'active'
        AND NOT EXISTS (
          SELECT 1 FROM payments p 
          WHERE p.tenant_id = t.id
          AND YEAR(p.payment_date) = YEAR(CURDATE())
          AND MONTH(p.payment_date) = MONTH(CURDATE())
          AND p.status = 'paid'
        )
        AND CURDATE() <= DATE_ADD(
          DATE_FORMAT(CURDATE(), '%Y-%m-01'),
          INTERVAL (t.due_day + 4) DAY
        )
      ), 0) AS pending,
      COALESCE((
        SELECT SUM(p.amount)
        FROM payments p
        JOIN tenants t ON p.tenant_id = t.id
        WHERE t.pg_id = ?
        AND t.status = 'active'
        AND p.status = 'overdue'
      ), 0) AS overdue,
      COALESCE((
        SELECT SUM(t.rent_amount)
        FROM tenants t
        WHERE t.pg_id = ? AND t.status = 'active'
      ), 0) AS expected
  `;

  db.query(query, [pgId, pgId, pgId, pgId], (err, results) => {
    if (err) {
      console.log('MAIN QUERY ERROR:', err);
      return res.status(500).json({ success: false, message: "DB error", err });
    }
    console.log('MAIN QUERY RESULT:', results[0]);

    const summary = results[0];

    const statusQuery = `
      SELECT
        COUNT(CASE WHEN p.status = 'paid' THEN 1 END) as paid_count,
        COUNT(CASE WHEN p.status IS NULL AND CURDATE() <= DATE_ADD(
          DATE_FORMAT(CURDATE(), '%Y-%m-01'),
          INTERVAL (t.due_day + 4) DAY
        ) THEN 1 END) as due_count,
        COUNT(CASE WHEN p.status IS NULL AND CURDATE() > DATE_ADD(
          DATE_FORMAT(CURDATE(), '%Y-%m-01'),
          INTERVAL (t.due_day + 4) DAY
        ) THEN 1 END) as overdue_count
      FROM tenants t
      LEFT JOIN payments p 
        ON t.id = p.tenant_id
        AND YEAR(p.payment_date) = YEAR(CURDATE())
        AND MONTH(p.payment_date) = MONTH(CURDATE())
      WHERE t.pg_id = ? AND t.status = 'active'
    `;

    db.query(statusQuery, [pgId], (err, statusResults) => {
      if (err) {
        console.log('STATUS QUERY ERROR:', err);
        return res.status(500).json({ success: false, message: "DB error", err });
      }
      console.log('STATUS RESULT:', statusResults[0]);

      const chartQuery = `
        SELECT 
          DATE_FORMAT(p.payment_date, '%b') as month,
          YEAR(p.payment_date) as year,
          SUM(p.amount) as total
        FROM payments p
        JOIN tenants t ON p.tenant_id = t.id
        WHERE t.pg_id = ?
        AND p.payment_date >= DATE_SUB(CURDATE(), INTERVAL 6 MONTH)
        AND p.status = 'paid'
        GROUP BY YEAR(p.payment_date), MONTH(p.payment_date), DATE_FORMAT(p.payment_date, '%b')
        ORDER BY YEAR(p.payment_date), MONTH(p.payment_date)
      `;

      db.query(chartQuery, [pgId], (err, chartResults) => {
        if (err) {
          console.log('CHART QUERY ERROR:', err);
          return res.status(500).json({ success: false, message: "DB error", err });
        }
        console.log('CHART RESULT:', chartResults);
        console.log('SUMMARY RESULT:', {
          collected: summary.collected,
          pending: summary.pending,
          overdue: summary.overdue,
          expected: summary.expected,
        });

        return res.json({
          success: true,
          collected: summary.collected,
          pending: summary.pending,
          overdue: summary.overdue,
          expected: summary.expected,
          rent_status: {
            paid: statusResults[0].paid_count,
            due: statusResults[0].due_count,
            overdue: statusResults[0].overdue_count,
          },
          monthly_chart: chartResults,
        });
      });
    });
  });
});

// GET /api/admin/rent/tenants-status   calender
router.get('/tenants-status', authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      t.id,
      t.name,
      r.room_no as room_number,
      t.rent_amount,
      t.due_day,
      r.bed,
      p.amount as paid_amount,
      DATE_FORMAT(p.payment_date, '%Y-%m-%d') as payment_date,
      p.payment_mode,
      p.status as payment_status,
      CASE
        WHEN p.status = 'paid' THEN 'Paid'
        WHEN DAY(CURDATE()) > t.due_day + 5 THEN 'Overdue'
        ELSE 'Due'
      END as rent_status
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    LEFT JOIN payments p 
      ON p.tenant_id = t.id
      AND YEAR(p.payment_date) = YEAR(CURDATE())
      AND MONTH(p.payment_date) = MONTH(CURDATE())
    WHERE t.pg_id = ? AND t.status = 'active'
    ORDER BY t.name
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) {
      console.error('TENANTS STATUS ERROR:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    return res.json({ success: true, tenants: results });
  });
});

router.get('/overdue-months', authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      p.tenant_id,
      p.month,
      p.amount,
      p.due_date
    FROM payments p
    JOIN tenants t ON p.tenant_id = t.id
    WHERE t.pg_id = ?
    AND t.status = 'active'
    AND p.status = 'overdue'
    ORDER BY p.tenant_id, p.due_date
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) {
      console.error('OVERDUE MONTHS ERROR:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    return res.json({ success: true, overdue_months: results });
  });
});

// GET /api/admin/rent/:bed_type
router.get("/:bed_type", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  const bedType = req.params.bed_type;

  const query = `
    SELECT amount FROM rent
    WHERE pg_id = ? AND bed_type = ?
  `;

  db.query(query, [pgId, bedType], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: "Database error", err });
    }

    if (results.length === 0) {
      return res.status(404).json({ success: false, message: "Rent not found" });
    }

    return res.json({ success: true, amount: results[0].amount });
  });
});


module.exports = router;