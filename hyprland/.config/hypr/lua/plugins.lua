-- GloView — macOS Mission Control-style overview
-- Nord palette (matches hyprtoolkit.conf)
-- Colors: 0xAARRGGBB
hl.config({
    plugin = {
        gloview = {
            -- Layout / main area
            layout           = "rows",
            gap              = 34,
            padding          = 80,
            padding_top      = 40,
            padding_bottom   = 70,
            max_scale        = 1.0,
            duration         = 360,
            preview_round    = 12,
            blur             = 1.0,

            -- Workspace strip
            anchor           = "top",
            strip_height     = 150,
            strip_offset     = 0,
            strip_margin     = 22,
            strip_gap        = 18,
            strip_card_round = 10,

            -- Nord-themed colors (0xAARRGGBB)
            backdrop_color      = 0xD02E3440,  -- nord0, 82% alpha
            strip_band_color    = 0x303B4252,  -- nord1, 19% alpha
            strip_card_color    = 0x403B4252,  -- nord1, 25% alpha
            strip_active_color  = 0x4088C0D0,  -- nord8, 25% alpha (frost blue)
            strip_active_border = 0xFF88C0D0,  -- nord8 (frost blue)
            strip_hover_border  = 0x8088C0D0,  -- nord8, 50% alpha
            strip_plus_color    = 0xFFA3BE8C,  -- nord14 (aurora green)
            shadow_color        = 0x70000000,  -- black, 44% alpha
            hover_border        = 0x8088C0D0,  -- nord8, 50% alpha
            close_button_color  = 0xE6BF616A,  -- nord11 (aurora red)
            select_border       = 0xFF88C0D0,  -- nord8 (frost blue)
            select_border_size  = 3,

            -- Input / keyboard navigation
            focus_follows_mouse       = 1,
            scroll_switches_workspace = 1,
            passthrough_keys          = 1,
            exit_on_click             = 1,
            debug_logs                = 0,

            -- Navigation keys (defaults)
            key_close          = "escape",
            key_next_workspace = "tab",
            key_prev_workspace = "shift+tab",
            key_activate       = "enter",
            key_close_window   = "d",
            key_left           = "left",
            key_right          = "right",
            key_up             = "up",
            key_down           = "down",
            key_desktop        = "shift",
            key_all_workspaces = "a",
            key_workspace      = "1,2,3,4,5,6,7,8,9,0",

            -- Workspace scope
            show_all_workspaces     = 0,
            show_empty              = 1,
            show_special            = 0,
            strip_all_card          = 0,
            switch_on_drop          = 0,
            drag_to_swap            = 1,
            exit_on_switch          = 0,
            switch_on_new_workspace = 1,

            -- Bar / layer-shell hiding
            hide_top_layers     = 0,
            hide_overlay_layers = 0,
            above_namespaces    = "",
        },
    },
})
