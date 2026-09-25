.pragma library

// Colors of the desktop widget styles. They are the styles of the sticky
// note widget of Plasma: each preset draws the note image of the Plasma
// theme ("widgets/notes", element "<svg>-notes") with the text color that
// the sticky note widget uses on it. "theme" uses the Plasma theme
// background and colors, and "custom" draws a plain background in the two
// colors from the settings.
//
// background is the main color of the note image. The settings preview
// and the colored controls use it, and "custom" starts from it.
// alpha is the opacity of that color in the note image.

var PRESETS = {
    "translucent":       { svg: "translucent", background: "#ffffff", text: "#202020", alpha: 0.09 },
    "translucent-light": { svg: "translucent", background: "#ffffff", text: "#dfdfdf", alpha: 0.09 },
    "yellow":            { svg: "yellow", background: "#f8ecc6", text: "#202020", alpha: 1 },
    "white":             { svg: "white",  background: "#eceef2", text: "#202020", alpha: 1 },
    "black":             { svg: "black",  background: "#1e2125", text: "#dfdfdf", alpha: 1 },
    "red":               { svg: "red",    background: "#f3394f", text: "#202020", alpha: 1 },
    "orange":            { svg: "orange", background: "#e97251", text: "#202020", alpha: 1 },
    "green":             { svg: "green",  background: "#36cf77", text: "#202020", alpha: 1 },
    "blue":              { svg: "blue",   background: "#27a0d8", text: "#202020", alpha: 1 },
    "pink":              { svg: "pink",   background: "#ff5576", text: "#202020", alpha: 1 },
};

// The style ids in the order of the settings list.
var IDS = ["theme", "translucent", "translucent-light", "yellow", "white", "black",
           "red", "orange", "green", "blue", "pink", "custom"];

// Returns { svg, background, text, alpha } for a style, or null for
// "theme" and for an unknown style. svg is "" for "custom".
function colors(style, customBackground, customText) {
    if (style === "custom")
        return { svg: "", background: String(customBackground), text: String(customText), alpha: 1 };
    return PRESETS[style] || null;
}

// The id of the note image of a style in the Plasma theme. The default
// theme spells the translucent one "transluscent", so the other spelling is
// the fallback.
function noteElement(svg, hasElement) {
    if (!svg)
        return "";
    const id = svg + "-notes";
    if (svg === "translucent" && !hasElement(id))
        return "transluscent-notes";
    return id;
}
