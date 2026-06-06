const { supabase } = require("./supabaseClient");

async function check() {
  console.log("Checking products...");
  const { data: products, error: pError } = await supabase.from("products").select("id, name, user_id").limit(5);
  console.log("Products:", products);
  console.log("Products Error:", pError);

  console.log("\nChecking orders...");
  const { data: orders, error: oError } = await supabase.from("orders").select("id, total, user_id").limit(5);
  console.log("Orders:", orders);
  
  console.log("\nChecking clients...");
  const { data: clients, error: cError } = await supabase.from("clients").select("id, name, user_id").limit(5);
  console.log("Clients:", clients);

  console.log("\nChecking profiles...");
  const { data: profiles, error: prError } = await supabase.from("profiles").select("*");
  console.log("Profiles:", profiles);
  console.log("Profiles Error:", prError);
}

check();
