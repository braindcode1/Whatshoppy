const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

router.get("/", async (req, res, next) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: "user_id is required",
        data: null,
      });
    }

    const { data, error } = await supabase
      .from("clients")
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("[clients GET] Supabase error:", error.message);
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.json({ success: true, message: "Clients fetched successfully", data: data || [] });
  } catch (err) {
    console.error("[/api/clients] Unexpected error:", err);
    next(err);
  }
});

module.exports = router;
