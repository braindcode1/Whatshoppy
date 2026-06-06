const { supabase } = require("./supabaseClient");

async function check() {
  console.log("Listing auth users...");
  const { data: { users }, error } = await supabase.auth.admin.listUsers();
  if (error) {
    console.error("Error listing users:", error.message);
  } else {
    console.log("Auth users:");
    users.forEach(u => {
      console.log(`- ID: ${u.id}, Email: ${u.email}`);
    });
  }
}

check();
