const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

router.get("/", async (req, res) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const { data, error } = await supabase
      .from("products")
      .select("*")
      .eq("user_id", user_id)
      .order("created_at", { ascending: false });

    if (error) {
      console.error("Fetch products error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Products fetched successfully", data: data });
  } catch (err) {
    console.error("Products route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

router.post("/", async (req, res) => {
  try {
    const { name, sku, category, price, stock, description, user_id } = req.body;
    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: "Product name is required", data: null });
    }

    if (price === undefined || price === null || isNaN(parseFloat(price)) || parseFloat(price) < 0) {
      return res.status(400).json({ success: false, message: "Valid price is required", data: null });
    }

    if (stock === undefined || stock === null || isNaN(parseInt(stock)) || parseInt(stock) < 0) {
      return res.status(400).json({ success: false, message: "Valid stock quantity is required", data: null });
    }

    const productData = {
      user_id: user_id,
      name: name.trim(),
      sku: sku?.trim() || `PROD-${Date.now()}`,
      category: category || "General",
      price: parseFloat(price),
      stock: parseInt(stock),
      description: description?.trim() || "",
    };

    const { data, error } = await supabase
      .from("products")
      .insert([productData])
      .select()
      .maybeSingle();

    if (error) {
      console.error("Insert product error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.status(201).json({
      success: true,
      message: "Product added successfully",
      data: data,
    });

  } catch (err) {
    console.error("Add product route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { name, sku, category, price, stock, description, user_id } = req.body;
    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const updateData = {};

    if (name !== undefined) updateData.name = name.trim();
    if (sku !== undefined) updateData.sku = sku.trim();
    if (category !== undefined) updateData.category = category;

    if (price !== undefined) {
      if (isNaN(parseFloat(price)) || parseFloat(price) < 0) {
        return res.status(400).json({ success: false, message: "Valid price is required", data: null });
      }
      updateData.price = parseFloat(price);
    }

    if (stock !== undefined) {
      if (isNaN(parseInt(stock)) || parseInt(stock) < 0) {
        return res.status(400).json({ success: false, message: "Valid stock quantity is required", data: null });
      }
      updateData.stock = parseInt(stock);
    }

    if (description !== undefined) {
      updateData.description = description.trim();
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({ success: false, message: "No fields to update", data: null });
    }

    const { data, error } = await supabase
      .from("products")
      .update(updateData)
      .eq("id", id)
      .eq("user_id", user_id) 
      .select()
      .maybeSingle();

    if (error) {
      console.error("Update product error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    if (!data) {
      return res.status(404).json({ success: false, message: "Product not found or access denied", data: null });
    }

    res.json({
      success: true,
      message: "Product updated successfully",
      data: data,
    });

  } catch (err) {
    console.error("Update product route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

router.delete("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const { error } = await supabase
      .from("products")
      .delete()
      .eq("id", id)
      .eq("user_id", user_id); 

    if (error) {
      console.error("Delete product error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Product deleted successfully", data: null });

  } catch (err) {
    console.error("Delete product route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

module.exports = router;
