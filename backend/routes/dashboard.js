const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

router.get("/", async (req, res, next) => {
  try {
    const userId = req.query.user_id?.toString().trim();

    if (!userId) {
      return res.status(400).json({
        success: false,
        message: "user_id query parameter is required",
        data: null,
      });
    }

    const [productsResult, clientsResult, ordersResult] = await Promise.all([
      supabase.from("products").select("id").eq("user_id", userId),
      supabase.from("clients").select("id").eq("user_id", userId),
      supabase.from("orders").select("id, total, status").eq("user_id", userId),
    ]);

    if (productsResult.error) {
      console.error("[dashboard] products error:", productsResult.error.message);
      return res.status(500).json({
        success: false,
        message: productsResult.error.message,
        data: null,
      });
    }
    if (clientsResult.error) {
      console.error("[dashboard] clients error:", clientsResult.error.message);
      return res.status(500).json({
        success: false,
        message: clientsResult.error.message,
        data: null,
      });
    }
    if (ordersResult.error) {
      console.error("[dashboard] orders error:", ordersResult.error.message);
      return res.status(500).json({
        success: false,
        message: ordersResult.error.message,
        data: null,
      });
    }

    const orders = ordersResult.data || [];
    const totalRevenue = orders.reduce(
      (sum, o) => sum + (parseFloat(o.total) || 0),
      0
    );
    const pendingOrders = orders.filter(
      (o) => o.status?.toString().toLowerCase() === "pending"
    ).length;

    res.json({
      success: true,
      message: "Dashboard fetched successfully",
      data: {
        products_count: (productsResult.data || []).length,
        clients_count: (clientsResult.data || []).length,
        orders_count: orders.length,
        pending_orders: pendingOrders,
        total_revenue: parseFloat(totalRevenue.toFixed(2)),
      },
    });
  } catch (err) {
    console.error("[/api/dashboard] Unexpected error:", err);
    next(err);
  }
});

module.exports = router;
