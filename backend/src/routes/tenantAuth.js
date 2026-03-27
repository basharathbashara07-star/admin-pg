const express = require("express");
const router = express.Router();
const db = require("../config/db");
const nodemailer = require("nodemailer");

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

module.exports = router;