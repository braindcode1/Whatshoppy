const { supabase } = require("./supabaseClient");

async function run() {
  const targetUserId = "a0fadc0d-9a67-43a4-9581-d10c5297e19e";
  console.log(`Re-associating all user_id columns to ${targetUserId}...`);

  const tables = ["products", "orders", "clients", "categories", "conversations", "business_settings"];

  for (const table of tables) {
    try {
      // Fetch some rows to verify
      const { data: beforeRows } = await supabase.from(table).select("*").limit(1);
      if (!beforeRows) {
        console.log(`Table ${table} has no data or cannot be read.`);
        continue;
      }

      // Update all rows in this table to targetUserId
      const { data, error } = await supabase
        .from(table)
        .update({ user_id: targetUserId })
        .neq("id", "00000000-0000-0000-0000-000000000000"); // matches everything

      if (error) {
        console.error(`Error updating ${table}:`, error.message);
      } else {
        console.log(`Updated user_id to ${targetUserId} in table: ${table}`);
      }
    } catch (e) {
      console.error(`Exception updating ${table}:`, e.message);
    }
  }

  // Double check if business_settings has a setting for the targetUserId
  const { data: settings } = await supabase
    .from("business_settings")
    .select("*")
    .eq("user_id", targetUserId)
    .maybeSingle();

  if (!settings) {
    console.log("No business settings found for active user. Inserting default...");
    const { error: insertErr } = await supabase
      .from("business_settings")
      .insert({
        user_id: targetUserId,
        business_name: "WhatShoppy Store",
        whatsapp_number: "+21650123456"
      });
    if (insertErr) {
      console.error("Failed to insert default business settings:", insertErr.message);
    } else {
      console.log("Default business settings inserted successfully.");
    }
  }

  console.log("Database update process completed.");
}

run();
