const express = require("express");
const {supabase} = require("../supabaseClient");

const router = express.Router();

// GET /api/messages?user_id=xxx
router.get("/", async (req, res) => {
  try {
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const { data, error } = await supabase
      .from("conversations")
      .select(`
        *,
        client:client_id (id, name, phone, email, address)
      `)
      .eq("user_id", user_id)
      .order("updated_at", { ascending: false });

    if (error) {
      console.error("Fetch conversations error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Conversations fetched successfully", data: data });
  } catch (err) {
    console.error("Conversations route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

// GET /api/messages/:id?user_id=xxx
router.get("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.query;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    // Verify conversation belongs to user
    const { data: convData, error: convError } = await supabase
      .from("conversations")
      .select("id")
      .eq("id", id)
      .eq("user_id", user_id)
      .maybeSingle();

    if (convError || !convData) {
      return res.status(404).json({ success: false, message: "Conversation not found or access denied", data: null });
    }

    const { data, error } = await supabase
      .from("messages")
      .select("*")
      .eq("conversation_id", id)
      .order("created_at", { ascending: true });

    if (error) {
      console.error("Fetch messages error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    // Mark as read
    await supabase.from("conversations").update({ unread_count: 0 }).eq("id", id);

    res.json({ success: true, message: "Messages fetched successfully", data: data });
  } catch (err) {
    console.error("Messages route error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

// POST /api/messages/:id
router.post("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id, text } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    if (!text || !text.trim()) {
      return res.status(400).json({ success: false, message: "Message text is required", data: null });
    }

    // Verify conversation belongs to user
    const { data: convData, error: convError } = await supabase
      .from("conversations")
      .select("id")
      .eq("id", id)
      .eq("user_id", user_id)
      .maybeSingle();

    if (convError || !convData) {
      return res.status(404).json({ success: false, message: "Conversation not found or access denied", data: null });
    }

    const { data, error } = await supabase
      .from("messages")
      .insert([
        {
          conversation_id: id,
          sender_type: "business",
          text: text.trim(),
        }
      ])
      .select()
      .maybeSingle();

    if (error) {
      console.error("Insert message error:", error.message);
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    // Update conversation last_message and updated_at
    await supabase
      .from("conversations")
      .update({ last_message: text.trim() })
      .eq("id", id);

    res.status(201).json({ success: true, message: "Message sent successfully", data: data });
  } catch (err) {
    console.error("Send message error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

// PUT /api/messages/:id/read — Mark a conversation as read
router.put("/:id/read", async (req, res) => {
  try {
    const { id } = req.params;
    const { user_id } = req.body;

    if (!user_id) {
      return res.status(400).json({ success: false, message: "user_id is required", data: null });
    }

    const { error } = await supabase
      .from("conversations")
      .update({ unread_count: 0 })
      .eq("id", id)
      .eq("user_id", user_id);

    if (error) {
      return res.status(500).json({ success: false, message: error.message, data: null });
    }

    res.json({ success: true, message: "Marked as read", data: null });
  } catch (err) {
    console.error("Mark as read error:", err.message);
    res.status(500).json({ success: false, message: "Internal server error", data: null });
  }
});

module.exports = router;
