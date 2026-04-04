const express = require("express");
const router = express.Router();
const db = require("../../config/db");
const authenticateAdmin = require("../../../middleware/auth");

// GET /api/admin/rooms
router.get("/", authenticateAdmin, (req, res) => {
  console.log("Token pg_id:", req.admin.pg_id); // debug log
  const pgId = req.admin.pg_id;

  const query = `
    SELECT id, room_no, floor, bed, capacity, current_occupancy, status
    FROM rooms
    WHERE pg_id = ? AND current_occupancy < capacity
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: "Database error", err });
    }

    const rooms = results.map(r => ({
      id: r.id,
      room_no: r.room_no,
      floor: r.floor,
      bed: r.bed,
      capacity: r.capacity,
      current_occupancy: r.current_occupancy,
      status: r.status,
      availableBeds: r.capacity - r.current_occupancy
    }));

    return res.json({ success: true, rooms });
  });
});


// GET /api/admin/rooms/occupancy-summary
router.get("/occupancy-summary", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
    SUM(r.capacity) as total_beds,
    (SELECT COUNT(*) FROM tenants t WHERE t.pg_id = ? AND t.status = 'active') as occupied_beds
  FROM rooms r
  WHERE r.pg_id = ?  `;

  db.query(query, [pgId, pgId], (err, results) => {
    if (err) {
      return res.status(500).json({ success: false, message: "Database error" });
    }

    const total = results[0].total_beds || 0;
    const occupied = results[0].occupied_beds || 0;
    const vacant = total - occupied;
    const percentage = total > 0 ? ((occupied / total) * 100).toFixed(1) : 0;

    return res.json({
      success: true,
      total_beds: total,
      occupied: occupied,
      vacant: vacant,
      percentage: parseFloat(percentage)
    });
  });
});


// GET /api/admin/rooms/all - Get all rooms floor wise with tenants
router.get("/all", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;

  const query = `
    SELECT 
      r.id, r.room_no, r.floor, r.bed, r.capacity, 
      r.current_occupancy, r.status,
      t.id as tenant_id, t.name as tenant_name
    FROM rooms r
    LEFT JOIN tenants t ON t.room_id = r.id AND t.status = 'active'
    WHERE r.pg_id = ?
    ORDER BY r.floor, r.room_no
  `;

  db.query(query, [pgId], (err, results) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });

    // Group by floor then room
    const floorsMap = {};
    results.forEach(row => {
      if (!floorsMap[row.floor]) floorsMap[row.floor] = {};
      if (!floorsMap[row.floor][row.id]) {
        floorsMap[row.floor][row.id] = {
          id: row.id,
          room_no: row.room_no,
          floor: row.floor,
          bed: row.bed,
          capacity: row.capacity,
          current_occupancy: row.current_occupancy,
          status: row.status,
          tenants: []
        };
      }
      if (row.tenant_id) {
        floorsMap[row.floor][row.id].tenants.push({
          id: row.tenant_id,
          name: row.tenant_name,
        });
      }
    });

    const floors = Object.keys(floorsMap).map(floor => ({
      floor,
      rooms: Object.values(floorsMap[floor])
    }));

    return res.json({ success: true, floors });
  });
});

// POST /api/admin/rooms/add - Add a new room
// POST /api/admin/rooms/add - Add a new room
router.post("/add", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  const { room_no, floor, bed, capacity, rent_amount } = req.body;
  console.log('ADD ROOM BODY:', req.body);

  const query = `
    INSERT INTO rooms (pg_id, room_no, floor, bed, capacity, rent_amount)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.query(query, [pgId, room_no, floor, bed, capacity, rent_amount || 0], (err, result) => {
    if (err) return res.status(500).json({ success: false, message: "DB error" });
    return res.json({ success: true, message: "Room added successfully", room_id: result.insertId });
  });
});

// DELETE /api/admin/rooms/:id - Delete a room
router.delete("/:id", authenticateAdmin, (req, res) => {
  const pgId = req.admin.pg_id;
  const roomId = req.params.id;

  db.query(
    "DELETE FROM rooms WHERE id = ? AND pg_id = ?",
    [roomId, pgId],
    (err) => {
      if (err) return res.status(500).json({ success: false, message: "DB error" });
      return res.json({ success: true, message: "Room deleted successfully" });
    }
  );
});

module.exports = router;