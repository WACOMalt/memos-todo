.pragma library

// Colors of the desktop widget styles, after the sticky note widget of
// Plasma. "theme" uses the Plasma theme background and colors, and
// "custom" uses the two colors from the settings.
//
// alpha is the opacity of the background at an opacity setting of 100 %.

var PRESETS = {
    "translucent":       { background: "#000000", text: "#ffffff", alpha: 0.45 },
    "translucent-light": { background: "#ffffff", text: "#1b1e20", alpha: 0.6 },
    "yellow":            { background: "#fff59d", text: "#3b3a1f", alpha: 1 },
    "white":             { background: "#fcfcfc", text: "#232627", alpha: 1 },
    "black":             { background: "#232627", text: "#eff0f1", alpha: 1 },
    "red":               { background: "#ef9a9a", text: "#3b1f1f", alpha: 1 },
    "orange":            { background: "#ffcc80", text: "#3b2a14", alpha: 1 },
    "green":             { background: "#c5e1a5", text: "#1f3b1a", alpha: 1 },
    "blue":              { background: "#90caf9", text: "#14283b", alpha: 1 },
    "pink":              { background: "#f8bbd0", text: "#3b1428", alpha: 1 },
};

// The style ids in the order of the settings list.
var IDS = ["theme", "translucent", "translucent-light", "yellow", "white", "black",
           "red", "orange", "green", "blue", "pink", "custom"];

// Returns { background, text, alpha } for a style, or null for "theme"
// and for an unknown style.
function colors(style, customBackground, customText) {
    if (style === "custom")
        return { background: String(customBackground), text: String(customText), alpha: 1 };
    return PRESETS[style] || null;
}
