import QtQuick
import Quickshell
import Quickshell.Io
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string pluginId: "emojiShortcode"
    property string trigger: ":"
    property var emojis: []

    signal itemsChanged

    property FileView emojiDb: FileView {
        path: Qt.resolvedUrl("emoji.json")
        onLoaded: {
            try {
                const raw = JSON.parse(text());
                const parsed = [];

                if (Array.isArray(raw)) {
                    // Format A: Gemoji array [{ "emoji": "😀", "aliases": ["grinning"], "description": "...", "tags": [...] }]
                    for (let i = 0; i < raw.length; i++) {
                        const entry = raw[i];
                        if (!entry.emoji || !entry.aliases) continue;
                        for (let j = 0; j < entry.aliases.length; j++) {
                            parsed.push({
                                code: entry.aliases[j],
                                emoji: entry.emoji,
                                name: entry.description || entry.aliases[j],
                                tags: (entry.tags || []).join(" ").toLowerCase()
                            });
                        }
                    }
                } else if (typeof raw === "object" && raw !== null) {
                    // Format B: Key-value object { "grinning": "😀" } or { "grinning": { "emoji": "😀", "name": "..." } }
                    const keys = Object.keys(raw);
                    for (let i = 0; i < keys.length; i++) {
                        const key = keys[i].replace(/^:+|:+$/g, "");
                        const val = raw[keys[i]];
                        if (typeof val === "string") {
                            parsed.push({
                                code: key,
                                emoji: val,
                                name: key.replace(/_/g, " "),
                                tags: ""
                            });
                        } else if (val && val.emoji) {
                            parsed.push({
                                code: key,
                                emoji: val.emoji,
                                name: val.name || val.description || key.replace(/_/g, " "),
                                tags: (val.tags || []).join(" ").toLowerCase()
                            });
                        }
                    }
                }

                root.emojis = parsed;
                root.itemsChanged();
            } catch (e) {
                console.warn("EmojiShortcode: Failed to parse emoji.json:", e);
            }
        }
    }

    function getItems(query) {
        const cleanQuery = (query || "").replace(/^:+|:+$/g, "").toLowerCase().trim();

        const exact = [];
        const startsWith = [];
        const partial = [];

        for (let i = 0; i < root.emojis.length; i++) {
            const e = root.emojis[i];
            if (cleanQuery === "") {
                partial.push(e);
            } else if (e.code === cleanQuery) {
                exact.push(e);
            } else if (e.code.startsWith(cleanQuery)) {
                startsWith.push(e);
            } else if (
                e.code.includes(cleanQuery) ||
                e.name.toLowerCase().includes(cleanQuery) ||
                e.tags.includes(cleanQuery)
            ) {
                partial.push(e);
            }

            if (cleanQuery === "" && partial.length >= 50) break;
        }

        const results = exact.concat(startsWith, partial).slice(0, 50);

        return results.map(e => ({
            name: ":" + e.code + ":  " + e.emoji,
            icon: "unicode:" + e.emoji,
            comment: e.name + " (Enter to copy)",
            action: "copy:" + e.emoji,
            categories: ["Emojis"]
        }));
    }

    function executeItem(item) {
        if (!item?.action || !item.action.startsWith("copy:")) return;

        const emoji = item.action.substring(5);
        Quickshell.execDetached(["dms", "cl", "copy", emoji]);
        ToastService.showInfo("Copied " + emoji);
    }

    function getPasteText(item) {
        if (!item?.action || !item.action.startsWith("copy:")) return null;
        return item.action.substring(5);
    }
}
