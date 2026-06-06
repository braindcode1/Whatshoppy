const { supabase } = require("./supabaseClient");

async function check() {
  console.log("Checking categories table structure...");
  const { data: catData, error: catError } = await supabase.from("categories").select("*").limit(1);
  console.log("Categories schema/data sample:", catData, catError?.message);

  console.log("\nChecking business_settings table existence/structure...");
  const { data: bsData, error: bsError } = await supabase.from("business_settings").select("*").limit(1);
  console.log("Business Settings schema/data sample:", bsData, bsError?.message);

  console.log("\nChecking products with user_id...");
  const { data: prodData, error: prodError } = await supabase.from("products").select("*").eq("user_id", "a0fadc0d-9a67-43a4-9581-d10c5297e19e").limit(5);
  console.log("Products for target user:", prodData, prodError?.message);

  console.log("\nChecking orders with user_id...");
  const { data: ordData, error: ordError } = await supabase.from("orders").select("*").eq("user_id", "a0fadc0d-9a67-43a4-9581-d10c5297e19e").limit(5);
  console.log("Orders for target user:", ordData, ordError?.message);
}

check();
