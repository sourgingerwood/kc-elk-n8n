process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0';

const https = require("https");
const fs = require("fs");
const express = require("express");
const session = require("express-session");
const Keycloak = require("keycloak-connect");
const path = require("path");

const app = express();
const PORT = 5500;

// Session setup
const memoryStore = new session.MemoryStore();
app.set('trust proxy', true);
//app.use((req, res, next) => {
//  if (req.secure) {
//    next();
//  } else {
//    res.redirect(`https://${req.headers.host}${req.url}`);
//  }
//});
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

// Critical-only route
app.get("/critical", keycloak.protect(), (req, res) => {
  res.sendFile(path.join(__dirname, "public/critical.html"));
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

const sslOptions = {
  key: fs.readFileSync("key.pem"),
  cert: fs.readFileSync("cert.pem")
};

https.createServer(sslOptions, app).listen(PORT, () => {
  console.log(`🔒 HTTPS server running at https://kc.ctt.tn:${PORT}`);
});

//app.listen(PORT, () => {
//  console.log(`Server running on http://kc.ctt.tn:${PORT}`);
//});
