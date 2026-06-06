const express = require("express");
const http = require("http");
const https = require("https");
const { URL } = require("url");

const router = express.Router();

const RAG_SERVICE_URL =
  process.env.RAG_SERVICE_URL || "http://127.0.0.1:9000";

function getRagTarget() {
  const base = new URL(RAG_SERVICE_URL);
  const path = `${base.pathname.replace(/\/$/, "")}/ask-navigation`;
  return {
    transport: base.protocol === "https:" ? https : http,
    hostname: base.hostname,
    port:
      base.port ||
      (base.protocol === "https:" ? 443 : base.protocol === "http:" ? 80 : 9000),
    path,
  };
}

// Route: POST /api/rag/ask-navigation
router.post("/ask-navigation", (req, res) => {
  const { question } = req.body;

  if (!question || typeof question !== "string" || !question.trim()) {
    return res.status(400).json({
      success: false,
      message: "question is required",
      data: null,
    });
  }

  const trimmedQuestion = question.trim();
  const postData = JSON.stringify({ question: trimmedQuestion });
  const ragTarget = getRagTarget();

  const options = {
    hostname: ragTarget.hostname,
    port: ragTarget.port,
    path: ragTarget.path,
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Content-Length": Buffer.byteLength(postData),
    },
  };

  const request = ragTarget.transport.request(options, (response) => {
    let data = "";

    response.on("data", (chunk) => {
      data += chunk;
    });

    response.on("end", () => {
      try {
        const parsed = JSON.parse(data);
        return res.json(parsed);
      } catch (error) {
        console.error("[RAG Route JSON Parse Error]", error.message);
        return res.status(502).json({
          success: false,
          message: "Navigation assistant is currently unavailable",
        });
      }
    });
  });

  request.on("error", (err) => {
    console.error("[RAG Route HTTP Request Error]", err.message);
    return res.status(502).json({
      success: false,
      message: "Navigation assistant is currently unavailable",
    });
  });

  request.setTimeout(15000, () => {
    request.destroy(new Error("Timeout waiting for RAG service"));
  });

  request.write(postData);
  request.end();
});

module.exports = router;
