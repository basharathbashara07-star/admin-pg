const express = require("express");
const cors = require("cors");
require('dotenv').config();
const cron = require('node-cron');
const db = require('./config/db');

console.log("EMAIL_USER=",process.env.EMAIL_USER);
console.log("EMAIL_PASS=",process.env.EMAIL_PASS);

const app = express();

// Admin routes
const adminAuthRoutes = require("./routes/admin/adminAuth");
const adminTenantsRoutes = require("./routes/admin/adminTenants");
const adminRoomRoutes = require('./routes/admin/adminRoom');
const adminRentRoutes = require('./routes/admin/adminRent');
const adminComplaintsRoutes = require('./routes/admin/adminComplaints');

// Tenant routes
const tenantAuthRoutes = require("./routes/tenantAuth");

// middleware
app.use(cors());
app.use(express.json());

// ADMIN routes
app.use("/api/admin", adminAuthRoutes);
app.use('/api/admin/rooms', adminRoomRoutes);
app.use("/api/admin", adminTenantsRoutes);
app.use('/api/admin/rent', adminRentRoutes);
app.use('/api/admin/complaints', adminComplaintsRoutes);

// Tenant routes
app.use("/api/tenant", tenantAuthRoutes);

// Cron job - runs every day at midnight
cron.schedule('* * * * *', () => {
  const sql = `
    UPDATE complaints 
    SET status = 'overdue' 
    WHERE due_date < CURDATE() 
    AND status IN ('open', 'in_progress')
  `;
  db.query(sql, (err) => {
    if (err) console.log('Cron error:', err);
    else console.log('Overdue complaints updated!');
  });
});

// test route
app.get("/", (req, res) => {
  res.send("Backend + Database running");
});

// server
const PORT = 5000;
app.listen(PORT, "0.0.0.0", () => {
  console.log("Server running on port 5000");
});