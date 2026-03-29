const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const nodemailer = require("nodemailer");
const tenantAuth = require("../../../middleware/tenantAuth");

// Generate random 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// POST /api/tenant/forgot-password
router.post("/forgot-password", (req, res) => {
  const { email } = req.body;

  if (!email) return res.status(400).json({ message: "Email is required" });

  // Check if email exists in tenants table
  const checkQuery = "SELECT * FROM tenants WHERE email = ?";
  db.query(checkQuery, [email], (err, results) => {
    if (err) return res.status(500).json({ message: "Database error", err });

    if (results.length === 0) {
      // Always return same message to avoid exposing valid emails
      return res.json({
        message: "If this email is registered, an OTP has been sent",
      });
    }

    const tenantId = results[0].id;
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // OTP valid 10 mins

    // Insert OTP into tenant_otp table
    const insertQuery =
      "INSERT INTO tenant_otp (tenant_id, otp, expires_at) VALUES (?, ?, ?)";
    db.query(insertQuery, [tenantId, otp, expiresAt], (err2, result2) => {
      if (err2) return res.status(500).json({ message: "DB error", err2 });

      // Send OTP via email
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
        subject: "Your OTP for Reset Password",
        text: `Your OTP is: ${otp}. It will expire in 10 minutes.`,
      };

      transporter.sendMail(mailOptions, (error, info) => {
        if (error) {
          console.log(error);
          return res
            .status(500)
            .json({ message: "Failed to send OTP", error });
        } else {
          console.log("Email sent: " + info.response);
          return res.json({
            message: "If this email is registered, an OTP has been sent",
          });
        }
      });
    });
  });
});


// POST /api/tenant/verify-otp
router.post("/verify-otp", (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ message: "Email and OTP are required" });
  }

  // Get tenant ID from email
  const tenantQuery = "SELECT id FROM tenants WHERE email = ?";
  db.query(tenantQuery, [email], (err, tenantResults) => {
    if (err) return res.status(500).json({ message: "DB error", err });

    if (tenantResults.length === 0) {
      return res.status(400).json({ message: "Invalid email or OTP" });
    }

    const tenantId = tenantResults[0].id;

    // Check OTP
    const otpQuery =
      "SELECT * FROM tenant_otp WHERE tenant_id = ? AND otp = ? ORDER BY created_at DESC LIMIT 1";
    db.query(otpQuery, [tenantId, otp], (err2, otpResults) => {
      if (err2) return res.status(500).json({ message: "DB error", err2 });

      if (otpResults.length === 0) {
        return res.status(400).json({ message: "Invalid OTP" });
      }

      const otpEntry = otpResults[0];
      const now = new Date();

      if (now > otpEntry.expires_at) {
        return res.status(400).json({ message: "OTP has expired" });
      }

      // OTP is valid
      return res.json({ message: "OTP verified successfully" });
    });
  });
});

const bcrypt = require("bcrypt");

// POST /api/tenant/reset-password
router.post("/reset-password", async (req, res) => {
  const { email, new_password } = req.body;

  if (!email || !new_password) {
    return res.status(400).json({ message: "Email and new password are required" });
  }

  try {
    // Hash password
    const hashedPassword = await bcrypt.hash(new_password, 10);

    // Update tenant password
    const updateQuery = "UPDATE tenants SET password = ? WHERE email = ?";
    db.query(updateQuery, [hashedPassword, email], (err, result) => {
      if (err) return res.status(500).json({ message: "Database error", err });

      return res.json({ message: "Password reset successfully" });
    });
  } catch (err) {
    return res.status(500).json({ message: "Server error", err });
  }
});


// POST /api/tenant/login
router.post("/login", async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ success: false, message: "Email and password are required" });
  }

  const query = "SELECT * FROM tenants WHERE email = ?";
  db.query(query, [email], async (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });

    if (results.length === 0) {
      return res.status(400).json({ success: false, message: "Tenant not found" });
    }

    const tenant = results[0];
    const isMatch = await bcrypt.compare(password, tenant.password);

    if (!isMatch) {
      return res.status(400).json({ success: false, message: "Invalid password" });
    }

    const jwt = require("jsonwebtoken");
    const token = jwt.sign(
      { id: tenant.id, email: tenant.email, pg_id: tenant.pg_id },
      process.env.JWT_SECRET,
      { expiresIn: "7d" }
    );

    return res.json({
      success: true,
      message: "Login successful",
      token,
      tenant_id: tenant.id,
      name: tenant.name,
      email: tenant.email,
      phone: tenant.phone,
      pg_id: tenant.pg_id,
      room_id: tenant.room_id,
    });
  });
});

// GET /api/tenant/me
router.get("/me", tenantAuth, (req, res) => {
  const sql = `
    SELECT t.id, t.name, t.email, t.phone,
           t.father_name, t.father_phone,
           t.mother_name, t.mother_phone,
           t.check_in_date, t.check_out_date,
           t.rent_amount, t.due_day,
           r.room_no, p.pg_name, p.address
    FROM tenants t
    LEFT JOIN rooms r ON r.id = t.room_id
    LEFT JOIN pgs p ON p.id = t.pg_id
    WHERE t.id = ?`;

  db.query(sql, [req.tenant.id], (err, rows) => {
    if (err) {
      console.error('getMe error:', err);
      return res.status(500).json({ success: false, message: 'Server error' });
    }
    if (rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Tenant not found.' });
    }
    return res.status(200).json({ success: true, data: rows[0] });
  });
});

router.post("/logout", (req, res) => {
  return res.json({
    success: true,
    message: "Logged out successfully",
  });
});


module.exports = router;