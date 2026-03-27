// adminTenants.js

const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");
const bcrypt = require("bcryptjs");
const nodemailer = require("nodemailer");

// GET /api/admin/tenants → only admin's tenants + current month payment
router.get("/tenants", authenticateAdmin, (req, res) => {
  const adminId = req.admin.id;

  const query = `
    SELECT 
        t.id,
        t.name,
        t.email,
        t.phone,
        t.gender,
        t.father_name,
        t.father_phone,
        t.mother_name,
        t.mother_phone,
        t.check_in_date,
        t.rent_amount,
        t.due_day,
        r.room_no,
        r.floor,
        r.bed,
        p.amount AS payment_amount,
        CASE 
            WHEN p.status = 'paid' THEN 'paid'
            WHEN p.status IS NULL AND CURDATE() > DATE_ADD(
                DATE_FORMAT(CURDATE(), '%Y-%m-01'), 
                INTERVAL (t.due_day + 4) DAY
            ) THEN 'overdue'
            ELSE 'due'
        END AS payment_status,
        p.payment_date
    FROM tenants t
    JOIN pgs pg ON t.pg_id = pg.id
    LEFT JOIN rooms r ON t.room_id = r.id
    LEFT JOIN payments p 
        ON t.id = p.tenant_id
        AND YEAR(p.payment_date) = YEAR(CURDATE())
        AND MONTH(p.payment_date) = MONTH(CURDATE())
    WHERE pg.admin_id = ? AND t.status = 'active'
    ORDER BY t.created_at DESC
`;

  db.query(query, [adminId], (err, results) => {
    if (err) {
      console.error("Database Error:", err);
      return res.status(500).json({ 
        success: false, 
        message: "Database error", 
        err 
      });
    }

    res.status(200).json({
      success: true,
      count: results.length,
      tenants: results
    });
  });
});

// GET /api/admin/tenants/counts
router.get("/tenants/counts", authenticateAdmin, (req, res) => {
  console.log("Admin object:", req.admin);
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      COUNT(*) as total_count,
      COUNT(CASE WHEN t.status = 'active' THEN 1 END) as active_count,
      COUNT(CASE WHEN t.status = 'vacated' THEN 1 END) as vacated_count,
      COUNT(CASE WHEN t.status = 'active' AND NOT EXISTS (
        SELECT 1 FROM payments p 
        WHERE p.tenant_id = t.id 
        AND YEAR(p.payment_date) = YEAR(CURDATE())
        AND MONTH(p.payment_date) = MONTH(CURDATE())
        AND p.status = 'paid'
      ) THEN 1 END) as pending_count
    FROM tenants t
    WHERE t.pg_id = ?
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });
    return res.json({ 
      success: true, 
      total: results[0].total_count,
      active: results[0].active_count,
      vacated: results[0].vacated_count,
      pending: results[0].pending_count,
    });
  });
});


// GET /api/admin/tenants/:id → get single tenant
router.get("/tenants/:id", authenticateAdmin, (req, res) => {
  const tenantId = req.params.id;

  const query = `
    SELECT 
        t.id,
        t.name,
        t.email,
        t.phone,
        t.gender,
        t.father_name,
        t.father_phone,
        t.mother_name,
        t.mother_phone,
        t.check_in_date,
        t.rent_amount,
        t.due_day,
        r.room_no,
        r.floor,
        r.bed,
        CASE 
            WHEN p.status = 'paid' THEN 'paid'
            WHEN p.status IS NULL AND CURDATE() > DATE_ADD(
                DATE_FORMAT(CURDATE(), '%Y-%m-01'), 
                INTERVAL (t.due_day + 4) DAY
            ) THEN 'overdue'
            ELSE 'due'
        END AS payment_status
    FROM tenants t
    LEFT JOIN rooms r ON t.room_id = r.id
    LEFT JOIN payments p 
        ON t.id = p.tenant_id
        AND YEAR(p.payment_date) = YEAR(CURDATE())
        AND MONTH(p.payment_date) = MONTH(CURDATE())
    WHERE t.id = ?
`;

  db.query(query, [tenantId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });
    if (results.length === 0) return res.status(404).json({ success: false, message: "Tenant not found" });

    return res.json({ success: true, tenant: results[0] });
  });
});






