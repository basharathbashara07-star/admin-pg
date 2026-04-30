// backend/src/routes/tenant/emergencyRoutes.js

const express = require('express');
const router = express.Router();
const tenantAuth = require('../../../middleware/tenantAuth');
const { triggerSOS, cancelSOS } = require('../../controllers/tenant/emergencyController');

router.post('/sos', tenantAuth, triggerSOS);
router.post('/cancel', tenantAuth, cancelSOS);

module.exports = router;