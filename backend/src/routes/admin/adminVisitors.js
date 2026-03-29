const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");

// GET /api/admin/visitors
router.get("/", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      v.id,
      v.name,
      v.phone,
      v.purpose,
      v.visit_date,
      v.status,
      v.created_at,
      t.name as tenant_name,
      r.room_no
    FROM visitors v
    JOIN tenants t ON v.tenant_id = t.id
    LEFT JOIN rooms r ON t.room_id = r.id
    WHERE v.pg_id = ?
    ORDER BY 
    CASE v.status 
    WHEN 'pending' THEN 1 
    WHEN 'approved' THEN 2 
    WHEN 'rejected' THEN 3 
  END,
  v.visit_date ASC
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    return res.json({ success: true, visitors: results });
  });
});

// PUT /api/admin/visitors/:id
router.put("/:id", authenticateAdmin, (req, res) => {
  const { status } = req.body;
  const visitorId = req.params.id;

  const query = `UPDATE visitors SET status = ? WHERE id = ?`;

  db.query(query, [status, visitorId], (err) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    return res.json({ success: true, message: "Visitor status updated" });
  });
});

module.exports = router;