// POST /api/admin/tenants → add tenant
router.post("/tenants", authenticateAdmin, async (req, res) => {
  const { name, email, phone, gender, father_name, father_phone, mother_name, mother_phone, room_id, bed_type, due_day } = req.body;
  const pgId = req.admin.pg_id;

  try {
    const rawPassword = Math.random().toString(36).slice(-8);
    const hashedPassword = await bcrypt.hash(rawPassword, 10);

    const rentQuery = `SELECT amount FROM rent WHERE pg_id = ? AND bed_type = ?`;
    db.query(rentQuery, [pgId, bed_type], async (err, rentResults) => {
      if (err) return res.status(500).json({ success: false, message: "DB error fetching rent" });

      const rentAmount = rentResults.length > 0 ? rentResults[0].amount : 0;

      const insertQuery = `
  INSERT INTO tenants (pg_id, room_id, name, email, password, phone, gender, father_name, father_phone, mother_name, mother_phone, rent_amount, due_day, status, check_in_date)
  VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'active', CURDATE())
`;
db.query(insertQuery, [pgId, room_id, name, email, hashedPassword, phone, gender, father_name, father_phone, mother_name, mother_phone, rentAmount, due_day], async (err, result) => {
        if (err) return res.status(500).json({ success: false, message: "DB error inserting tenant", err });

        const updateRoomQuery = `
          UPDATE rooms SET 
            current_occupancy = current_occupancy + 1,
            status = CASE 
              WHEN current_occupancy + 1 >= capacity THEN 'full'
              ELSE 'partial'
            END
          WHERE id = ?
        `;
        db.query(updateRoomQuery, [room_id], async (err) => {
          if (err) return res.status(500).json({ success: false, message: "DB error updating room" });

          const pgQuery = `SELECT pg_name FROM pgs WHERE id = ?`;
          db.query(pgQuery, [pgId], async (err, pgResults) => {
            const pgName = pgResults.length > 0 ? pgResults[0].pg_name : "Your PG";

            const transporter = nodemailer.createTransport({
              service: "gmail",
              auth: {
                user: process.env.EMAIL_USER,
                pass: process.env.EMAIL_PASS,
              },
            });

            const mailOptions = {
              from: process.env.EMAIL_USER,
              to: email,
              subject: `Welcome to ${pgName} - Your Login Credentials`,
              html: `
                <div style="font-family: Arial, sans-serif; max-width: 500px; margin: auto; padding: 32px; border: 1px solid #e0e0e0; border-radius: 16px;">
                  <div style="text-align: center; margin-bottom: 24px;">
                    <h1 style="color: #2196F3; margin: 0;">🏠 ${pgName}</h1>
                    <p style="color: #9e9e9e; font-size: 13px; margin: 4px 0;">PG Management System</p>
                  </div>
                  <h2 style="color: #212121;">Welcome, ${name}! 👋</h2>
                  <p style="color: #424242; font-size: 14px;">
                    You have been successfully registered as a tenant at <b>${pgName}</b>. 
                    Use the credentials below to access your tenant portal.
                  </p>
                  <div style="background: #E3F2FD; padding: 20px; border-radius: 12px; margin: 20px 0;">
                    <p style="margin: 8px 0; font-size: 14px;"><b>📧 Email:</b> ${email}</p>
                    <p style="margin: 8px 0; font-size: 14px;"><b>🔑 Password:</b> ${rawPassword}</p>
                  </div>
                  <p style="color: #424242; font-size: 13px;">
                    Please login and change your password as soon as possible for security.
                  </p>
                  <div style="margin-top: 24px; padding-top: 16px; border-top: 1px solid #e0e0e0; text-align: center;">
                    <p style="color: #9e9e9e; font-size: 11px;">
                      This is an automated message from ${pgName}. 
                      If you did not expect this, please contact your PG admin.
                    </p>
                  </div>
                </div>
              `,
            };

            try {
              await transporter.sendMail(mailOptions);
            } catch (mailErr) {
              console.error("Email error:", mailErr);
            }

            return res.status(200).json({
              success: true,
              message: "Tenant added successfully",
              tenantId: result.insertId,
              rent: rentAmount,
            });
          });
        });
      });
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: "Server error", e });
  }
});



