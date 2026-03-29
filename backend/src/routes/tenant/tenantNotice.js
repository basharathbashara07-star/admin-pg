const express = require('express');
const router = express.Router();
const { getNotices } = require('../../controllers/tenant/noticeController');
const tenantAuth = require('../../../middleware/tenantAuth');

router.get('/notices', tenantAuth, getNotices);

module.exports = router;