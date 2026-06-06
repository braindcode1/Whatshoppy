const express = require("express");
const { supabase } = require("../supabaseClient");

const router = express.Router();

const DEFAULT_DL_CLASSES = [
  "Blazer",
  "Pants",
  "Shorts",
  "Dress",
  "Hoodie",
  "Jacket",
  "Denim Jacket",
  "Sports Jacket",
  "Jeans",
  "T-Shirt",
  "Shirt",
  "Coat",
  "Polo Shirt",
  "Skirt",
  "Sweater"
];

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

    let { data, error } = await supabase
      .from("categories")
      .select("*")
      .eq("user_id", user_id)
      .order("nom", { ascending: true });

    if (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    // Automatically seed any missing deep learning classes for this user
    const existingNames = new Set((data || []).map(c => c.nom.toLowerCase()));
    const missingClasses = DEFAULT_DL_CLASSES.filter(name => !existingNames.has(name.toLowerCase()));

    if (missingClasses.length > 0) {
      const inserts = missingClasses.map(name => ({
        nom: name,
        user_id,
      }));

      const { data: seeded, error: seedError } = await supabase
        .from("categories")
        .insert(inserts)
        .select();

      if (!seedError && seeded) {
        data = [...(data || []), ...seeded];
        data.sort((a, b) => a.nom.localeCompare(b.nom));
      } else if (seedError) {
        console.error("Failed to seed categories:", seedError.message);
      }
    }

    res.json({ success: true, data });
  } catch (err) {
    next(err);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const { nom, user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({
        success: false,
        message: "user_id is required",
        data: null,
      });
    }

    if (!nom || !nom.trim()) {
      return res.status(400).json({
        success: false,
        message: "nom is required",
        data: null,
      });
    }

    const categoryName = nom.trim();

    const { data: existing, error: findError } = await supabase
      .from("categories")
      .select("*")
      .eq("user_id", user_id)
      .ilike("nom", categoryName)
      .maybeSingle();

    if (findError) {
      return res.status(500).json({
        success: false,
        message: findError.message,
        data: null,
      });
    }

    if (existing) {
      return res.json({
        success: true,
        message: "Category already exists",
        data: existing,
      });
    }

    const { data, error } = await supabase
      .from("categories")
      .insert([
        {
          nom: categoryName,
          user_id,
        },
      ])
      .select()
      .maybeSingle();

    if (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.status(201).json({
      success: true,
      message: "Category added successfully",
      data,
    });
  } catch (err) {
    next(err);
  }
});

module.exports = router;