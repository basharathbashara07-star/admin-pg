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

module.exports = router;