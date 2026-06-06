const express = require("express");
const http = require("http");
const https = require("https");

const router = express.Router();

const LOCAL_AI_BASE_URL = process.env.LOCAL_AI_BASE_URL || "http://127.0.0.1:8000";
const LOCAL_AI_URL = process.env.LOCAL_AI_URL || `${LOCAL_AI_BASE_URL}/analyze-image`;
const LOCAL_PRICE_URL = process.env.LOCAL_PRICE_URL || `${LOCAL_AI_BASE_URL}/predict-price`;
const LOCAL_AI_TIMEOUT_MS = Number(process.env.LOCAL_AI_TIMEOUT_MS || 20000);

router.post("/analyze-image", async (req, res, next) => {
  try {
    const { image_base64, mime_type } = req.body;

    if (!image_base64 || typeof image_base64 !== "string") {
      return res.status(400).json({
        success: false,
        message: "image_base64 is required",
        data: null,
      });
    }

    const safeMime = ["image/jpeg", "image/png", "image/webp", "image/gif"].includes(
      mime_type
    )
      ? mime_type
      : "image/jpeg";

    try {
      const local = await callLocalAi(
        {
          image_base64,
          mime_type: safeMime,
        },
        LOCAL_AI_URL
      );

      const normalized = normalizeLocalResult(local);

      return res.json({
        success: true,
        source: local.source || "yolov8",
        data: normalized.data,
      });
    } catch (err) {
      return res.status(502).json({
        success: false,
        source: "local",
        message: `Local AI model service failed: ${err.message}`,
        data: null,
      });
    }
  } catch (err) {
    console.error("[/api/ai/analyze-image] Unexpected error:", err);
    next(err);
  }
});

router.post("/predict-price", async (req, res, next) => {
  try {
    const payload = buildPricePayload(req.body);

    try {
      const local = await callLocalAi(payload, LOCAL_PRICE_URL);

      const recommendedPrice = Number(
        local?.recommended_price ?? local?.data?.recommended_price
      );

      if (!Number.isFinite(recommendedPrice)) {
        throw new Error("Local AI returned an invalid price prediction");
      }

      const roundedPrice = Math.round(recommendedPrice * 100) / 100;

      return res.json({
        success: true,
        source: "local",
        recommended_price: roundedPrice,
        data: {
          recommended_price: roundedPrice,
        },
      });
    } catch (err) {
      return res.status(502).json({
        success: false,
        source: "local",
        message: `Local price model service failed: ${err.message}`,
        data: null,
      });
    }
  } catch (err) {
    console.error("[/api/ai/predict-price] Unexpected error:", err);
    next(err);
  }
});

function buildPricePayload(body) {
  const requiredFields = [
    "Brand",
    "Category",
    "Color",
    "Size",
    "Material",
    "Gender",
    "Season",
    "Brand_Tier",
  ];

  const payload = {};

  for (const field of requiredFields) {
    const value = body?.[field];

    if (typeof value !== "string" || value.trim() === "") {
      const error = new Error(`${field} is required`);
      error.status = 400;
      throw error;
    }

    payload[field] = value.trim();
  }

  return payload;
}

function normalizeLocalResult(local) {
  if (local?.success !== true || !local.data) {
    throw new Error(local?.message || "Local AI returned an invalid response");
  }

  const data = local.data;

  const confidence =
    typeof data.confidence === "number"
      ? data.confidence
      : Number(data.confidence);

  const category = normalizeCategory(data.category);

  return {
    confidence: Number.isFinite(confidence) ? confidence : 0,
    data: {
      name: String(data.name || data.title || "").trim(),
      description: String(data.description || "").trim(),
      category,
      tags: Array.isArray(data.tags)
        ? data.tags.map((tag) => String(tag).trim()).filter(Boolean)
        : [],
      estimated_price:
        typeof data.estimated_price === "number" ? data.estimated_price : null,
      confidence: Number.isFinite(confidence) ? confidence : 0,
      model_category: category,
      detections: Array.isArray(data.detections) ? data.detections : [],
    },
  };
}

function normalizeCategory(category) {
  return String(category || "").trim() || "unknown";
}

function callLocalAi(payload, targetUrl) {
  const body = JSON.stringify(payload);
  const url = new URL(targetUrl);
  const transport = url.protocol === "https:" ? https : http;

  return new Promise((resolve, reject) => {
    const req = transport.request(
      {
        hostname: url.hostname,
        port: url.port || (url.protocol === "https:" ? 443 : 80),
        path: url.pathname + url.search,
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "Content-Length": Buffer.byteLength(body),
        },
      },
      (response) => {
        let data = "";

        response.on("data", (chunk) => {
          data += chunk;
        });

        response.on("end", () => {
          try {
            const parsed = JSON.parse(data || "{}");

            if (response.statusCode < 200 || response.statusCode >= 300) {
              reject(
                new Error(
                  parsed?.detail ||
                    parsed?.message ||
                    `Local AI HTTP ${response.statusCode}`
                )
              );
              return;
            }

            resolve(parsed);
          } catch {
            reject(new Error("Failed to parse local AI response"));
          }
        });
      }
    );

    req.on("error", reject);

    req.setTimeout(LOCAL_AI_TIMEOUT_MS, () => {
      req.destroy(new Error("Local AI request timed out"));
    });

    req.write(body);
    req.end();
  });
}

module.exports = router;