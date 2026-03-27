import { useState } from "react";
import "../styles/Login.css";

function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const handleLogin = async (e) => {
    e.preventDefault();
    setError("");
    setLoading(true);

    try {
      const res = await fetch("http://localhost:5000/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ email, password }),
      });

      const data = await res.json();

      if (!res.ok) {
        setError(data.message || "Login failed");
      } else {
        alert(`Welcome ${data.user.name} (${data.user.role})`);
        // Dashboard redirect will be added later
      }
    } catch (err) {
      setError("Server not reachable");
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="login-container">
      <div className="login-box">
        
        {/* LOGO SECTION */}
        <div className="logo-section">
          <div className="logo-icon">🏢</div>
          <h1 className="logo-text">PG Manager</h1>
          <p className="logo-tagline">Smart Living Management</p>
        </div>

        {/* LOGIN FORM */}
        <form onSubmit={handleLogin}>
          <input
            type="email"
            placeholder="Email address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <input
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />

          {error && <p className="error">{error}</p>}

          <button type="submit" disabled={loading}>
            {loading ? "Logging in..." : "Login"}
          </button>
        </form>

        {/* EXTRA LINKS */}
        <div className="login-footer">
          <a href="/forgot-password">Forgot Password?</a>

        </div>

      </div>
    </div>
  );
}

export default Login;