// POST /api/admin/tenants/payment → record payment
router.post("/tenants/payment", authenticateAdmin, async (req, res) => {
  const { tenant_id, amount, payment_mode, month, due_date, payment_date } = req.body;

  try {
    const checkQuery = `
      SELECT id FROM payments 
      WHERE tenant_id = ? AND month = ?
    `;
    db.query(checkQuery, [tenant_id, month], (err, existing) => {
      if (err) return res.status(500).json({ success: false, message: "DB error" });

      if (existing.length > 0) {
        console.log('payment_mode received:', payment_mode);
        console.log('full body:', req.body);
        const updateQuery = `
          UPDATE payments SET amount = ?, status = ?, payment_date = ?, payment_mode = ?
          WHERE tenant_id = ? AND month = ?
        `;
        const status = amount >= parseFloat(req.body.total_rent) ? 'paid' : 'pending';
        db.query(updateQuery, [amount, status, payment_date || new Date(), payment_mode, tenant_id, month], (err) => {
          if (err) return res.status(500).json({ success: false, message: "DB error updating payment" });
          return res.json({ success: true, message: "Payment updated successfully" });
        });
      } else {
        const insertQuery = `
          INSERT INTO payments (tenant_id, amount, month, status, payment_date, due_date, payment_mode)
          VALUES (?, ?, ?, ?, ?, ?, ?)
        `;
        const status = amount >= parseFloat(req.body.total_rent) ? 'paid' : 'pending';
        db.query(insertQuery, [tenant_id, amount, month, status, payment_date || new Date(), due_date, payment_mode], (err) => {
          if (err) return res.status(500).json({ success: false, message: "DB error inserting payment", err });
          return res.json({ success: true, message: "Payment recorded successfully" });
        });
      }
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: "Server error", e });
  }
});

// PUT /api/admin/tenants/:id → edit tenant
router.put("/tenants/:id", authenticateAdmin, async (req, res) => {
  const tenantId = req.params.id;
  const { email, phone, father_name, father_phone, mother_name, mother_phone, room_id } = req.body;

  try {
    // 1. Update tenant details
    const updateQuery = `
      UPDATE tenants 
      SET email = ?, phone = ?, father_name = ?, father_phone = ?, mother_name = ?, mother_phone = ?
      WHERE id = ?
    `;
   db.query(updateQuery, [email, phone, father_name, father_phone, mother_name, mother_phone, tenantId], async (err) => {
      if (err) return res.status(500).json({ success: false, message: "DB error updating tenant", err });

      // 2. If room changed, update room
      if (room_id) {
        // Get current room_id
        const getCurrentRoom = `SELECT room_id FROM tenants WHERE id = ?`;
        db.query(getCurrentRoom, [tenantId], (err, results) => {
          if (err) return res.status(500).json({ success: false, message: "DB error" });

          const oldRoomId = results[0].room_id;

          // Decrease old room occupancy
          const decreaseQuery = `
            UPDATE rooms SET 
              current_occupancy = current_occupancy - 1,
              status = CASE 
                WHEN current_occupancy - 1 <= 0 THEN 'available'
                ELSE 'partial'
              END
            WHERE id = ?
          `;
          db.query(decreaseQuery, [oldRoomId], (err) => {
            if (err) return res.status(500).json({ success: false, message: "DB error decreasing room" });

            // Increase new room occupancy
            const increaseQuery = `
              UPDATE rooms SET 
                current_occupancy = current_occupancy + 1,
                status = CASE 
                  WHEN current_occupancy + 1 >= capacity THEN 'full'
                  ELSE 'partial'
                END
              WHERE id = ?
            `;
            db.query(increaseQuery, [room_id], (err) => {
              if (err) return res.status(500).json({ success: false, message: "DB error increasing room" });

              // Update tenant room
              const updateRoomQuery = `UPDATE tenants SET room_id = ? WHERE id = ?`;
              db.query(updateRoomQuery, [room_id, tenantId], (err) => {
                if (err) return res.status(500).json({ success: false, message: "DB error updating tenant room" });

                return res.json({ success: true, message: "Tenant updated successfully" });
              });
            });
          });
        });
      } else {
        return res.json({ success: true, message: "Tenant updated successfully" });
      }
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: "Server error", e });
  }
});




