const { supabase } = require("./supabaseClient");

const HIGH_LEVEL_CATEGORIES = [
  "General",
  "Clothes",
  "Accessories",
  "Beauty",
  "Pantry",
  "Home"
];

const CLOTHING_SUBCATEGORIES = [
  "blazer", "pants", "shorts", "dress", "hoodie", "jacket", "denim jacket",
  "sports jacket", "jeans", "t-shirt", "shirt", "coat", "polo shirt", "skirt", "sweater",
  "clothes", "clothing"
];

async function runCleanup() {
  try {
    console.log("Starting DB Category Cleanup...");

    // 1. Fetch all products
    const { data: products, error: prodError } = await supabase
      .from("products")
      .select("id, name, category");

    if (prodError) {
      console.error("Error fetching products:", prodError);
      return;
    }

    console.log(`Fetched ${products.length} products. checking categories...`);

    for (const p of products) {
      const currentCat = (p.category || "").trim().toLowerCase();
      let targetCat = "General";

      if (CLOTHING_SUBCATEGORIES.includes(currentCat)) {
        targetCat = "Clothes";
      } else if (currentCat === "accessories") {
        targetCat = "Accessories";
      } else if (currentCat === "beauty") {
        targetCat = "Beauty";
      } else if (currentCat === "pantry") {
        targetCat = "Pantry";
      } else if (currentCat === "home") {
        targetCat = "Home";
      } else if (currentCat === "general") {
        targetCat = "General";
      }

      // If category needs update
      if (p.category !== targetCat) {
        console.log(`Updating product "${p.name}" (ID: ${p.id}): "${p.category}" -> "${targetCat}"`);
        const { error: updateError } = await supabase
          .from("products")
          .update({ category: targetCat })
          .eq("id", p.id);

        if (updateError) {
          console.error(`Failed to update product ${p.id}:`, updateError);
        }
      }
    }

    // 2. Fetch all categories currently in DB
    const { data: categories, error: catError } = await supabase
      .from("categories")
      .select("*");

    if (catError) {
      console.error("Error fetching categories:", catError);
      return;
    }

    console.log(`Fetched ${categories.length} category records.`);

    // Delete categories not in HIGH_LEVEL_CATEGORIES
    for (const cat of categories) {
      const isHighLevel = HIGH_LEVEL_CATEGORIES.some(
        hl => hl.toLowerCase() === cat.nom.toLowerCase()
      );

      if (!isHighLevel) {
        console.log(`Deleting category "${cat.nom}" (ID: ${cat.id})`);
        const { error: deleteError } = await supabase
          .from("categories")
          .delete()
          .eq("id", cat.id);

        if (deleteError) {
          console.error(`Failed to delete category "${cat.nom}":`, deleteError);
        }
      }
    }

    // 3. Ensure all HIGH_LEVEL_CATEGORIES exist in categories table
    const { data: remainingCats, error: refetchError } = await supabase
      .from("categories")
      .select("nom");

    if (refetchError) {
      console.error("Error refetching remaining categories:", refetchError);
      return;
    }

    const remainingNames = new Set(remainingCats.map(c => c.nom.toLowerCase()));

    for (const hl of HIGH_LEVEL_CATEGORIES) {
      if (!remainingNames.has(hl.toLowerCase())) {
        console.log(`Adding missing high-level category: "${hl}"`);
        const { error: insertError } = await supabase
          .from("categories")
          .insert([{ nom: hl }]);

        if (insertError) {
          console.error(`Failed to insert category "${hl}":`, insertError);
        }
      }
    }

    console.log("Database Category Cleanup completed successfully!");
  } catch (err) {
    console.error("Unexpected cleanup error:", err);
  }
}

runCleanup();
