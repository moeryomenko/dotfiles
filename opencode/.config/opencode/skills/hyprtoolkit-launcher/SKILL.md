---
name: hyprtoolkit-launcher
description: Build overlay launcher-style applications using the Hyprtoolkit library and wlr-layer-shell protocol
when_to_use: "When building a floating overlay UI (launcher, picker, popup, OSD) that must appear above all windows in Hyprland/Wayland, or when writing code that uses hyprtoolkit's CWindowBuilder with HT_WINDOW_LAYER. NOT for regular toplevel windows, XDG desktop apps, or non-Wayland environments."
allowed-tools: Read, Write, Grep, Glob, Bash
effort: medium
---

# Hyprtoolkit Launcher — Build Overlay UI Applications

> Use wlr-layer-shell at the OVERLAY level to render above everything, with a composable builder-pattern UI tree.

## Overview

This skill enables building launcher-style applications (like Hyprland's hyprlauncher) that float above all other windows. It covers the layer shell window setup, UI element tree construction with the builder pattern, keyboard/input handling, palette theming, and the daemon/IPC lifecycle pattern.

Derived from reverse-engineering `hyprlauncher`, a production launcher for Hyprland.

## When to Use

**Good for:**
- Application launchers (`dmenu`/`rofi` replacements)
- Clipboard managers, emoji pickers, calculator overlays
- OSD notifications, volume/brightness overlays
- Any transient popup that must render above fullscreen apps
- Custom widgets that need to float over the desktop

**Not for:**
- Regular application windows (use `HT_WINDOW_TOPLEVEL`)
- Tooltips or dropdown menus (use `HT_WINDOW_POPUP` with a parent)
- Lock screens (use `HT_WINDOW_LOCK_SURFACE`)
- Non-Wayland/X11 environments

## Required Dependencies

```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(deps REQUIRED IMPORTED_TARGET
    hyprtoolkit
    hyprutils>=0.10.2
    hyprlang           # for config (optional)
    hyprwire           # for IPC (optional)
    pixman-1 libdrm    # rendering deps
    fontconfig         # font handling
)
set(CMAKE_CXX_STANDARD 23)
target_link_libraries(app PkgConfig::deps)
```

Includes needed:
```cpp
#include <hyprtoolkit/core/Backend.hpp>
#include <hyprtoolkit/window/Window.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/Text.hpp>
#include <hyprtoolkit/element/Textbox.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
#include <hyprtoolkit/element/RowLayout.hpp>
#include <hyprtoolkit/element/ScrollArea.hpp>
#include <hyprtoolkit/element/Image.hpp>
#include <hyprtoolkit/element/Button.hpp>
#include <hyprtoolkit/element/Null.hpp>
#include <hyprtoolkit/palette/Palette.hpp>
#include <hyprtoolkit/types/FontTypes.hpp>
#include <hyprtoolkit/types/SizeType.hpp>
#include <hyprtoolkit/system/Icons.hpp>
#include <xkbcommon/xkbcommon-keysyms.h>
```

## Protocol

### Step 1: Create the Backend

One backend per process. It manages the event loop, outputs, palette, and icon system.

```cpp
auto backend = Hyprtoolkit::IBackend::create();
auto palette = backend->getPalette();
```

The backend is ref-counted via `CSharedPointer`. Hold it for the process lifetime.

> [Check] Backend created successfully

### Step 2: Build the Overlay Window

Use `CWindowBuilder` with `HT_WINDOW_LAYER` type and `layer(3)` for the overlay level.

```cpp
auto window = Hyprtoolkit::CWindowBuilder::begin()
    ->appClass("my-launcher")              // Wayland app_id
    ->type(Hyprtoolkit::HT_WINDOW_LAYER)   // layer shell, not toplevel
    ->preferredSize({400, 260})            // logical pixels
    ->anchor(1 | 2 | 4 | 8)               // all 4 edges → centered
    ->exclusiveZone(-1)                    // -1 = floating overlay, no space reservation
    ->layer(3)                             // 3 = OVERLAY (above everything)
    ->kbInteractive(1)                     // 1 = exclusive keyboard grab
    ->commence();
```

**Layer reference:**

| Layer | Type       | Stack Position                |
|-------|------------|-------------------------------|
| 0     | Background | Wallpaper, desktop background |
| 1     | Bottom     | Desktop icons                 |
| 2     | Top        | Panels, docks, taskbars       |
| **3** | **Overlay**| **Above all windows**         |

**Anchor bitmask:**

| Value | Edge  |
|-------|-------|
| 1     | Top   |
| 2     | Bottom|
| 4     | Left  |
| 8     | Right |

**`1|2|4|8 = 15`** anchors to all edges → compositor centers the window at preferred size.

**Exclusive zone semantics:**

| Value | Behavior                                |
|-------|-----------------------------------------|
| `-1`  | No space reservation — floating overlay  |
| `0`   | Occlude area but reserve no space       |
| `>0`  | Reserve N pixels (like a panel)         |

**Keyboard interactivity:**

| Value | Mode      | Effect                                |
|-------|-----------|---------------------------------------|
| 1     | Exclusive | Window captures all keyboard input    |
| 2     | None      | Window does not receive keyboard input|

> [Check] Window configured with HT_WINDOW_LAYER, layer(3), exclusiveZone(-1)
> [Check] Anchor set to 1|2|4|8 (or tailored for position)

### Step 3: Construct the UI Element Tree

Every element uses a **builder pattern**: `Builder::begin()` → chain config methods → `commence()`.

#### Element reference

| Element      | Builder Class         | Purpose                            | Key Methods                                                      |
|--------------|-----------------------|------------------------------------|------------------------------------------------------------------|
| Rectangle    | `CRectangleBuilder`   | Backgrounds, dividers, containers  | `color(fn)`, `borderColor(fn)`, `rounding(n)`, `borderThickness(n)` |
| Text         | `CTextBuilder`        | Labels, descriptions               | `text(s)`, `color(fn)`, `fontSize()`, `align()`, `fontFamily(s)` |
| Textbox      | `CTextboxBuilder`     | Search input                       | `placeholder(s)`, `onTextEdited(fn)`, `multiline(b)`, `defaultText(s)` |
| Button       | `CButtonBuilder`      | Clickable buttons                  | `label(s)`, `onMainClick(fn)`, `onRightClick(fn)`, `noBorder(b)` |
| Image        | `CImageBuilder`       | Icons, images                      | `path(s)`, `icon(desc)`, `fitMode()`, `rounding(n)`, `sync(b)`  |
| ColumnLayout | `CColumnLayoutBuilder`| Vertical layout stack              | `gap(n)`                                                         |
| RowLayout    | `CRowLayoutBuilder`   | Horizontal layout                  | `gap(n)`                                                         |
| ScrollArea   | `CScrollAreaBuilder`  | Scrollable container               | `scrollX(b)`, `scrollY(b)`, `blockUserScroll(b)`                 |
| Null         | `CNullBuilder`        | Invisible spacer/placeholder       | —                                                                |

#### Sizing system (`CDynamicSize`)

```cpp
// (typeX, typeY, value)
CDynamicSize(HT_SIZE_PERCENT, HT_SIZE_ABSOLUTE, {1.F, 28.F})
//   width=100%           height=28px
```

| Type              | Meaning                          |
|-------------------|----------------------------------|
| `HT_SIZE_ABSOLUTE`| Fixed pixel value                |
| `HT_SIZE_PERCENT` | Fraction of parent (0.0 - 1.0)   |
| `HT_SIZE_AUTO`    | Shrink-wrap to children          |

#### Typical layout tree (launcher pattern)

```cpp
// Root fullscreen background with rounded corners
auto background = Hyprtoolkit::CRectangleBuilder::begin()
    ->color([palette]() { return palette->m_colors.background; })
    ->rounding(palette->m_vars.bigRounding)
    ->borderColor([palette]() { return palette->m_colors.accent.darken(0.2F); })
    ->borderThickness(1)
    ->size({HT_SIZE_PERCENT, HT_SIZE_PERCENT, {1, 1}})
    ->commence();

// Column layout: input → divider → results
auto layout = Hyprtoolkit::CColumnLayoutBuilder::begin()
    ->size({HT_SIZE_PERCENT, HT_SIZE_PERCENT, {1, 1}})
    ->gap(4)
    ->commence();
layout->setMargin(4);

// Search input
auto inputBox = Hyprtoolkit::CTextboxBuilder::begin()
    ->placeholder("Search...")
    ->onTextEdited([](auto, const std::string& query) { /* handle */ })
    ->size({HT_SIZE_PERCENT, HT_SIZE_ABSOLUTE, {1.F, 28.F}})
    ->multiline(false)
    ->commence();

// Horizontal divider (positioned absolute, centered)
auto hr = Hyprtoolkit::CRectangleBuilder::begin()
    ->color([palette]() { return palette->m_colors.accent.darken(0.2F); })
    ->size({HT_SIZE_PERCENT, HT_SIZE_ABSOLUTE, {0.8F, 1.F}})
    ->commence();
hr->setPositionMode(Hyprtoolkit::IElement::HT_POSITION_ABSOLUTE);
hr->setPositionFlag(Hyprtoolkit::IElement::HT_POSITION_FLAG_HCENTER, true);

// Scrollable results
auto scrollArea = Hyprtoolkit::CScrollAreaBuilder::begin()
    ->size({HT_SIZE_PERCENT, HT_SIZE_ABSOLUTE, {1.F, 10.F}})
    ->scrollY(true)
    ->commence();
scrollArea->setGrow(true);

auto resultsLayout = Hyprtoolkit::CColumnLayoutBuilder::begin()
    ->size({HT_SIZE_PERCENT, HT_SIZE_AUTO, {1, 1}})
    ->gap(2)
    ->commence();

// Assemble: background → layout → children
background->addChild(layout);
layout->addChild(inputBox);
layout->addChild(hr);
layout->addChild(scrollArea);
scrollArea->addChild(resultsLayout);

// Attach root element to window
window->m_rootElement->addChild(background);
```

> [Check] Element tree built with proper parent-child hierarchy
> [Check] Root element attached to window->m_rootElement

### Step 4: Handle Keyboard Input

Global key events live on the window:

```cpp
window->m_events.keyboardKey.listenStatic([](Hyprtoolkit::Input::SKeyboardKeyEvent e) {
    if (e.xkbKeysym == XKB_KEY_Escape)
        window->close();
    else if (e.xkbKeysym == XKB_KEY_Down)
        selectNext();
    else if (e.xkbKeysym == XKB_KEY_Up)
        selectPrev();
    else if (e.xkbKeysym == XKB_KEY_Return || e.xkbKeysym == XKB_KEY_KP_Enter)
        confirmSelection();
});
```

`SKeyboardKeyEvent` fields:

| Field      | Type       | Description                         |
|------------|------------|-------------------------------------|
| `xkbKeysym`| `uint32_t` | Key symbol (`XKB_KEY_Escape`, etc.) |
| `down`     | `bool`     | Press (true) or release (false)     |
| `repeat`   | `bool`     | Is this a key repeat?               |
| `utf8`     | `string`   | UTF-8 character if printable        |
| `modMask`  | `uint32_t` | Modifier bitmask (see below)        |

**Modifier bitmask (`eKeyboardModifier`):**

| Constant              | Value |
|-----------------------|-------|
| `HT_MODIFIER_SHIFT`   | 1     |
| `HT_MODIFIER_CAPS`    | 2     |
| `HT_MODIFIER_CTRL`    | 4     |
| `HT_MODIFIER_ALT`     | 8     |
| `HT_MODIFIER_META`    | 64    |

For text input interaction, use the Textbox's `onTextEdited` callback instead of raw key events.

> [Check] Keyboard handler registered for Escape (close), navigation, and confirm
> [Check] Textbox onTextEdited handler wired up for search

### Step 5: Open and Close the Window

```cpp
// Show the overlay (appears above everything)
window->open();
inputBox->focus();

// Hide it
window->close();
```

Typical flow:
1. User presses a keybinding (handled by compositor, which runs `hyprlauncher` or sends IPC)
2. Window opens via `window->open()`
3. Input box gets focus
4. User types, navigates, selects
5. Window closes on selection or Escape

> [Check] Window opens/closes correctly via open()/close()

### Step 6: Use Palette and Colors

```cpp
auto palette = backend->getPalette();

// Available colors
palette->m_colors.background;       // Window background
palette->m_colors.text;             // Primary text
palette->m_colors.base;             // Input background
palette->m_colors.alternateBase;    // Alternate row color
palette->m_colors.brightText;       // Highlighted text
palette->m_colors.accent;           // Accent color
palette->m_colors.accentSecondary;  // Secondary accent

// Metrics
palette->m_vars.fontSize;           // Default: 11
palette->m_vars.smallFontSize;      // Default: 10
palette->m_vars.bigRounding;        // Default: 10
palette->m_vars.smallRounding;      // Default: 5
palette->m_vars.fontFamily;         // Default: "Sans Serif"

// Color operations
color.darken(0.3F);                 // Darken by 30%
color.brighten(0.2F);               // Brighten by 20%
color.mix(other, 0.5F);            // Mix two colors 50/50
CHyprColor{0xRRGGBB};              // From hex
```

> [Check] Colors sourced from palette (or custom colors set)
> [Check] Color functions (darken/brighten) used for hover/active states

### Step 7: Run the Event Loop

```cpp
// Add file descriptors for external events (IPC, inotify, etc.)
backend->addFd(someFd, []() { handleEvent(); });

// Add timers
backend->addTimer(std::chrono::seconds(5),
    [](auto self, void* data) { /* timer callback */ }, nullptr);

// Block forever
backend->enterLoop();
```

> [Check] Event loop entered via backend->enterLoop()
> [Check] File descriptors registered with addFd() before enterLoop()

### Step 8: Build Reusable Result Items

For dynamic list items, pre-allocate and toggle visibility:

```cpp
class MyResultItem {
public:
    SP<Hyprtoolkit::CRectangleElement> m_background;
    SP<Hyprtoolkit::CTextElement>      m_label;
    bool                               m_added = false;
    bool                               m_active = false;

    MyResultItem() {
        const auto FONT_SIZE = Hyprtoolkit::CFontSize{Hyprtoolkit::CFontSize::HT_FONT_TEXT}.ptSize();
        const auto BG_HEIGHT = (FONT_SIZE * 2.F) + 4.F;

        m_background = Hyprtoolkit::CRectangleBuilder::begin()
            ->color([]() { return CHyprColor{0, 0, 0, 0}; })  // transparent
            ->rounding(palette->m_vars.smallRounding)
            ->size({HT_SIZE_PERCENT, HT_SIZE_ABSOLUTE, {1.F, BG_HEIGHT}})
            ->commence();

        m_label = Hyprtoolkit::CTextBuilder::begin()
            ->text("")
            ->align(Hyprtoolkit::HT_FONT_ALIGN_LEFT)
            ->size({HT_SIZE_PERCENT, HT_SIZE_PERCENT, {1, 1}})
            ->commence();

        m_background->addChild(m_label);
    }

    void setActive(bool active) {
        if (active == m_active) return;
        m_active = active;
        m_background->rebuild()
            ->color([this]() {
                auto c = palette->m_colors.accent.darken(0.3F);
                c.a = m_active ? 0.4F : 0.F;
                return c;
            })
            ->commence();
    }

    void setLabel(const std::string& text) {
        m_label->rebuild()->text(std::string{text})->commence();
    }
};
```

**Key pattern**: `rebuild()` returns a builder pre-populated with the element's current state. Call `commence()` to apply changes without destroying the element.

> [Check] Result items pre-allocated in a fixed pool (not created/destroyed per frame)
> [Check] setActive() uses rebuild() to update colors

### Step 9: Implement Daemon Mode with IPC (Optional)

For a single-instance launcher that stays resident:

```cpp
// First instance
if (!socketConnected()) {
    createServerSocket();  // Using hyprwire
    enterLoop();           // Stay resident
}

// Second instance sends command via IPC
connectToSocket();
sendToggle();  // or sendOpen()
exit(0);
```

When IPC signals arrive, call `window->open()` or `window->close()` from within the event loop.

> [Check] IPC socket created before enterLoop()
> [Check] FD registered via backend->addFd() for socket events

## Verification Markers

> [Check] Step 1: Backend created via IBackend::create()
> [Check] Step 2: Window configured with HT_WINDOW_LAYER, layer(3), exclusiveZone(-1), proper anchor
> [Check] Step 3: UI element tree built and attached to window->m_rootElement
> [Check] Step 4: Keyboard handlers registered for Escape, navigation, confirm
> [Check] Step 5: Window opens/closes correctly
> [Check] Step 6: Colors and fonts sourced from backend palette
> [Check] Step 7: Event loop entered via backend->enterLoop()
> [Check] Step 8: Reusable item pattern used for dynamic result lists
> [Check] (optional) Step 9: Daemon mode with IPC socket wired up

## Example: Minimal Launcher

```cpp
#include <hyprtoolkit/core/Backend.hpp>
#include <hyprtoolkit/window/Window.hpp>
#include <hyprtoolkit/element/ColumnLayout.hpp>
#include <hyprtoolkit/element/Rectangle.hpp>
#include <hyprtoolkit/element/Text.hpp>
#include <hyprtoolkit/palette/Palette.hpp>
#include <xkbcommon/xkbcommon-keysyms.h>

int main() {
    auto backend = Hyprtoolkit::IBackend::create();
    auto palette = backend->getPalette();

    auto label = Hyprtoolkit::CTextBuilder::begin()
        ->text("Hello, Hyprtoolkit!")
        ->align(Hyprtoolkit::HT_FONT_ALIGN_CENTER)
        ->size({HT_SIZE_PERCENT, HT_SIZE_PERCENT, {1, 1}})
        ->commence();

    auto bg = Hyprtoolkit::CRectangleBuilder::begin()
        ->color([palette]() { return palette->m_colors.background; })
        ->rounding(palette->m_vars.bigRounding)
        ->size({HT_SIZE_PERCENT, HT_SIZE_PERCENT, {1, 1}})
        ->commence();
    bg->addChild(label);

    auto window = Hyprtoolkit::CWindowBuilder::begin()
        ->appClass("my-launcher")
        ->type(Hyprtoolkit::HT_WINDOW_LAYER)
        ->preferredSize({400, 200})
        ->anchor(1 | 2 | 4 | 8)
        ->exclusiveZone(-1)
        ->layer(3)
        ->kbInteractive(1)
        ->commence();

    window->m_rootElement->addChild(bg);

    window->m_events.keyboardKey.listenStatic([window](auto e) {
        if (e.xkbKeysym == XKB_KEY_Escape)
            window->close();
    });

    window->open();
    backend->enterLoop();
}
```