// PUT /api/admin/tenants/:id/vacate → vacate tenant
router.put("/tenants/:id/vacate", authenticateAdmin, (req, res) => {
  const tenantId = req.params.id;

  // 1. Get tenant's room_id
  const getRoomQuery = `SELECT room_id FROM tenants WHERE id = ?`;
  db.query(getRoomQuery, [tenantId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });

    const roomId = results[0].room_id;

    // 2. Update tenant status to vacated
    const vacateQuery = `
      UPDATE tenants SET status = 'vacated', check_out_date = CURDATE() 
      WHERE id = ?
    `;
    db.query(vacateQuery, [tenantId], (err) => {
      if (err) return res.status(500).json({ success: false, message: "DB error vacating tenant" });

      // 3. Decrease room occupancy
      const updateRoomQuery = `
        UPDATE rooms SET 
          current_occupancy = current_occupancy - 1,
          status = CASE 
            WHEN current_occupancy - 1 <= 0 THEN 'available'
            ELSE 'partial'
          END
        WHERE id = ?
      `;
      db.query(updateRoomQuery, [roomId], (err) => {
        if (err) return res.status(500).json({ success: false, message: "DB error updating room" });

        return res.json({ success: true, message: "Tenant vacated successfully" });
      });
    });
  });
});

                                                      // DELETE /api/admin/tenants/:id → delete tenant
router.delete("/tenants/:id", authenticateAdmin, (req, res) => {
  const tenantId = req.params.id;

  // 1. Get tenant's room_id
  const getRoomQuery = `SELECT room_id FROM tenants WHERE id = ?`;
  db.query(getRoomQuery, [tenantId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });

    const roomId = results[0].room_id;

    // 2. Decrease room occupancy
    const updateRoomQuery = `
      UPDATE rooms SET 
        current_occupancy = current_occupancy - 1,
        status = CASE 
          WHEN current_occupancy - 1 <= 0 THEN 'available'
          ELSE 'partial'
        END
      WHERE id = ?
    `;
    db.query(updateRoomQuery, [roomId], (err) => {
      if (err) return res.status(500).json({ success: false, message: "DB error updating room" });

      // 3. Delete tenant (payments auto deleted via CASCADE)
      const deleteQuery = `DELETE FROM tenants WHERE id = ?`;
      db.query(deleteQuery, [tenantId], (err) => {
        if (err) return res.status(500).json({ success: false, message: "DB error deleting tenant" });

        return res.json({ success: true, message: "Tenant deleted successfully" });
      });
    });
  });
});

// GET /api/admin/tenants/:id/payments → get all payments for a tenant
router.get("/tenants/:id/payments", authenticateAdmin, (req, res) => {
  const tenantId = req.params.id;
  const query = `
    SELECT month, amount, status, payment_date, payment_mode, due_date
    FROM payments
    WHERE tenant_id = ?
    ORDER BY due_date DESC
  `;
  db.query(query, [tenantId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });
    return res.json({ success: true, payments: results });
  });
});

// GET /api/admin/dashboard/summary
router.get("/dashboard/summary", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const sql = `
    SELECT
      (SELECT COUNT(*) FROM tenants WHERE pg_id = ? AND status = 'active') AS total_residents,
      (SELECT COUNT(*) FROM rooms WHERE pg_id = ? AND status = 'available') AS vacant_rooms,
      (SELECT COALESCE(SUM(amount), 0) FROM payments p 
        JOIN tenants t ON p.tenant_id = t.id 
        WHERE t.pg_id = ? AND p.status = 'pending') AS pending_rent,
      (SELECT COUNT(*) FROM complaints c
        JOIN tenants t ON c.tenant_id = t.id
        WHERE t.pg_id = ? AND c.status = 'open') AS open_tickets
  `;

  db.query(sql, [pgId, pgId, pgId, pgId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });
    return res.json({ success: true, data: results[0] });
  });
});
                              
module.exports = router;