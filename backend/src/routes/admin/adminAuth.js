const express = require("express");
const router = express.Router();
const db = require("../../config/db"); // Your MySQL connection
const nodemailer = require("nodemailer");
const bcrypt = require("bcrypt"); // Added for password hashing
const jwt = require("jsonwebtoken");

// Generate random 6-digit OTP
function generateOTP() {
  return Math.floor(100000 + Math.random() * 900000).toString();
}

// POST /api/admin/forgot-password
router.post("/forgot-password", (req, res) => {
  const { email } = req.body;

  if (!email) {
    return res.status(400).json({ success: false, message: "Email is required" });
  }

  // Step 1: Check if the email exists in admins table
  const checkQuery = "SELECT * FROM admins WHERE email = ?";
  db.query(checkQuery, [email], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: "Database error", err });
    }

    if (results.length === 0) {
      // Email NOT registered
      return res.json({
        success: false,
        message: "Email not registered. Please enter a registered email.",
      });
    }

    // Email exists → generate OTP
    const adminId = results[0].id;
    const otp = generateOTP();
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // OTP valid 10 mins

    // Store OTP in admin_otp table
    const insertQuery =
      "INSERT INTO admin_otp (admin_id, otp, expires_at) VALUES (?, ?, ?)";
    db.query(insertQuery, [adminId, otp, expiresAt], (err2) => {
      if (err2) {
        return res.status(500).json({ success: false, message: "Database error", err2 });
      }

      // Step 2: Send OTP via email
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
        subject: "Your OTP for Admin Reset Password",
        text: `Hello Admin,\n\nYour OTP for resetting your password is: ${otp}\nIt will expire in 10 minutes.\n\nIf you did not request this, please ignore this email.\n\nThanks!`,
      };

      transporter.sendMail(mailOptions, (error) => {
        if (error) {
          console.log(error);
          return res.status(500).json({
            success: false,
            message: "Failed to send OTP",
            error,
          });
        }

        // OTP sent successfully
        return res.json({
          success: true,
          message: `OTP has been sent to ${email}.`,
        });
      });
    });
  });
});

// POST /api/admin/verify-otp
router.post("/verify-otp", (req, res) => {
  const { email, otp } = req.body;

  if (!email || !otp) {
    return res.status(400).json({ status: "error", message: "Email and OTP are required" });
  }

  // 1️⃣ Get the admin ID from the email
  const adminQuery = "SELECT id FROM admins WHERE email = ?";
  db.query(adminQuery, [email], (err, adminResults) => {
    if (err) return res.status(500).json({ status: "error", message: "Database error", err });

    if (adminResults.length === 0) {
      return res.status(400).json({ status: "error", message: "Admin not found" });
    }

    const adminId = adminResults[0].id;

    // 2️⃣ Get the latest OTP for this admin
    const otpQuery = "SELECT * FROM admin_otp WHERE admin_id = ? ORDER BY created_at DESC LIMIT 1";
    db.query(otpQuery, [adminId], (err2, otpResults) => {
      if (err2) return res.status(500).json({ status: "error", message: "Database error", err2 });

      if (otpResults.length === 0) {
        return res.status(400).json({ status: "error", message: "No OTP found. Please request a new one." });
      }

      const otpEntry = otpResults[0];
      const now = new Date();

      // 3️⃣ Check if OTP expired
      if (now > otpEntry.expires_at) {
        return res.status(400).json({ status: "error", message: "OTP has expired. Please request a new one." });
      }

      // 4️⃣ Check if OTP matches
      if (otpEntry.otp !== otp) {
        return res.status(400).json({ status: "error", message: "Invalid OTP. Please try again." });
      }

      // ✅ OTP is correct
      return res.json({ status: "success", message: "OTP verified successfully" });
    });
  });
});

