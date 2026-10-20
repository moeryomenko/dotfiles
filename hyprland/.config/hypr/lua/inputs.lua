hl.config({
  input = {
    kb_layout = "us,ru",
    kb_variant = "",
    kb_model = "",
    kb_options = "grp:alt_space_toggle",
    kb_rules = "",
    follow_mouse = 1,
    touchpad = {
      natural_scroll = true,
    },
    sensitivity = 0,
  },
  xwayland = {
    force_zero_scaling = true,
  },
})

hl.device({
  name = "epic-mouse-v1",
  sensitivity = -0.5,
})
