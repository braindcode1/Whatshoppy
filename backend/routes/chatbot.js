const express = require("express");
const https = require("https");

const router = express.Router();

const GEMINI_MODEL = process.env.GEMINI_MODEL || "gemini-1.5-flash";
const GEMINI_ENDPOINT = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const SYSTEM_PROMPT = `
You are the WhatShoppy AI Assistant.
Help users navigate and use the WhatShoppy app.

App structure:
- Home/Dashboard: revenue, pending orders, clients, orders, products, quick actions.
- Clients: list/search clients, open client profile.
- Orders: list/search orders, open order details, change status.
- Stock/Products: list/search products, add/edit/delete products.
- Add Product: product name, SKU, category, description, price, stock, image AI analysis.
- Settings: email, password, business name, WhatsApp number, sign out.
- Inbox: client messages.

Rules:
- Always answer in English unless the user clearly writes in French or Arabic.
- Be short, clear, and helpful.
- Give steps when the user asks how to do something.
- Never expose technical API errors to the user.
`;

router.post("/", async (req, res) => {
  try {
    const { message, history } = req.body;
    const apiKey = process.env.GEMINI_API_KEY;

    if (!message || typeof message !== "string" || !message.trim()) {
      return res.status(400).json({
        success: false,
        message: "message is required",
        data: null,
      });
    }

    const userMessage = message.trim();

    if (!apiKey || !apiKey.trim()) {
      return res.json({
        success: true,
        fallback: true,
        reply: getLocalReply(userMessage),
      });
    }

    try {
      const contents = [];

      if (Array.isArray(history)) {
        for (const msg of history.slice(-8)) {
          if (!msg || !msg.text) continue;

          contents.push({
            role: msg.role === "user" ? "user" : "model",
            parts: [{ text: String(msg.text) }],
          });
        }
      }

      contents.push({
        role: "user",
        parts: [{ text: userMessage }],
      });

      const body = JSON.stringify({
        system_instruction: {
          parts: [{ text: SYSTEM_PROMPT }],
        },
        contents,
        generationConfig: {
          temperature: 0.5,
          topP: 0.9,
          maxOutputTokens: 350,
        },
      });

      const geminiResponse = await callGemini(apiKey, body);

      const reply =
        geminiResponse &&
        geminiResponse.candidates &&
        geminiResponse.candidates[0] &&
        geminiResponse.candidates[0].content &&
        geminiResponse.candidates[0].content.parts &&
        geminiResponse.candidates[0].content.parts[0] &&
        geminiResponse.candidates[0].content.parts[0].text
          ? geminiResponse.candidates[0].content.parts[0].text.trim()
          : "";

      return res.json({
        success: true,
        fallback: false,
        reply: reply || getLocalReply(userMessage),
      });
    } catch (aiError) {
      console.error("[Chatbot Gemini Error]", aiError.message);

      return res.json({
        success: true,
        fallback: true,
        reply: getLocalReply(userMessage),
      });
    }
  } catch (err) {
    console.error("[/api/chatbot] Error:", err.message);

    return res.json({
      success: true,
      fallback: true,
      reply:
        "I'm available, but I had a small issue. Please try asking your question again.",
    });
  }
});

function detectLanguage(message) {
  const text = message.toLowerCase();

  const frenchWords = [
    "bonjour",
    "salut",
    "comment",
    "produit",
    "commande",
    "client",
    "paramètre",
    "parametres",
    "mot de passe",
    "où",
    "ou trouver",
    "ajouter",
    "changer",
    "statut",
  ];

  const arabicRegex = /[\u0600-\u06FF]/;

  if (arabicRegex.test(text)) return "ar";
  if (frenchWords.some((word) => text.includes(word))) return "fr";

  return "en";
}