// POST /api/admin/reset-password
router.post("/reset-password", async (req, res) => {
  const { email, new_password } = req.body;

  if (!email || !new_password) {
    return res
      .status(400)
      .json({ success: false, message: "Email and new password are required" });
  }

  try {
    // 1️⃣ Hash the new password
    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(new_password, saltRounds);

    // 2️⃣ Update password in admins table
    const updateQuery = "UPDATE admins SET password = ? WHERE email = ?";
    db.query(updateQuery, [hashedPassword, email], (err, result) => {
      if (err) {
        return res
          .status(500)
          .json({ success: false, message: "Database error", err });
      }

      if (result.affectedRows === 0) {
        return res
          .status(404)
          .json({ success: false, message: "Admin not found" });
      }

      // ✅ Password updated successfully
      return res.json({ success: true, message: "Password reset successfully" });
    });
  } catch (error) {
    return res
      .status(500)
      .json({ success: false, message: "Error hashing password", error });
  }
});
router.post("/register", async (req, res) => {
  const {
    register_no,
    name,
    email,
    phone,
    password,
    pg_name,
    address,
    city
  } = req.body;

  if (!register_no || !name || !email || !password || !pg_name || !address) {
    return res.status(400).json({
      success: false,
      message: "All required fields must be filled",
    });
  }

  try {

    // 1️⃣ Check register number
    const checkRegisterQuery =
      "SELECT * FROM approved_pgs WHERE pg_register_no = ? AND pg_name = ?";

    db.query(checkRegisterQuery, [register_no,pg_name], async (err, results) => {
      if (err) return res.status(500).json({ success: false });

      if (results.length === 0) {
        return res.status(400).json({
          success: false,
          message: "PG name and register No do not match",
        });
      }

      const approvedPG = results[0];

      if (approvedPG.is_used === 1) {
        return res.status(400).json({
          success: false,
          message: "Register Number already used",
        });
      }

      // 2️⃣ Check if email exists
      const checkAdminQuery = "SELECT * FROM admins WHERE email = ?";
      db.query(checkAdminQuery, [email], async (err2, adminResults) => {

        if (err2) return res.status(500).json({ success: false });

        if (adminResults.length > 0) {
          return res.status(400).json({
            success: false,
            message: "Admin already registered",
          });
        }

        // 3️⃣ Hash password
        const hashedPassword = await bcrypt.hash(password, 10);

        // 4️⃣ Insert into admins
        const insertAdminQuery =
          "INSERT INTO admins (name, email, phone, password, pg_id) VALUES (?, ?, ?, ?, ?)";

        db.query(
          insertAdminQuery,
          [name, email, phone, hashedPassword, approvedPG.id],
          (err3, result) => {

            if (err3) return res.status(500).json({ success: false });

            const adminId = result.insertId; // 🔥 IMPORTANT

            // 5️⃣ Insert into pgs
            const insertPgQuery =
              "INSERT INTO pgs (admin_id, pg_name, address, city) VALUES (?, ?, ?, ?)";

            db.query(
              insertPgQuery,
              [adminId, pg_name, address, city],
              (err4) => {

                if (err4) return res.status(500).json({ success: false });

                // 6️⃣ Mark register number used
                const updateQuery =
                  "UPDATE approved_pgs SET is_used = 1 WHERE id = ?";

                db.query(updateQuery, [approvedPG.id]);

                return res.json({
                  success: true,
                  message: "Admin & PG registered successfully",
                });
              }
            );
          }
        );
      });
    });

  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error",
    });
  }
});

router.post("/login", async (req, res) => {
  const { email, password } = req.body;
  console.log("Email recieved:",email);

  if (!email || !password) {
    return res.status(400).json({
      success: false,
      message: "Email and password are required"
    });
  }

  try {
    const query = "SELECT * FROM admins WHERE email = ?";
    db.query(query, [email], async (err, results) => {
      console.log("DB result :", results);
      if (err) return res.status(500).json({ success: false });

      if (results.length === 0) {
        return res.status(400).json({
          success: false,
          message: "Admin not found"
        });
      }

      const admin = results[0];

      // Compare hashed password
      const isMatch = await bcrypt.compare(password, admin.password);

      if (!isMatch) {
        return res.status(400).json({
          success: false,
          message: "Invalid password"
        });
      }

      const token = jwt.sign(
        {id: admin.id, email: admin.email, pg_id:admin.pg_id},
        process.env.JWT_SECRET,
        {expiresIn: "1d"}

      );

      // Login success - Get PG details too
      const pgQuery = "SELECT * FROM pgs WHERE id = ?";
      db.query(pgQuery, [admin.pg_id], (pgErr, pgResults) => {
        const pg = pgResults && pgResults.length > 0 ? pgResults[0] : {};
        return res.json({
          success: true,
          message: "Login successful",
          token,
          admin_id: admin.id,
          pg_id: admin.pg_id,
          name: admin.name,
          email: admin.email,
          phone: admin.phone,
          pg_name: pg.pg_name ?? '',
          address: pg.address ?? '',
          city: pg.city ?? '',
        });
      });
    });
  } catch (error) {
    return res.status(500).json({
      success: false,
      message: "Server error"
    });
  }
});

module.exports = router;