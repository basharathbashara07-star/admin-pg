const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");

// PUT /api/admin/profile/update
router.put("/update", authenticateAdmin, async (req, res) => {
  console.log('PROFILE UPDATE HIT');
  const adminId = req.admin.id;
  const pgId = req.admin.pg_id;
  const { name, email, phone, pg_name, address } = req.body;
  console.log('Admin ID:', adminId);
  console.log('PG ID:', pgId);
  console.log('Body:', req.body);

  try {
    const updateAdmin = "UPDATE admins SET name=?, email=?, phone=? WHERE id=?";
    db.query(updateAdmin, [name, email, phone, adminId], (err) => {
      if (err) return res.status(500).json({ success: false, message: "DB error" });

      const updatePg = "UPDATE pgs SET pg_name=?, address=? WHERE id=?";
      db.query(updatePg, [pg_name, address, pgId], (err2) => {
        if (err2) return res.status(500).json({ success: false, message: "DB error" });

        return res.json({ success: true, message: "Profile updated successfully" });
      });
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});


const bcrypt = require("bcrypt");

// PUT /api/admin/profile/change-password
router.put("/change-password", authenticateAdmin, async (req, res) => {
  const adminId = req.admin.id;
  const { current_password, new_password } = req.body;

  try {
    // Get current password from database
    const query = "SELECT password FROM admins WHERE id = ?";
    db.query(query, [adminId], async (err, results) => {
      if (err) return res.status(500).json({ success: false, message: "DB error" });

      if (results.length === 0) {
        return res.status(404).json({ success: false, message: "Admin not found" });
      }

      // Check current password
      const isMatch = await bcrypt.compare(current_password, results[0].password);
      if (!isMatch) {
        return res.status(400).json({ success: false, message: "Current password is incorrect" });
      }

      // Hash new password
      const hashedPassword = await bcrypt.hash(new_password, 10);

      // Update password
      const updateQuery = "UPDATE admins SET password = ? WHERE id = ?";
      db.query(updateQuery, [hashedPassword, adminId], (err2) => {
        if (err2) return res.status(500).json({ success: false, message: "DB error" });

        return res.json({ success: true, message: "Password changed successfully" });
      });
    });
  } catch (e) {
    return res.status(500).json({ success: false, message: "Server error" });
  }
});

module.exports = router;