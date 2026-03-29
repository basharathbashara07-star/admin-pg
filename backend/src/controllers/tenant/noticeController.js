const db = require('../../config/db');

const getNotices = (req, res) => {
  const tenantId = req.tenant.id;
  const pgId = req.tenant.pg_id;

  // 1. Get admin notices
  db.query(
    `SELECT * FROM notices WHERE pg_id = ? AND is_active = TRUE ORDER BY created_at DESC`,
    [pgId],
    (err, notices) => {
      if (err) return res.status(500).json({ success: false, message: 'Server error' });

      // 2. Get rent alert
      db.query(
        `SELECT * FROM payments WHERE tenant_id = ? AND status IN ('pending','overdue') ORDER BY due_date ASC LIMIT 1`,
        [tenantId],
        (err2, rentRows) => {
          if (err2) return res.status(500).json({ success: false, message: 'Server error' });

          // 3. Get maintenance alert
          db.query(
            `SELECT * FROM complaints WHERE tenant_id = ? AND status != 'resolved' ORDER BY created_at DESC LIMIT 1`,
            [tenantId],
            (err3, complaintRows) => {
              if (err3) return res.status(500).json({ success: false, message: 'Server error' });

              const autoAlerts = [];

              if (rentRows.length > 0) {
                const r = rentRows[0];
                const due = new Date(r.due_date);
                const today = new Date();
                const daysLeft = Math.ceil((due - today) / (1000 * 60 * 60 * 24));
                autoAlerts.push({
                  id: 'rent_alert',
                  title: daysLeft <= 0 ? 'Rent Overdue!' : `Rent Due in ${daysLeft} day${daysLeft === 1 ? '' : 's'}`,
                  message: `Your rent of Rs.${r.amount} is ${daysLeft <= 0 ? 'overdue' : `due on ${due.toDateString()}`}. Please pay soon!`,
                  type: daysLeft <= 0 ? 'urgent' : 'rent',
                  auto: true,
                  created_at: new Date(),
                });
              }

              if (complaintRows.length > 0) {
                const c = complaintRows[0];
                autoAlerts.push({
                  id: 'complaint_alert',
                  title: `Maintenance: ${c.title}`,
                  message: `Your request is currently "${c.status.replace('_', ' ')}". We will update you soon.`,
                  type: 'maintenance',
                  auto: true,
                  created_at: c.created_at,
                });
              }

              return res.status(200).json({
                success: true,
                data: {
                  auto_alerts: autoAlerts,
                  notices,
                },
              });
            }
          );
        }
      );
    }
  );
};

module.exports = { getNotices };