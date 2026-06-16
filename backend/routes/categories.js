const express = require("express");
const { supabase } = require("../supabaseClient");

const router = express.Router();

const DEFAULT_DL_CLASSES = [
  "General",
  "Clothes",
  "Accessories",
  "Beauty",
  "Pantry",
  "Home"
];

let hasUserIdColumn = null;

async function checkCategoriesSchema() {
  if (hasUserIdColumn !== null) return hasUserIdColumn;
  try {
    const { error } = await supabase.from("categories").select("user_id").limit(1);
    if (error && error.message.includes("column") && error.message.includes("does not exist")) {
      hasUserIdColumn = false;
    } else {
      hasUserIdColumn = true;
    }
  } catch (e) {
    hasUserIdColumn = false;
  }
  return hasUserIdColumn;
}

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

    const hasUser = await checkCategoriesSchema();

    let query = supabase.from("categories").select("*");
    if (hasUser) {
      query = query.eq("user_id", user_id);
    }

    let { data, error } = await query.order("nom", { ascending: true });

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
      const inserts = missingClasses.map(name => {
        const item = { nom: name };
        if (hasUser) {
          item.user_id = user_id;
        }
        return item;
      });

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
    const hasUser = await checkCategoriesSchema();

    let query = supabase.from("categories").select("*");
    if (hasUser) {
      query = query.eq("user_id", user_id);
    }
    const { data: existing, error: findError } = await query
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

    const insertData = { nom: categoryName };
    if (hasUser) {
      insertData.user_id = user_id;
    }

    const { data, error } = await supabase
      .from("categories")
      .insert([insertData])
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