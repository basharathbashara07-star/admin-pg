import { useState } from "react";
import "../styles/Login.css";

function ForgotPassword() {
  const [email, setEmail] = useState("");
  const [message, setMessage] = useState("");

  const handleSubmit = (e) => {
    e.preventDefault();

    // For now, frontend-only confirmation
    setMessage("Password reset link has been sent to your email.");
  };

  return (
    <div className="login-container">
      <div className="login-box">
        <div className="logo-section">
          <div className="logo-icon">🔐</div>
          <h1 className="logo-text">Forgot Password</h1>
          <p className="logo-tagline">Recover your account access</p>
        </div>

        <form onSubmit={handleSubmit}>
          <input
            type="email"
            placeholder="Enter your registered email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <button type="submit">Send Reset Link</button>
        </form>

        {message && <p style={{ color: "green", marginTop: "10px" }}>{message}</p>}

        <div className="login-footer">
          <a href="/">Back to Login</a>
        </div>
      </div>
    </div>
  );
}

export default ForgotPassword;
