require("dotenv").config();

const express = require("express");
const cors = require("cors");

const authRoutes = require("./routes/auth");
const clientsRoutes = require("./routes/clients");
const ordersRoutes = require("./routes/orders");
const productsRoutes = require("./routes/products");
const dashboardRoutes = require("./routes/dashboard");
const messagesRoutes = require("./routes/messages");
const settingsRoutes = require("./routes/settings");
const aiRoutes = require("./routes/ai");
const categoriesRoutes = require("./routes/categories");
const chatbotRoutes = require("./routes/chatbot");
const ragRoutes = require("./routes/rag");

const app = express();

// ─── CORS ─────────────────────────────────────────────────────────────────────
app.use(
  cors({
    origin: "*",
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
  })
);

// ─── BODY PARSERS ─────────────────────────────────────────────────────────────
app.use(express.json({ limit: "20mb" }));
app.use(express.urlencoded({ extended: true, limit: "20mb" }));

// ─── REQUEST LOGGER ───────────────────────────────────────────────────────────
app.use((req, _res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`);
  next();
});

// ─── HEALTH ───────────────────────────────────────────────────────────────────
app.get("/", (_req, res) => {
  res.json({ success: true, message: "WhatShoppy backend is running" });
});

app.get("/health", (_req, res) => {
  res.json({
    success: true,
    message: "Backend healthy",
    time: new Date().toISOString(),
  });
});

// ─── ROUTES ───────────────────────────────────────────────────────────────────
app.use("/api/auth", authRoutes);
app.use("/api/clients", clientsRoutes);
app.use("/api/orders", ordersRoutes);
app.use("/api/products", productsRoutes);
app.use("/api/dashboard", dashboardRoutes);
app.use("/api/messages", messagesRoutes);
app.use("/api/settings", settingsRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/categories", categoriesRoutes);
app.use("/api/chatbot", chatbotRoutes);
app.use("/api/rag", ragRoutes);

// ─── 404 ──────────────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, message: "Route not found", data: null });
});

// ─── GLOBAL ERROR HANDLER ─────────────────────────────────────────────────────
// Express 5 propagates async errors automatically via next(err).
// This is the single place that formats all unhandled errors into JSON.
// eslint-disable-next-line no-unused-vars
app.use((err, _req, res, _next) => {
  const status = err.status || err.statusCode || 500;
  const isDev = process.env.NODE_ENV !== "production";
  const message = isDev
    ? err.message || "Internal server error"
    : "Internal server error";

  console.error(`[ERROR] ${status} — ${err.message}`);
  if (isDev && err.stack) console.error(err.stack);

  // Avoid sending a response if headers already sent (e.g. streaming)
  if (res.headersSent) return;
  res.status(status).json({ success: false, message, data: null });
});

// ─── PROCESS-LEVEL GUARDS ─────────────────────────────────────────────────────
// Strategy:
//   • unhandledRejection  → log + graceful shutdown (promise bug = unknown state)
//   • uncaughtException   → log + graceful shutdown (sync throw = unknown state)
// We do NOT silently swallow these. An unknown state is worse than a restart.

function gracefulShutdown(reason, err) {
  console.error(`\n[FATAL] ${reason}:`, err);
  console.error("Initiating graceful shutdown...");
  // Give in-flight requests up to 5 s to finish, then force-exit.
  server.close(() => {
    console.error("Server closed. Exiting.");
    process.exit(1);
  });
  setTimeout(() => {
    console.error("Forced exit after timeout.");
    process.exit(1);
  }, 5000).unref();
}

process.on("unhandledRejection", (reason) => {
  gracefulShutdown("unhandledRejection", reason);
});

process.on("uncaughtException", (err) => {
  gracefulShutdown("uncaughtException", err);
});

// ─── START ────────────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 3000;

const server = app.listen(PORT, "0.0.0.0", () => {
  console.log(`✅  Server running on http://localhost:${PORT}`);
  console.log("NODE_ENV  =", process.env.NODE_ENV || "development");
  console.log("SUPABASE_URL =", process.env.SUPABASE_URL ? "✅ loaded" : "❌ MISSING");
console.log(
  "SUPABASE_SERVICE_ROLE_KEY =",
  process.env.SUPABASE_SERVICE_ROLE_KEY ? "✅ loaded" : "❌ MISSING"
);  console.log("GEMINI_API_KEY =", process.env.GEMINI_API_KEY ? "✅ loaded" : "⚠️  not set (AI disabled)");
});
