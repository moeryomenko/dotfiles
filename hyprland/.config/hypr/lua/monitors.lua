hl.monitor({ output = "DP-1", mode = "preferred", position = "0x0", scale = "auto" })
hl.monitor({ output = "DP-2", mode = "preferred", position = "0x-1440", scale = "auto" })
hl.monitor({ output = "HDMI-A-1", mode = "1280x720", position = "-1280x0", scale = "auto" })

hl.workspace_rule({ workspace = 1, monitor = "DP-1" })
hl.workspace_rule({ workspace = 2, monitor = "DP-2" })
hl.workspace_rule({ workspace = 10, monitor = "HDMI-A-1" })
