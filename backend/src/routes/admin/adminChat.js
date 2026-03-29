const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");

// GET /api/admin/chat/tenants - Get all active tenants with unread count
router.get("/tenants", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      t.id,
      t.name,
      t.phone,
      r.room_no,
      (
        SELECT message FROM messages 
        WHERE pg_id = ? AND (
          (sender_type = 'tenant' AND sender_id = t.id) OR
          (receiver_type = 'tenant' AND receiver_id = t.id)
        )
        ORDER BY created_at DESC LIMIT 1
      ) as last_message,
      (
        SELECT created_at FROM messages 
        WHERE pg_id = ? AND (
          (sender_type = 'tenant' AND sender_id = t.id) OR
          (receiver_type = 'tenant' AND receiver_id = t.id)
        )
        ORDER BY created_at DESC LIMIT 1
      ) as last_message_time,
      (
        SELECT COUNT(*) FROM messages 
        WHERE pg_id = ? AND sender_type = 'tenant' 
        AND sender_id = t.id AND is_read = 0
      ) as unread_count
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    WHERE t.pg_id = ? AND t.status = 'active'
    ORDER BY last_message_time DESC
  `;

  db.query(query, [pgId, pgId, pgId, pgId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    return res.json({ success: true, tenants: results });
  });
});

// GET /api/admin/chat/messages/:tenantId - Get messages with a tenant
router.get("/messages/:tenantId", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  const tenantId = req.params.tenantId;

  // Mark tenant messages as read
  db.query(
    `UPDATE messages SET is_read = 1 
     WHERE pg_id = ? AND sender_type = 'tenant' AND sender_id = ?`,
    [pgId, tenantId]
  );

  const query = `
    SELECT * FROM messages 
    WHERE pg_id = ? AND (
      (sender_type = 'tenant' AND sender_id = ?) OR
      (receiver_type = 'tenant' AND receiver_id = ?)
    )
    ORDER BY created_at ASC
  `;

  db.query(query, [pgId, tenantId, tenantId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    return res.json({ success: true, messages: results });
  });
});

// POST /api/admin/chat/send - Send message to tenant
router.post("/send", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  const adminId = req.admin.id;
  const { tenant_id, message } = req.body;

  const query = `
    INSERT INTO messages (pg_id, sender_id, sender_type, receiver_id, receiver_type, message)
    VALUES (?, ?, 'admin', ?, 'tenant', ?)
  `;

  db.query(query, [pgId, adminId, tenant_id, message], (err, result) => {
    if (err) return res.status(500).json({ success: false, message: err.message });
    return res.json({ success: true, message_id: result.insertId });
  });
});

module.exports = router;