const express = require('express');
const router = express.Router();
const authenticateTenant = require('../../../middleware/tenantAuth');
const db = require('../../config/db');

router.get('/conversations', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;

  // Get admin
  db.query(
    `SELECT id, name, 'admin' as type FROM admins WHERE pg_id = ?`,
    [pgId],
    (err, admins) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      // Get roommates
      db.query(
        `SELECT id, name, 'tenant' as type FROM tenants WHERE pg_id = ? AND id != ? AND status = 'active'`,
        [pgId, tenantId],
        (err, roommates) => {
          if (err) return res.status(500).json({ success: false, message: 'DB error' });

          const people = [...admins, ...roommates];
          const results = [];
          let completed = 0;

          if (people.length === 0) {
            return res.json({ success: true, data: [] });
          }

          people.forEach((person) => {
            const receiverType = person.type;

            db.query(
              `SELECT * FROM messages 
               WHERE pg_id = ? AND (
                 (sender_id = ? AND sender_type = 'tenant' AND receiver_id = ? AND receiver_type = ?) OR
                 (sender_id = ? AND sender_type = ? AND receiver_id = ? AND receiver_type = 'tenant')
               )
               ORDER BY created_at DESC LIMIT 1`,
              [pgId, tenantId, person.id, receiverType, person.id, receiverType, tenantId],
              (err, lastMsg) => {
                db.query(
                  `SELECT COUNT(*) as count FROM messages 
                   WHERE sender_id = ? AND sender_type = ? AND receiver_id = ? AND receiver_type = 'tenant' AND is_read = 0`,
                  [person.id, receiverType, tenantId],
                  (err, unread) => {
                    results.push({
                      ...person,
                      last_message: lastMsg[0]?.message || null,
                      last_time: lastMsg[0]?.created_at || null,
                      unread_count: unread[0].count,
                    });
                    completed++;
                    if (completed === people.length) {
                      return res.json({ success: true, data: results });
                    }
                  }
                );
              }
            );
          });
        }
      );
    }
  );
});

router.get('/messages/:receiverId', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;
  const receiverId = parseInt(req.params.receiverId);
  const receiverType = req.query.type || 'tenant';

  db.query(
    `SELECT * FROM messages 
     WHERE pg_id = ? AND (
       (sender_id = ? AND sender_type = 'tenant' AND receiver_id = ? AND receiver_type = ?) OR
       (sender_id = ? AND sender_type = ? AND receiver_id = ? AND receiver_type = 'tenant')
     )
     ORDER BY created_at ASC`,
    [pgId, tenantId, receiverId, receiverType, receiverId, receiverType, tenantId],
    (err, messages) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      // Mark as read
      db.query(
        `UPDATE messages SET is_read = 1 
         WHERE sender_id = ? AND sender_type = ? AND receiver_id = ? AND receiver_type = 'tenant'`,
        [receiverId, receiverType, tenantId]
      );

      return res.json({ success: true, data: messages });
    }
  );
});

router.post('/messages', authenticateTenant, (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;
  const { receiver_id, receiver_type, message } = req.body;

  if (!receiver_id || !receiver_type || !message) {
    return res.status(400).json({ success: false, message: 'receiver_id, receiver_type, message required.' });
  }

  db.query(
    `INSERT INTO messages (sender_id, sender_type, receiver_id, receiver_type, pg_id, message)
     VALUES (?, 'tenant', ?, ?, ?, ?)`,
    [tenantId, receiver_id, receiver_type, pgId, message],
    (err, result) => {
      if (err) return res.status(500).json({ success: false, message: 'DB error' });

      return res.status(201).json({
        success: true,
        data: {
          id: result.insertId,
          sender_id: tenantId,
          sender_type: 'tenant',
          receiver_id,
          receiver_type,
          message,
          created_at: new Date()
        }
      });
    }
  );
});

module.exports = router;