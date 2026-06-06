const { supabase } = require("./supabaseClient");

async function check() {
  const { data, error } = await supabase.from("category").select("*").limit(5);
  console.log("Category table:", data, error?.message);

  const { data: d2, error: e2 } = await supabase.from("categories").select("*").limit(5);
  console.log("Categories table:", d2, e2?.message);
}

check();
