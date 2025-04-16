process.env.NODE_TLS_REJECT_UNAUTHORIZED = "0";

const express = require("express");
const session = require("express-session");
const Keycloak = require("keycloak-connect");
const path = require("path");

const app = express();
const PORT = 5500;

// Session setup
const memoryStore = new session.MemoryStore();
app.use(
  session({
    secret: "server secret",
    resave: false,
    saveUninitialized: true,
    store: memoryStore,
  })
);

// Keycloak
const keycloak = new Keycloak({ store: memoryStore });
app.use(keycloak.middleware());

// Serve static files from the "public" folder
app.use(express.static(path.join(__dirname, "public")));

// Public route
app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public/index.html"));
});

// Protected route
app.get("/protected", keycloak.protect(), (req, res) => {
  res.sendFile(path.join(__dirname, "public/protected.html"));
});

// Admin-only route
app.get("/admin", keycloak.protect("realm:admin"), (req, res) => {
  res.sendFile(path.join(__dirname, "public/admin.html"));
});

// Logout route
// app.get("/admin", keycloak.protect(), (req, res) => {
//   keycloak.deauthenticated();
//   send("Bye! ")
// });

// Forbidden fallback
app.use((req, res) => {
  res.status(403).sendFile(path.join(__dirname, "public/forbidden.html"));
});

app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`);
});
