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
const adminProfileRoutes = require("./routes/admin/adminProfile");
const adminChatRoutes = require("./routes/admin/adminChat");
const adminVisitorsRoutes = require("./routes/admin/adminVisitors");

// Tenant routes
const tenantAuthRoutes = require("./routes/tenant/tenantAuth");
const tenantNoticeRoutes = require("./routes/tenant/tenantNotice");
const tenantChatRoutes = require("./routes/tenant/tenantChat");
const tenantVisitorsRoutes = require("./routes/tenant/tenantVisitors");
const tenantRentRoutes = require("./routes/tenant/tenantRent");
const {router: tenantRewardsRoutes}= require("./routes/tenant/tenantRewards");
const tenantExpensesRoutes = require("./routes/tenant/tenantExpenses");
const tenantMaintenanceRoutes = require("./routes/tenant/tenantMaintenance");
// middleware
app.use(cors());
app.use(express.json());

// ADMIN routes
app.use("/api/admin", adminAuthRoutes);
app.use('/api/admin/rooms', adminRoomRoutes);
app.use("/api/admin", adminTenantsRoutes);
app.use('/api/admin/rent', adminRentRoutes);
app.use('/api/admin/complaints', adminComplaintsRoutes);
app.use('/api/admin/profile', adminProfileRoutes);
app.use('/api/admin/chat',adminChatRoutes);
app.use('/api/admin/visitors',adminVisitorsRoutes);


//TENANT ROUTES
app.use("/api/tenant", tenantAuthRoutes);
app.use("/api/tenant", tenantNoticeRoutes);
app.use("/api/tenant/chat", tenantChatRoutes);
app.use("/api/tenant/visitors", tenantVisitorsRoutes);
app.use("/api/tenant/rent", tenantRentRoutes);
app.use("/api/tenant/rewards", tenantRewardsRoutes);
app.use("/api/tenant/expenses", tenantExpensesRoutes);
app.use("/api/tenant/maintenance", tenantMaintenanceRoutes);

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


// Cron job - runs every day at midnight -- overdue rent
cron.schedule('* * * * *', () => {
  const sql = `
    UPDATE payments p
    JOIN tenants t ON p.tenant_id = t.id
    SET p.status = 'overdue'
    WHERE p.status = 'pending'
    AND p.due_date < CURDATE()
  `;
  db.query(sql, (err) => {
    if (err) console.log('Payment cron error:', err);
    else console.log('Payment overdue updated!');
  });
});

cron.schedule('0 0 * * *', () => {
  const sql = `
    INSERT INTO payments (tenant_id, amount, month, status, due_date, payment_mode)
    SELECT 
      t.id,
      t.rent_amount,
      DATE_FORMAT(CURDATE(), '%M %Y'),
      'pending',
      DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL t.due_day DAY),
      'Cash'
    FROM tenants t
    WHERE t.status = 'active'
    AND NOT EXISTS (
      SELECT 1 FROM payments p
      WHERE p.tenant_id = t.id
      AND p.month = DATE_FORMAT(CURDATE(), '%M %Y')
    )
  `;
  db.query(sql, (err) => {
    if (err) console.log('Monthly payment creation error:', err);
    else console.log('Monthly payments created!');
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