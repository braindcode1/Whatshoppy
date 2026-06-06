const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

const VALID_STATUSES = ["Pending", "Processing", "Shipped", "Delivered", "Cancelled"];

// GET /api/orders?user_id=...
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
      .from("orders")
      .select(`
        id,
        user_id,
        client_id,
        order_number,
        items_count,
        total,
        status,
        placed_at,
        created_at,
        client:client_id (
          id,
          name,
          phone,
          address
        )
      `)
      .eq("user_id", user_id)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("[orders GET] Supabase error:", error.message);
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Orders fetched successfully",
      data: data || [],
    });
  } catch (err) {
    console.error("[/api/orders GET] Unexpected error:", err);
    next(err);
  }
});

// GET /api/orders/:id/items?user_id=...
router.get("/:id/items", async (req, res, next) => {
  try {
    const { id } = req.params;
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: "user_id is required",
        data: null,
      });
    }

    // Verify the order belongs to this user before returning its items
    const { data: order, error: orderError } = await supabase
      .from("orders")
      .select("id")
      .eq("id", id)
      .maybeSingle();

    if (orderError) {
      console.error("[orders/:id/items] order check error:", orderError.message);
      return res.status(500).json({
        success: false,
        message: orderError.message,
        data: null,
      });
    }

    if (!order) {
      return res.status(404).json({
        success: false,
        message: "Order not found or access denied",
        data: null,
      });
    }

    const { data, error } = await supabase
      .from("order_line_items")
      .select("*")
      .eq("order_id", id)
      .order("id", { ascending: true });

    if (error) {
      console.error("[orders/:id/items] line items error:", error.message);
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Line items fetched successfully",
      data: data || [],
    });
  } catch (err) {
    console.error("[/api/orders/:id/items] Unexpected error:", err);
    next(err);
  }
});

// PUT /api/orders/:id/status
router.put("/:id/status", async (req, res, next) => {
  try {
    const { id } = req.params;
    const { status, user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: "user_id is required",
        data: null,
      });
    }

    if (!status || !VALID_STATUSES.includes(status)) {
      return res.status(400).json({
        success: false,
        message: `status must be one of: ${VALID_STATUSES.join(", ")}`,
        data: null,
      });
    }

    const { data, error } = await supabase
      .from("orders")
      .update({ status })
      .eq("id", id)
      .eq("user_id", user_id)
      .select()
      .maybeSingle();

    if (error) {
      console.error("[orders PUT status] Supabase error:", error.message);
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    if (!data) {
      return res.status(404).json({
        success: false,
        message: "Order not found or access denied",
        data: null,
      });
    }

    res.json({ success: true, message: "Order status updated", data });
  } catch (err) {
    console.error("[/api/orders/:id/status] Unexpected error:", err);
    next(err);
  }
});

module.exports = router;
