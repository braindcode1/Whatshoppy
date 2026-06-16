const { supabase } = require("./supabaseClient");

async function checkDb() {
  try {
    const { data: categories, error: catError } = await supabase
      .from("categories")
      .select("*");
    
    if (catError) {
      console.error("Error fetching categories:", catError);
      return;
    }
    
    console.log("Current categories in database:", categories);

    const { data: products, error: prodError } = await supabase
      .from("products")
      .select("id, name, category");

    if (prodError) {
      console.error("Error fetching products:", prodError);
      return;
    }

    console.log("Current products category field:", products);
  } catch (err) {
    console.error("Unexpected error:", err);
  }
}

checkDb();
