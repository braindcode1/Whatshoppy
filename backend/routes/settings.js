const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

// GET /api/settings/business?user_id=xxx
router.get("/business", async (req, res) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const { data, error } = await supabase
      .from("business_settings")
      .select("*")
      .eq("user_id", user_id)
      .maybeSingle();

    if (error) {
      console.error("Fetch business settings error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Settings fetched successfully", data: data || { business_name: "", whatsapp_number: "" } });
  } catch (err) {
    console.error("Settings route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

// PUT /api/settings/business
router.put("/business", async (req, res) => {
  try {
    const { user_id, business_name, whatsapp_number } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    if (!business_name || !business_name.trim()) {
      return res.status(400).json({ success: false, message: "business_name is required", data: null });
    }

    if (!whatsapp_number || !whatsapp_number.trim()) {
      return res.status(400).json({ success: false, message: "whatsapp_number is required", data: null });
    }

    // Upsert the business settings
    const { data, error } = await supabase
      .from("business_settings")
      .upsert(
        { 
          user_id, 
          business_name: business_name.trim(), 
          whatsapp_number: whatsapp_number.trim() 
        }, 
        { onConflict: 'user_id' }
      )
      .select()
      .maybeSingle();

    if (error) {
      console.error("Update business settings error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Settings updated successfully", data: data });
  } catch (err) {
    console.error("Settings route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

module.exports = router;