function getLocalReply(message) {
  const text = message.toLowerCase();
  const lang = detectLanguage(message);

  const isProductQuestion =
    text.includes("add product") ||
    text.includes("product") ||
    text.includes("ajouter") ||
    text.includes("produit");

  const isOrderQuestion =
    text.includes("order") ||
    text.includes("orders") ||
    text.includes("status") ||
    text.includes("commande") ||
    text.includes("statut");

  const isClientQuestion =
    text.includes("client") ||
    text.includes("clients") ||
    text.includes("customer") ||
    text.includes("customers");

  const isDashboardQuestion =
    text.includes("dashboard") ||
    text.includes("home") ||
    text.includes("revenue") ||
    text.includes("accueil");

  const isSettingsQuestion =
    text.includes("settings") ||
    text.includes("password") ||
    text.includes("email") ||
    text.includes("param") ||
    text.includes("mot de passe");

  const isAiQuestion =
    text.includes("ai") ||
    text.includes("analysis") ||
    text.includes("analyze") ||
    text.includes("analyse") ||
    text.includes("image");

  if (lang === "fr") {
    if (isProductQuestion) {
      return `Pour ajouter un produit :

1. Va dans l’onglet Stock.
2. Clique sur Add Product.
3. Remplis le nom, la catégorie, le prix et le stock.
4. Clique sur Add Product.

Tu peux aussi créer une nouvelle catégorie avec le bouton +.`;
    }

    if (isOrderQuestion) {
      return `Pour changer le statut d’une commande :

1. Va dans Orders.
2. Ouvre la commande.
3. Choisis le nouveau statut.
4. Sauvegarde la modification.

Statuts disponibles : Pending, Processing, Shipped, Delivered, Cancelled.`;
    }

    if (isClientQuestion) {
      return `Pour gérer les clients :

1. Va dans l’onglet Clients.
2. Utilise la barre de recherche.
3. Clique sur un client pour voir son profil et ses commandes.`;
    }

    if (isDashboardQuestion) {
      return `Le Dashboard affiche une vue globale de ton business :

- revenus
- commandes en attente
- clients
- produits
- accès rapide aux actions importantes`;
    }

    if (isSettingsQuestion) {
      return `Dans Settings, tu peux modifier :

- email
- mot de passe
- nom du business
- numéro WhatsApp
- paramètres du compte`;
    }

    if (isAiQuestion) {
      return `L’analyse AI t’aide à remplir automatiquement un produit à partir d’une image.

1. Va dans Add Product.
2. Ajoute une image du produit.
3. Lance l’analyse AI.
4. Vérifie les champs générés.
5. Sauvegarde le produit.`;
    }

    return `Je peux t’aider à utiliser WhatShoppy.

Tu peux me demander :
- Comment ajouter un produit ?
- Comment changer le statut d’une commande ?
- Où trouver mes clients ?
- Comment modifier mes paramètres ?`;
  }

  if (lang === "ar") {
    return `I can help you use WhatShoppy. Please ask me about products, orders, clients, dashboard, settings, or AI product analysis.`;
  }

  if (isProductQuestion) {
    return `To add a product:

1. Go to the Stock tab.
2. Tap Add Product.
3. Fill in the product name, category, price, and stock.
4. Tap Add Product to save it.

You can also create a custom category using the + button next to Category.`;
  }

  if (isOrderQuestion) {
    return `To change an order status:

1. Go to the Orders tab.
2. Open the order.
3. Select the new status.
4. Save the change.

Available statuses: Pending, Processing, Shipped, Delivered, Cancelled.`;
  }

  if (isClientQuestion) {
    return `To manage clients:

1. Go to the Clients tab.
2. Use the search bar to find a client.
3. Tap a client to view their profile and order history.`;
  }

  if (isDashboardQuestion) {
    return `The Dashboard gives you a quick overview of your business:

- revenue
- pending orders
- clients
- products
- quick actions`;
  }

  if (isSettingsQuestion) {
    return `In Settings, you can update:

- email
- password
- business name
- WhatsApp number
- account settings`;
  }

  if (isAiQuestion) {
    return `AI analysis helps you create a product from an image.

1. Go to Add Product.
2. Upload or select a product image.
3. Start the AI analysis.
4. Review the generated product name, description, category, and price.
5. Save the product.`;
  }

  return `I can help you use WhatShoppy.

You can ask me things like:
- How do I add a product?
- How does AI analysis work?
- How do I change an order status?
- Where can I find my clients?
- How do I update my settings?`;
}

function callGemini(apiKey, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(`${GEMINI_ENDPOINT}?key=${apiKey}`);

    const options = {
      hostname: url.hostname,
      path: url.pathname + url.search,
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    };

    const request = https.request(options, (response) => {
      let data = "";

      response.on("data", (chunk) => {
        data += chunk;
      });

      response.on("end", () => {
        try {
          const parsed = JSON.parse(data);

          if (response.statusCode !== 200) {
            return reject(
              new Error(
                parsed &&
                parsed.error &&
                parsed.error.message
                  ? parsed.error.message
                  : `Gemini HTTP ${response.statusCode}`
              )
            );
          }

          return resolve(parsed);
        } catch (error) {
          return reject(new Error("Failed to parse Gemini response"));
        }
      });
    });

    request.on("error", reject);

    request.setTimeout(15000, () => {
      request.destroy(new Error("Gemini request timed out"));
    });

    request.write(body);
    request.end();
  });
}

module.exports = router;