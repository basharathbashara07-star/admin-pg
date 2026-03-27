const db = require("../config/db");
const bcrypt = require("bcryptjs");

exports.registerAdmin = async (req, res) => {
  const { register_no, name, email, phone, password } = req.body;

  if (!register_no || !name || !email || !password) {
    return res.status(400).json({ message: "All required fields missing" });
  }

  // 1️⃣ Check register number (super admin given)
  db.query(
    "SELECT * FROM approved_pgs WHERE pg_register_no = ?",
    [register_no],
    async (err, pgResult) => {
      if (err) return res.status(500).json({ message: "DB error" });

      if (pgResult.length === 0) {
        return res.status(400).json({ message: "Invalid register number" });
      }

      // 2️⃣ Check admin already exists
      db.query(
        "SELECT * FROM admins WHERE email = ?",
        [email],
        async (err2, adminResult) => {
          if (err2) return res.status(500).json({ message: "DB error" });

          if (adminResult.length > 0) {
            return res.status(409).json({ message: "Admin already exists" });
          }

          // 3️⃣ Hash password
          const hashedPassword = await bcrypt.hash(password, 10);

          // 4️⃣ Insert admin
          db.query(
            `INSERT INTO admins 
             (register_no, name, email, phone, password)
             VALUES (?, ?, ?, ?, ?)`,
            [register_no, name, email, phone, hashedPassword],
            (err3) => {
              if (err3){
                console.error("ADMIN INSERT ERROR:",err3);
                return res.status(500).json({
                    message:"Admin creation failed",
                    error: err3.sqlMessage
                });
              }
                
            }
          );
        }
      );
    }
  );
};