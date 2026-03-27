const jwt = require("jsonwebtoken");

const authenticateAdmin = (req, res, next) => {
  // 1️⃣ Get token from headers
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return res.status(401).json({ message: "No token provided" });
  }

  // 2️⃣ Extract token (Bearer token)
  const token = authHeader.split(" ")[1]; // "Bearer <token>"

  if (!token) {
    return res.status(401).json({ message: "Token missing" });
  }

  try {
    // 3️⃣ Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // 4️⃣ Attach admin info to request
    req.admin = decoded; // now req.admin.id contains admin_id

    next(); // pass control to next route
  } catch (err) {
    return res.status(403).json({ message: "Invalid or expired token" });
  }
};

module.exports = authenticateAdmin;