const express = require("express");
const { supabase, supabaseAuth } = require("../supabaseClient");

const router = express.Router();

// ─── LOGIN ───────────────────────────────────────────────────────────────────
router.post("/login", async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: "Email and password are required",
        data: null,
      });
    }

    const { data, error } = await supabaseAuth.auth.signInWithPassword({
      email: email.trim(),
      password,
    });

    if (error) {
      return res.status(400).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("*")
      .eq("id", data.user.id)
      .maybeSingle();

    if (profileError) {
      return res.status(500).json({
        success: false,
        message: profileError.message,
        data: null,
      });
    }

    if (!profile) {
      return res.status(404).json({
        success: false,
        message: "Profile not found",
        data: null,
      });
    }

    if (profile.role !== "admin") {
      return res.status(403).json({
        success: false,
        message: "Access denied (not admin)",
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Login success",
      data: {
        user: data.user,
        profile,
        session: data.session,
      },
    });
  } catch (err) {
    console.error("[/api/auth/login] Unexpected error:", err);
    next(err);
  }
});

// ─── FORGOT PASSWORD ─────────────────────────────────────────────────────────
router.post("/forgot-password", async (req, res, next) => {
  try {
    const { email } = req.body;

    if (!email || !email.trim()) {
      return res.status(400).json({
        success: false,
        message: "Email is required",
        data: null,
      });
    }

    const emailRegex = /^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$/;

    if (!emailRegex.test(email.trim())) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
        data: null,
      });
    }

    const { error } = await supabaseAuth.auth.resetPasswordForEmail(
      email.trim(),
      {
        redirectTo: `${
          process.env.SUPABASE_RESET_URL || "http://localhost:3000"
        }/reset-password`,
      }
    );

    if (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "If an account with that email exists, we've sent a reset link.",
      data: null,
    });
  } catch (err) {
    console.error("[/api/auth/forgot-password] Unexpected error:", err);
    next(err);
  }
});

// ─── RESET PASSWORD ──────────────────────────────────────────────────────────
router.post("/reset-password", async (req, res, next) => {
  try {
    const { access_token, refresh_token, new_password } = req.body;

    if (!access_token || !access_token.trim()) {
      return res.status(400).json({
        success: false,
        message: "Access token is required",
        data: null,
      });
    }

    if (!new_password || new_password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "Password is required and must be at least 6 characters",
        data: null,
      });
    }

    const { error: sessionError } = await supabaseAuth.auth.setSession({
      access_token,
      refresh_token: refresh_token || "",
    });

    if (sessionError) {
      return res.status(401).json({
        success: false,
        message: "Invalid or expired reset token",
        data: null,
      });
    }

    const { error } = await supabaseAuth.auth.updateUser({
      password: new_password,
    });

    if (error) {
      return res.status(500).json({
        success: false,
        message: error.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Password updated successfully",
      data: null,
    });
  } catch (err) {
    console.error("[/api/auth/reset-password] Unexpected error:", err);
    next(err);
  }
});

// ─── UPDATE EMAIL ────────────────────────────────────────────────────────────
router.put("/update-email", async (req, res, next) => {
  try {
    const { user_id, new_email } = req.body;

    if (!user_id || !user_id.trim()) {
      return res.status(400).json({
        success: false,
        message: "User ID is required",
        data: null,
      });
    }

    if (!new_email || !new_email.trim()) {
      return res.status(400).json({
        success: false,
        message: "New email is required",
        data: null,
      });
    }

    const emailRegex = /^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$/;

    if (!emailRegex.test(new_email.trim())) {
      return res.status(400).json({
        success: false,
        message: "Invalid email format",
        data: null,
      });
    }

    const { error: authError } =
      await supabaseAuth.auth.admin.updateUserById(user_id, {
        email: new_email.trim(),
      });

    if (authError) {
      return res.status(500).json({
        success: false,
        message: authError.message,
        data: null,
      });
    }

    const { error: profileError } = await supabase
      .from("profiles")
      .update({ email: new_email.trim() })
      .eq("id", user_id);

    if (profileError) {
      return res.status(500).json({
        success: false,
        message: profileError.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Email updated successfully",
      data: null,
    });
  } catch (err) {
    console.error("[/api/auth/update-email] Unexpected error:", err);
    next(err);
  }
});

// ─── UPDATE PASSWORD ─────────────────────────────────────────────────────────
router.put("/update-password", async (req, res, next) => {
  try {
    const { user_id, current_password, new_password } = req.body;

    if (!user_id || !user_id.trim()) {
      return res.status(400).json({
        success: false,
        message: "User ID is required",
        data: null,
      });
    }

    if (!new_password || new_password.length < 6) {
      return res.status(400).json({
        success: false,
        message: "New password must be at least 6 characters",
        data: null,
      });
    }

    if (current_password) {
      const { data: userData, error: getUserError } =
        await supabaseAuth.auth.admin.getUserById(user_id);

      if (getUserError || !userData?.user?.email) {
        return res.status(404).json({
          success: false,
          message: "User not found",
          data: null,
        });
      }

      const { error: signInError } =
        await supabaseAuth.auth.signInWithPassword({
          email: userData.user.email,
          password: current_password,
        });

      if (signInError) {
        return res.status(401).json({
          success: false,
          message: "Current password is incorrect",
          data: null,
        });
      }
    }

    const { error: updateError } =
      await supabaseAuth.auth.admin.updateUserById(user_id, {
        password: new_password,
      });

    if (updateError) {
      return res.status(500).json({
        success: false,
        message: updateError.message,
        data: null,
      });
    }

    res.json({
      success: true,
      message: "Password updated successfully",
      data: null,
    });
  } catch (err) {
    console.error("[/api/auth/update-password] Unexpected error:", err);
    next(err);
  }
});

module.exports = router;