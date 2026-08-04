---
description: Review the diff with tuicr, then fix all comments
---

Use the tuicr_review tool with action "launch" and args parsed from "$ARGUMENTS" to launch the interactive tuicr review overlay.
Pass the tuicr CLI flags through verbatim (for example -w for the working tree, -r main..HEAD for a range, pr 125 for a pull request, or --file <path> for a single file).
Wait for the annotations, then address each one with code changes.
After fixing everything, summarize what you changed.
