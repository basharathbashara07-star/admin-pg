// backend/src/routes/admin/emergencyRoutes.js

const express = require('express');
const router = express.Router();
const authenticateAdmin = require('../../../middleware/auth');
const { getAlerts, resolveAlert } = require('../../controllers/tenant/emergencyController');

router.get('/alerts', authenticateAdmin, getAlerts);
router.post('/resolve/:alertId', authenticateAdmin, resolveAlert);

module.exports = router;