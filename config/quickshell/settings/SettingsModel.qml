import QtQuick
import Quickshell
import Quickshell.Io
import qs.core

Scope {
    id: root

    property bool visible: false
    property bool busy: false
    property string searchQuery: ""
    property string selectedSectionId: "displays"
    property string discoveryState: "idle"
    property string message: ""
    property string platformId: "unknown"
    property string platformFamily: "unknown"
    property string platformName: "Unknown Linux"
    property var targetScreen: null
    property var capabilities: []
    property int selectedIndex: 0
    property var displayOutputs: []
    property var displayModes: []
    property var displayProfiles: []
    property var displayUnsupportedProfiles: []
    property string displayState: "idle"
    property string displayMessage: ""
    property var inputDevices: []
    property var inputSettings: []
    property var inputUnsupported: []
    property string inputState: "idle"
    property string appearanceState: "idle"
    property var appearanceThemes: []
    property string appearanceActive: ""
    property int appearanceBorderpx: 1
    property string appearanceMessage: ""
    property var appearanceColors: ({})
    property bool appearanceDarkMode: true
    property string wallpaperState: "idle"
    property var wallpaperMonitors: []
    property var wallpaperCandidates: []
    property string wallpaperFit: "scale"
    property string wallpaperMessage: ""
    property string fontState: "idle"
    property string fontFamily: ""
    property real fontScale: 1.0
    property string fontDetail: ""
    property string fontMessage: ""
    property var fontCandidates: []
    property string fontPreviewState: "none"
    property string fontPreviewToken: ""
    property int fontPreviewRemaining: 0
    property bool fontMutationReady: false
    property string iconsState: "idle"
    property string iconsCurrent: ""
    property var iconsThemes: []
    property string iconsMessage: ""
    property string picomState: "idle"
    property bool picomInstalled: false
    property bool picomEditable: false
    property bool picomRunning: false
    property real picomActive: 100.0
    property real picomInactive: 97.0
    property string picomBackend: "auto"
    property string picomEffectiveBackend: ""
    property string picomMessage: ""
    property string picomRevision: ""
    property string inputMessage: ""
    property string previewKind: ""
    property string previewToken: ""
    property int previewSeconds: 0
    property int displayPreviewStatusAttempts: 0
	property int inputPreviewStatusAttempts: 0
    property bool previewRollbackFailed: false
    property bool previewOperationLocked: false
    property bool closeRollbackPending: false
    property string pendingAction: ""

    readonly property int maxDisplayPreviewStatusAttempts: 120
	readonly property int maxInputPreviewStatusAttempts: 120
    readonly property var displayPersistenceCapability: {
        for (const capability of root.capabilities) {
            if (capability.id === "display-persistence") return capability;
        }
        return { "status": "restricted", "detail": "Persistent display controls are unavailable" };
    }
    readonly property bool displayPersistenceAvailable: root.displayPersistenceCapability.status === "available"

    readonly property var sections: [
        { "id": "displays", "label": "Displays", "description": "Monitors, layouts, and profiles" },
        { "id": "input", "label": "Input", "description": "Keyboard, pointer, and touchpad" },
        { "id": "network", "label": "Network", "description": "Connections and VPN providers" },
        { "id": "bluetooth", "label": "Bluetooth", "description": "Adapters and devices" },
        { "id": "audio", "label": "Audio", "description": "Outputs, inputs, and streams" },
        { "id": "power", "label": "Power", "description": "DPMS, locking, and session policy" },
        { "id": "defaults", "label": "Defaults", "description": "Applications and autostart" },
        { "id": "appearance", "label": "Appearance", "description": "Themes and accessibility" },
        { "id": "system", "label": "System", "description": "Health and administration" }
    ]

    readonly property var filteredSections: {
        const query = root.searchQuery.trim().toLowerCase();
        if (query.length === 0) return root.sections;
        return root.sections.filter(function(section) {
            return section.label.toLowerCase().indexOf(query) >= 0
                || section.description.toLowerCase().indexOf(query) >= 0;
        });
    }

    function sectionById(id) {
        for (const section of root.sections) {
            if (section.id === id) return section;
        }
        return root.sections[0];
    }

    function selectedSection() {
        return root.sectionById(root.selectedSectionId);
    }

    function capabilitiesForSection(id) {
        return root.capabilities.filter(function(capability) {
            return capability.section === id;
        });
    }

    function activateSection(id) {
        displayWatchProcess.running = id === "displays" && root.visible;
        inputWatchProcess.running = id === "input" && root.visible;
			if (id !== "input") inputSettleTimer.stop();
        if (id === "displays") root.refreshDisplays();
        if (id === "input") root.refreshInput();
        if (id === "appearance") { root.refreshAppearance(); root.refreshWallpaper(); root.refreshFont(); root.refreshIcons(); root.refreshPicom(); }
    }

    function parseDisplays(text) {
        const outputs = [];
        const modes = [];
        const profiles = [];
        const unsupportedProfiles = [];
        let valid = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "display-protocol" && fields[1] === "1") {
                valid = true;
            } else if (fields[0] === "output" && fields.length >= 9) {
                outputs.push({
                    "name": fields[1], "enabled": fields[2] === "1",
                    "primary": fields[3] === "1", "mode": fields[4],
                    "rate": "", "x": Number(fields[5]), "y": Number(fields[6]),
                    "rotation": fields[7], "tearfree": fields[8],
                    "fullCompositionPipeline": fields.length >= 10 ? fields[9] : "unsupported"
                });
            } else if (fields[0] === "mode" && fields.length >= 6) {
                modes.push({
                    "output": fields[1], "mode": fields[2], "rate": fields[3],
                    "current": fields[4] === "1", "preferred": fields[5] === "1"
                });
            } else if (fields[0] === "profile" && fields.length >= 2) {
                profiles.push(fields[1]);
            } else if (fields[0] === "profile-unsupported" && fields.length >= 3) {
                unsupportedProfiles.push({ "name": fields[1], "detail": fields.slice(2).join("\t") });
            }
        }
        for (let index = 0; index < outputs.length; index++) {
            const current = modes.find(function(mode) {
                return mode.output === outputs[index].name && mode.current;
            });
            if (current) {
                outputs[index].mode = current.mode;
                outputs[index].rate = current.rate;
            } else {
                const preferred = modes.find(function(mode) {
                    return mode.output === outputs[index].name && mode.preferred;
                });
                if (preferred) {
                    outputs[index].mode = preferred.mode;
                    outputs[index].rate = preferred.rate;
                }
            }
        }
        root.displayOutputs = outputs;
        root.displayModes = modes;
        root.displayProfiles = profiles;
        root.displayUnsupportedProfiles = unsupportedProfiles;
        root.displayState = valid ? "ready" : "failure";
        root.displayMessage = valid ? outputs.length + " connected outputs" : "Unsupported display provider response";
    }

    function availableModes(outputName) {
        const result = [];
        const seen = {};
        for (const m of root.displayModes) {
            if (m.output !== outputName) continue;
            if (seen[m.mode]) continue;
            seen[m.mode] = true;
            result.push(m.mode);
        }
        return result;
    }

    function availableRates(outputName, mode) {
        const result = [];
        for (const m of root.displayModes) {
            if (m.output !== outputName) continue;
            if (m.mode !== mode) continue;
            if (result.indexOf(m.rate) >= 0) continue;
            result.push(m.rate);
        }
        return result;
    }

    function parseInput(text) {
        const devices = [];
        const settings = [];
        const unsupported = [];
        let valid = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "input-protocol" && fields[1] === "1") {
                valid = true;
            } else if (fields[0] === "device" && fields.length >= 5) {
                devices.push({ "key": fields[1], "xid": fields[2], "kind": fields[3], "name": fields[4] });
            } else if (fields[0] === "setting" && fields.length >= 9) {
                settings.push({
                    "device": fields[1], "id": fields[2], "label": fields[3],
                    "type": fields[4], "value": fields[5], "defaultValue": fields[6],
                    "minimum": Number(fields[7]), "maximum": Number(fields[8])
                });
            } else if (fields[0] === "unsupported" && fields.length >= 4) {
                unsupported.push({ "device": fields[1], "id": fields[2], "detail": fields[3] });
            }
        }
        root.inputDevices = devices;
        root.inputSettings = settings;
        root.inputUnsupported = unsupported;
        root.inputState = valid ? "ready" : "failure";
        root.inputMessage = valid ? devices.length + " input devices" : "Unsupported input provider response";
    }

    function parseAppearance(text) {
        const themes = [];
        let active = "";
        let borderpx = 1;
        let valid = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "appearance-protocol" && fields[1] === "1") {
                valid = true;
            } else if (fields[0] === "active" && fields.length >= 2) {
                active = fields[1];
            } else if (fields[0] === "borderpx" && fields.length >= 2) {
                borderpx = Number(fields[1]) || 1;
            } else if (fields[0] === "theme" && fields.length >= 3) {
                themes.push({ "name": fields[1], "active": fields[2] === "1" });
            }
        }
        root.appearanceThemes = themes;
        root.appearanceActive = active;
        root.appearanceBorderpx = borderpx;
        root.appearanceState = valid ? "ready" : "failure";
        root.appearanceMessage = valid ? themes.length + " themes" : "Unsupported appearance provider response";
    }

    function parseAppearanceSnapshot(text) {
        const colors = {};
        let darkMode = true;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "color" && fields.length >= 3) {
                colors[fields[1]] = fields[2];
            } else if (fields[0] === "theme" && fields.length >= 4) {
                if (fields[1] === fields[0]) continue; // skip malformed
                // theme name status valid dark ...
                if (fields[2] === "selected" && fields.length >= 5) {
                    darkMode = fields[4] === "true";
                }
            }
        }
        root.appearanceColors = colors;
        root.appearanceDarkMode = darkMode;
        if (Object.keys(colors).length > 0) {
            Theme.applyAppearanceColors(colors, darkMode);
        }
    }

    function parseWallpaper(text) {
        const monitors = [];
        const candidates = [];
        let fit = "scale";
        let valid = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "wallpaper-protocol" && fields[1] === "1") {
                valid = true;
            } else if (fields[0] === "fit" && fields.length >= 2) {
                fit = fields[1];
            } else if (fields[0] === "monitor" && fields.length >= 5) {
                monitors.push({
                    "name": fields[1],
                    "index": Number(fields[2]),
                    "basename": fields[3],
                    "path": fields[4]
                });
            } else if (fields[0] === "candidate" && fields.length >= 3) {
                candidates.push({
                    "basename": fields[1],
                    "path": fields[2]
                });
            }
        }
        root.wallpaperMonitors = monitors;
        root.wallpaperCandidates = candidates;
        root.wallpaperFit = fit;
        root.wallpaperState = valid ? "ready" : "failure";
        root.wallpaperMessage = valid ? (monitors.length + " monitors, " + candidates.length + " wallpapers") : "Unsupported wallpaper provider response";
    }

    function parseFont(text) {
        let family = "";
        let scale = 1.0;
        let detail = "";
        let previewState = "none";
        let previewToken = "";
        let previewRemaining = 0;
        let mutationReady = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "appearance-font-action-protocol" && fields[1] === "1") {
                // protocol ok
            } else if (fields[0] === "selection" && fields.length >= 5) {
                family = fields[2];
                scale = parseFloat(fields[3]) || 1.0;
                detail = fields[4] || "";
            } else if (fields[0] === "preview" && fields.length >= 7) {
                previewState = fields[1];
                previewToken = fields[2];
                previewRemaining = Number(fields[5]) || 0;
            }
        }
        root.fontFamily = family;
        root.fontScale = scale;
        root.fontDetail = detail;
        root.fontPreviewState = previewState;
        root.fontPreviewToken = previewToken;
        root.fontPreviewRemaining = previewRemaining;
        root.fontState = "ready";
        root.fontMessage = family + " / " + Math.round(scale * 100) + "%";
        if (family.length > 0) {
            Theme.applyFontPreferences(family, scale);
        }
    }

    function parseFontInventory(text) {
        const candidates = [];
        const allowed = /^(MesloLGS Nerd Font Mono|MesloLGM Nerd Font Mono|Noto Color Emoji)$/;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "candidate" && fields[1] === "font" && fields.length >= 4) {
                if (!allowed.test(fields[3])) continue;
                candidates.push({
                    "id": fields[1],
                    "state": fields[2],
                    "family": fields[3],
                    "name": fields[4] || fields[3]
                });
            }
        }
        root.fontCandidates = candidates;
    }

    function parseIcons(text) {
        const themes = [];
        let current = "";
        let valid = false;
        for (const line of text.trim().split("\n")) {
            const fields = line.split("\t");
            if (fields[0] === "icons-protocol" && fields[1] === "1") {
                valid = true;
            } else if (fields[0] === "current" && fields.length >= 2) {
                current = fields[1];
            } else if (fields[0] === "theme" && fields.length >= 3) {
                themes.push({ "name": fields[1], "active": fields[2] === "1" });
            }
        }
        root.iconsThemes = themes;
        root.iconsCurrent = current;
        root.iconsState = valid ? "ready" : "failure";
        root.iconsMessage = valid ? themes.length + " Icon-Themes" : "Unsupported icons provider response";
    }

    function parsePicom(text) {
        try {
            const data = JSON.parse(text.trim());
            root.picomInstalled = data.installed === true;
            root.picomEditable = data.editable === true;
            root.picomRunning = data.running === true;
            root.picomActive = Number(data.active) || 100.0;
            root.picomInactive = Number(data.inactive) || 97.0;
            root.picomBackend = data.policy || "auto";
            root.picomEffectiveBackend = data.effective || "";
            root.picomMessage = data.message || data.detail || "";
            root.picomRevision = data.revision || "";
            root.picomState = "ready";
        } catch (e) {
            root.picomState = "failure";
            root.picomMessage = "Picom-Status konnte nicht gelesen werden: " + e;
        }
    }

    function updateDisplay(index, field, value) {
        const outputs = root.displayOutputs.slice();
        const changed = Object.assign({}, outputs[index]);
        changed[field] = value;
        outputs[index] = changed;
        if (field === "primary" && value) {
            for (let other = 0; other < outputs.length; other++) {
                if (other !== index) outputs[other] = Object.assign({}, outputs[other], { "primary": false });
            }
        }
        root.displayOutputs = outputs;
    }

    function cycleDisplayMode(index) {
        const output = root.displayOutputs[index];
        const choices = root.displayModes.filter(function(mode) { return mode.output === output.name; });
        if (choices.length === 0) return;
        let selected = choices.findIndex(function(mode) { return mode.mode === output.mode && mode.rate === output.rate; });
        selected = (selected + 1) % choices.length;
        root.updateDisplay(index, "mode", choices[selected].mode);
        root.updateDisplay(index, "rate", choices[selected].rate);
    }

    function cycleRotation(index) {
        const rotations = ["normal", "left", "right", "inverted"];
        const current = rotations.indexOf(root.displayOutputs[index].rotation);
        root.updateDisplay(index, "rotation", rotations[(current + 1) % rotations.length]);
    }

    function displaySpecs() {
        const specs = [];
        for (const output of root.displayOutputs) {
            if (!output.name || output.name.indexOf("|") >= 0
                    || (output.enabled && (!output.mode || !output.rate
                        || !Number.isInteger(output.x) || !Number.isInteger(output.y)))) {
                root.displayState = "failure";
                root.displayMessage = "Display data is incomplete; refresh before previewing or saving";
                return null;
            }
            specs.push([output.name, output.enabled ? "1" : "0", output.mode, output.rate,
                String(output.x), String(output.y), output.rotation, output.primary ? "1" : "0"].join("|"));
        }
        return specs;
    }

    function runDisplay(action, args) {
        if (displayActionProcess.running) return;
        root.pendingAction = "display-" + action;
        displayActionProcess.command = Commands.settingsDisplayCommand(action, args || []);
        displayActionProcess.running = true;
    }

    function previewDisplay() {
        if (root.previewOperationLocked || displayActionProcess.running || inputActionProcess.running) return;
        const specs = root.displaySpecs();
        if (!specs || specs.length === 0) return;
        root.previewOperationLocked = true;
		root.closeRollbackPending = false;
        const token = "display-" + Date.now();
        root.runDisplay("preview", [token, "15"].concat(specs));
    }

    function previewDisplayProfile(name) {
        if (root.previewOperationLocked || displayActionProcess.running || inputActionProcess.running) return;
        root.previewOperationLocked = true;
		root.closeRollbackPending = false;
        const token = "display-" + Date.now();
        root.runDisplay("preview-profile", [token, "15", name]);
    }

    function keepPreview(name) {
        if (root.previewKind === "display") root.runDisplay("keep", [root.previewToken].concat(name && !root.previewRollbackFailed ? [name] : []));
        else if (root.previewKind === "input") root.runInput("keep", [root.previewToken]);
    }

    function revertPreview() {
        if (!root.previewToken) return;
        if (root.previewKind === "display") root.runDisplay("revert", [root.previewToken]);
        else if (root.previewKind === "input") root.runInput("revert", [root.previewToken]);
    }

    function saveDisplay(name) {
        const specs = root.displaySpecs();
        if (name.trim().length > 0 && specs && specs.length > 0)
            root.runDisplay("save", [name.trim()].concat(specs));
    }

    function installDisplayProfile(name) {
        if (name.trim().length > 0) root.runDisplay("install-profile", [name.trim()]);
    }

    function rollbackDisplaySystem() {
        root.runDisplay("rollback-system", []);
    }

    function pollDisplayPreviewStatus() {
        if (root.displayPreviewStatusAttempts >= root.maxDisplayPreviewStatusAttempts) {
            root.previewSeconds = 0;
            root.previewOperationLocked = true;
            root.displayMessage = "Automatic rollback status timed out; use Revert to retry the captured layout";
            return;
        }
        root.displayPreviewStatusAttempts++;
        if (displayActionProcess.running) {
            root.previewSeconds = 1;
            return;
        }
        root.runDisplay("preview-status", [root.previewToken]);
    }

    function runInput(action, args) {
        if (inputActionProcess.running) return;
        root.pendingAction = "input-" + action;
        inputActionProcess.command = Commands.settingsInputCommand(action, args || []);
        inputActionProcess.running = true;
    }

	function pollInputPreviewStatus() {
		if (root.inputPreviewStatusAttempts >= root.maxInputPreviewStatusAttempts) {
			root.previewSeconds = 0;
			root.previewOperationLocked = true;
			root.inputMessage = "Automatic rollback status timed out; use Revert to retry the captured value";
			return;
		}
		root.inputPreviewStatusAttempts++;
		if (inputActionProcess.running) {
			root.previewSeconds = 1;
			return;
		}
		root.runInput("preview-status", [root.previewToken]);
	}

	function recoverInputPreview() {
		if (!root.previewToken && !inputActionProcess.running)
			root.runInput("preview-status", []);
	}

	function recoverDisplayPreview() {
		if (!root.previewToken && !displayActionProcess.running)
			root.runDisplay("preview-status", []);
	}

	function requireRecoveredPreviewRollback() {
		if (!root.visible) root.closeRollbackPending = true;
	}

    function previewInput(device, setting, value) {
        if (root.previewOperationLocked || displayActionProcess.running || inputActionProcess.running) return;
        root.previewOperationLocked = true;
		root.closeRollbackPending = false;
        const token = "input-" + Date.now();
        root.runInput("preview", [token, "15", device, setting, String(value)]);
    }

    function resetInput(device, setting) {
        root.runInput("reset", [device, setting]);
    }

    function refreshDisplays() {
        if (!root.visible || displayDiscoverProcess.running) return;
        root.displayState = "loading";
        displayDiscoverProcess.running = true;
    }

    function refreshInput() {
        if (!root.visible || inputDiscoverProcess.running) return;
        root.inputState = "loading";
        inputDiscoverProcess.running = true;
    }

    function refreshAppearance() {
        if (!root.visible || appearanceDiscoverProcess.running) return;
        root.appearanceState = "loading";
        appearanceDiscoverProcess.running = true;
        if (!appearanceSnapshotProcess.running) appearanceSnapshotProcess.running = true;
    }

    function setTheme(name) {
        if (!name || appearanceActionProcess.running) return;
        appearanceActionProcess.command = Commands.settingsAppearanceControlCommand("set-theme", [name]);
        appearanceActionProcess.running = true;
    }

    function setBorderpx(value) {
        if (appearanceActionProcess.running) return;
        appearanceActionProcess.command = Commands.settingsAppearanceControlCommand("set-borderpx", [String(value)]);
        appearanceActionProcess.running = true;
    }

    function refreshWallpaper() {
        if (!root.visible || wallpaperDiscoverProcess.running) return;
        root.wallpaperState = "loading";
        wallpaperDiscoverProcess.running = true;
    }

    function setWallpaper(index, path) {
        if (!path || wallpaperActionProcess.running) return;
        wallpaperActionProcess.command = Commands.settingsWallpaperAzoteCommand("set-wallpaper", [String(index), path]);
        wallpaperActionProcess.running = true;
    }

    function setWallpaperFit(mode) {
        if (!mode || wallpaperActionProcess.running) return;
        wallpaperActionProcess.command = Commands.settingsWallpaperAzoteCommand("set-fit", [mode]);
        wallpaperActionProcess.running = true;
    }

    function randomizeWallpaper() {
        if (wallpaperActionProcess.running) return;
        wallpaperActionProcess.command = Commands.settingsWallpaperAzoteCommand("randomize", []);
        wallpaperActionProcess.running = true;
    }

    function resetWallpaper() {
        if (wallpaperActionProcess.running) return;
        wallpaperActionProcess.command = Commands.settingsWallpaperAzoteCommand("reset", []);
        wallpaperActionProcess.running = true;
    }

    function refreshFont() {
        if (!root.visible || fontStatusProcess.running) return;
        root.fontState = "loading";
        fontStatusProcess.running = true;
        root.refreshFontCandidates();
    }

    function applyFont(family, scale) {
        if (!family || fontActionProcess.running) return;
        const scaleStr = (scale || 1.0).toFixed(2);
        fontActionProcess.command = Commands.settingsFontCommand("apply", [family, scaleStr]);
        fontActionProcess.running = true;
    }

    function followSystemFont() {
        if (fontActionProcess.running) return;
        fontActionProcess.command = Commands.settingsFontCommand("reset", []);
        fontActionProcess.running = true;
    }

    function refreshIcons() {
        if (!root.visible || iconsProcess.running) return;
        root.iconsState = "loading";
        iconsProcess.command = Commands.settingsIconsCommand("list", []);
        iconsProcess.running = true;
    }

    function setIconTheme(name) {
        if (!name || iconsActionProcess.running) return;
        iconsActionProcess.command = Commands.settingsPersonalizationCommand("apply", ["icon", name]);
        iconsActionProcess.running = true;
    }

    function refreshPicom() {
        if (!root.visible || picomStatusProcess.running) return;
        root.picomState = "loading";
        picomStatusProcess.running = true;
    }

    function setPicomOpacity(active, inactive) {
        if (picomActionProcess.running) return;
        picomActionProcess.command = Commands.helperCommand("dwm-settings-picom", "set-opacity",
            [String(Math.round(active)), String(Math.round(inactive)), root.picomRevision], true);
        picomActionProcess.running = true;
    }

    function setPicomBackend(backend) {
        if (!backend || picomActionProcess.running) return;
        picomActionProcess.command = Commands.helperCommand("dwm-settings-picom", "set-backend",
            [backend], true);
        picomActionProcess.running = true;
    }

    function togglePicom() {
        if (picomActionProcess.running) return;
        picomActionProcess.command = Commands.helperCommand("dwm-settings-picom", "toggle", [], true);
        picomActionProcess.running = true;
    }

    function restartPicom() {
        if (picomActionProcess.running) return;
        picomActionProcess.command = Commands.helperCommand("dwm-settings-picom", "restart", [], true);
        picomActionProcess.running = true;
    }

    function setSearch(value) {
        root.searchQuery = value;
        root.selectedIndex = 0;
        if (root.filteredSections.length > 0) {
            root.selectedSectionId = root.filteredSections[0].id;
            root.activateSection(root.selectedSectionId);
        }
    }

    function selectSection(id) {
        const exists = root.sections.some(function(section) {
            return section.id === id;
        });
        if (!exists) return;
        if (root.searchQuery.length > 0 && !root.filteredSections.some(function(section) {
            return section.id === id;
        })) {
            root.searchQuery = "";
        }
        for (let index = 0; index < root.filteredSections.length; index++) {
            if (root.filteredSections[index].id === id) {
                root.selectedIndex = index;
                root.selectedSectionId = id;
                root.activateSection(id);
                return;
            }
        }
    }

    function selectRelative(delta) {
        const sections = root.filteredSections;
        if (sections.length === 0) return;
        root.selectedIndex = (root.selectedIndex + delta + sections.length) % sections.length;
        root.selectedSectionId = sections[root.selectedIndex].id;
        root.activateSection(root.selectedSectionId);
    }

    function parseDiscovery(text) {
        const capabilities = [];
        const lines = text.trim().length > 0 ? text.trim().split("\n") : [];
        let validProtocol = false;

        for (const line of lines) {
            const fields = line.split("\t");
            if (fields[0] === "settings-protocol" && fields[1] === "1") {
                validProtocol = true;
            } else if (fields[0] === "platform" && fields.length >= 4) {
                root.platformId = fields[1];
                root.platformFamily = fields[2];
                root.platformName = fields[3];
            } else if (fields[0] === "capability" && fields.length >= 8) {
                capabilities.push({
                    "section": fields[1],
                    "id": fields[2],
                    "label": fields[3],
                    "status": fields[4],
                    "capabilityClass": fields[5],
                    "provider": fields[6],
                    "detail": fields[7]
                });
            }
        }

        root.busy = false;
        if (!validProtocol) {
            root.discoveryState = "failure";
            root.message = "Capability provider returned an unsupported response";
            root.capabilities = [];
            return;
        }

        root.capabilities = capabilities;
        root.discoveryState = "ready";
        root.message = capabilities.length + " capabilities discovered";
    }

    function refresh() {
        if (!root.visible || providerProcess.running) return;
        root.busy = true;
        root.discoveryState = "loading";
        root.message = "Discovering capabilities...";
        providerProcess.running = true;
    }

    function openWindow() {
        root.visible = true;
        root.searchQuery = "";
        root.selectedIndex = 0;
        root.selectedSectionId = root.sections[0].id;
        root.refresh();
        root.activateSection(root.selectedSectionId);
		root.recoverDisplayPreview();
		root.recoverInputPreview();
    }

    function open() {
        root.targetScreen = null;
        root.openWindow();
    }

    function openOnScreen(screen) {
        root.targetScreen = screen;
        root.openWindow();
    }

    function close() {
			const displayPreviewStarting = displayActionProcess.running
				&& (root.pendingAction === "display-preview" || root.pendingAction === "display-preview-profile");
			const inputPreviewStarting = inputActionProcess.running && root.pendingAction === "input-preview";
			if (!root.previewToken && (displayPreviewStarting || inputPreviewStarting)) {
				root.closeRollbackPending = true;
			} else if (root.previewToken) {
				const actionBusy = root.previewKind === "display" ? displayActionProcess.running : inputActionProcess.running;
				if (actionBusy) root.closeRollbackPending = true;
			else {
				root.closeRollbackPending = false;
				root.revertPreview();
			}
		}
        providerProcess.running = false;
        displayDiscoverProcess.running = false;
        inputDiscoverProcess.running = false;
        displayWatchProcess.running = false;
        inputWatchProcess.running = false;
			inputSettleTimer.stop();
        root.visible = false;
        root.busy = false;
        root.searchQuery = "";
        root.selectedIndex = 0;
    }

    function toggle() {
        if (root.visible) root.close(); else root.open();
    }

    Process {
        id: providerProcess

        command: Commands.settingsProviderCommand("discover")
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.parseDiscovery(this.text)
        }

        stderr: StdioCollector {
            onStreamFinished: {
                const error = this.text.trim();
                if (error.length > 0) root.message = error;
            }
        }
    }

    Process {
        id: displayDiscoverProcess
        command: Commands.settingsDisplayCommand("discover")
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseDisplays(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.displayState = "failure"; root.displayMessage = error; } } }
    }

    Process {
        id: inputDiscoverProcess
        command: Commands.settingsInputCommand("discover")
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseInput(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.inputState = "failure"; root.inputMessage = error; } } }
    }

    Process {
        id: displayWatchProcess
        command: Commands.settingsDisplayCommand("watch")
        running: false
        stdout: SplitParser { onRead: root.refreshDisplays() }
    }

    Process {
        id: inputWatchProcess
        command: Commands.settingsInputCommand("watch")
        running: false
			stdout: SplitParser { onRead: inputSettleTimer.restart() }
    }

    Process {
        id: displayActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
				const lines = this.text.trim().split("\n");
				for (const line of lines) {
					const fields = line.split("\t");
					if (fields[0] === "preview") {
						root.previewKind = "display"; root.previewToken = fields[1]; root.previewSeconds = Number(fields[2]);
						root.previewRollbackFailed = false;
						root.displayPreviewStatusAttempts = 0;
						root.displayMessage = "Display preview active";
						} else if (fields[0] === "preview-active") {
							root.previewKind = "display"; root.previewToken = fields[1]; root.previewOperationLocked = true;
							root.previewRollbackFailed = false;
							root.requireRecoveredPreviewRollback();
						if (root.displayPreviewStatusAttempts >= root.maxDisplayPreviewStatusAttempts) {
							root.previewSeconds = 0; root.previewOperationLocked = true;
							root.displayMessage = "Automatic rollback status timed out; use Revert to retry the captured layout";
						} else {
							root.previewSeconds = 1;
							root.displayMessage = "Waiting for automatic rollback";
						}
						} else if (fields[0] === "preview-failed") {
							root.previewKind = "display"; root.previewToken = fields[1]; root.previewSeconds = 0;
							root.previewRollbackFailed = true;
							root.requireRecoveredPreviewRollback();
						root.displayPreviewStatusAttempts = 0;
						root.previewOperationLocked = true; root.displayMessage = fields.slice(2).join("\t");
					} else if (fields[0] === "result") {
						const finalizesPreview = fields[1] === "kept" || fields[1] === "reverted" || fields[1] === "expired";
						if (finalizesPreview) {
							root.previewKind = ""; root.previewToken = ""; root.previewSeconds = 0; root.previewOperationLocked = false;
							root.previewRollbackFailed = false;
							root.displayPreviewStatusAttempts = 0;
						}
						root.displayMessage = fields.slice(1).join(" ");
						root.refreshDisplays();
					}
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) root.displayMessage = error; } }
        onRunningChanged: {
            if (!running && !root.previewToken) root.previewOperationLocked = false;
			if (!running && !root.visible && root.previewKind === "display" && root.closeRollbackPending) {
				root.closeRollbackPending = false;
				root.revertPreview();
			}
        }
    }

    Process {
        id: inputActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
				const lines = this.text.trim().split("\n");
				for (const line of lines) {
					const fields = line.split("\t");
					if (fields[0] === "preview") {
						root.previewKind = "input"; root.previewToken = fields[1]; root.previewSeconds = Number(fields[2]);
						root.previewRollbackFailed = false;
						root.inputPreviewStatusAttempts = 0;
						root.inputMessage = "Input preview active";
						} else if (fields[0] === "preview-active") {
							root.previewKind = "input"; root.previewToken = fields[1]; root.previewOperationLocked = true;
							root.requireRecoveredPreviewRollback();
						if (root.inputPreviewStatusAttempts >= root.maxInputPreviewStatusAttempts) {
							root.previewSeconds = 0; root.previewOperationLocked = true;
							root.inputMessage = "Automatic rollback status timed out; use Revert to retry the captured value";
						} else {
							root.previewSeconds = 1;
							root.inputMessage = "Waiting for automatic input rollback";
						}
						} else if (fields[0] === "preview-failed") {
							root.previewKind = "input"; root.previewToken = fields[1]; root.previewSeconds = 0;
							root.requireRecoveredPreviewRollback();
						root.inputPreviewStatusAttempts = 0;
						root.previewOperationLocked = true; root.inputMessage = fields.slice(2).join("\t");
					} else if (fields[0] === "result") {
						if (fields[1] === "keep" || fields[1] === "revert" || fields[1] === "expired") {
							root.previewKind = ""; root.previewToken = ""; root.previewSeconds = 0; root.previewOperationLocked = false;
							root.inputPreviewStatusAttempts = 0;
						}
						root.inputMessage = fields.slice(1).join(" ");
						root.refreshInput();
					}
					}
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) root.inputMessage = error; } }
        onRunningChanged: {
            if (!running && !root.previewToken) root.previewOperationLocked = false;
			if (!running && !root.visible && root.previewKind === "input" && root.closeRollbackPending) {
				root.closeRollbackPending = false;
				root.revertPreview();
			}
        }
    }

    Process {
        id: appearanceSnapshotProcess
        command: Commands.settingsAppearanceCommand("snapshot")
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseAppearanceSnapshot(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) console.warn("appearance snapshot:", error); } }
    }

    Process {
        id: wallpaperDiscoverProcess
        command: Commands.settingsWallpaperAzoteCommand("discover", [])
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseWallpaper(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.wallpaperState = "failure"; root.wallpaperMessage = error; } } }
    }

    Process {
        id: wallpaperActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const fields = line.split("\t");
                    if (fields[0] === "ok") {
                        root.wallpaperMessage = fields.slice(1).join(" ");
                    } else if (fields[0] === "error") {
                        root.wallpaperState = "failure";
                        root.wallpaperMessage = fields.slice(1).join(" ");
                    }
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.wallpaperState = "failure"; root.wallpaperMessage = error; } } }
        onRunningChanged: {
            if (!running) root.refreshWallpaper();
        }
    }

    function refreshFontCandidates() {
        const wanted = [
            "MesloLGS Nerd Font Mono",
            "MesloLGM Nerd Font Mono",
            "FantasqueSansM Nerd Font Mono",
            "FiraCode Nerd Font Mono",
            "Iosevka Nerd Font Mono",
            "JetBrainsMono Nerd Font Mono",
            "JetBrainsMono Nerd Font",
            "Hack Nerd Font Mono",
            "Hack Nerd Font",
            "CascadiaCode Nerd Font Mono",
            "CascadiaCode Nerd Font",
            "Mononoki Nerd Font Mono",
            "Mononoki Nerd Font",
            "SourceCodePro Nerd Font Mono",
            "SourceCodePro Nerd Font",
            "Inconsolata Nerd Font Mono",
            "Inconsolata Nerd Font",
            "Ubuntu Nerd Font Mono",
            "Ubuntu Nerd Font",
            "RobotoMono Nerd Font Mono",
            "RobotoMono Nerd Font",
            "Noto Sans",
            "Noto Sans Mono",
            "Noto Color Emoji",
            "DejaVu Sans",
            "DejaVu Sans Mono",
            "Liberation Sans",
            "Liberation Mono",
            "Cantarell",
            "Open Sans"
        ];
        const result = [];
        const available = Qt.fontFamilies();
        for (const name of wanted) {
            if (available.indexOf(name) >= 0) {
                result.push({
                    "id": "font",
                    "state": "available",
                    "family": name,
                    "name": name
                });
            }
        }
        root.fontCandidates = result;
    }

    Process {
        id: fontStatusProcess
        command: Commands.settingsFontCommand("status", [])
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseFont(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.fontState = "failure"; root.fontMessage = error; } } }
    }

    Process {
        id: fontActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const fields = line.split("\t");
                    if (fields[0] === "result") {
                        root.fontMessage = fields.slice(1).join(" ");
                    } else if (fields[0] === "error") {
                        root.fontState = "failure";
                        root.fontMessage = fields.slice(1).join(" ");
                    }
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.fontState = "failure"; root.fontMessage = error; } } }
        onRunningChanged: {
            if (!running) root.refreshFont();
        }
    }

    Process {
        id: iconsProcess
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseIcons(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.iconsState = "failure"; root.iconsMessage = error; } } }
    }

    Process {
        id: iconsActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const fields = line.split("\t");
                    if (fields[0] === "ok") {
                        root.iconsMessage = fields.slice(1).join(" ");
                    } else if (fields[0] === "error") {
                        root.iconsState = "failure";
                        root.iconsMessage = fields.slice(1).join(" ");
                    }
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.iconsState = "failure"; root.iconsMessage = error; } } }
        onRunningChanged: {
            if (!running) root.refreshIcons();
        }
    }

    Process {
        id: picomStatusProcess
        command: Commands.helperCommand("dwm-settings-picom", "status", [], true)
        running: false
        stdout: StdioCollector { onStreamFinished: root.parsePicom(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.picomState = "failure"; root.picomMessage = error; } } }
    }

    Process {
        id: picomActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const text = this.text.trim();
                if (text.length > 0) {
                    root.picomMessage = text.split("\n").slice(-1)[0] || "OK";
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.picomState = "failure"; root.picomMessage = error; } } }
        onRunningChanged: {
            if (!running) root.refreshPicom();
        }
    }

    Process {
        id: appearanceDiscoverProcess
        command: Commands.settingsAppearanceControlCommand("discover")
        running: false
        stdout: StdioCollector { onStreamFinished: root.parseAppearance(this.text) }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.appearanceState = "failure"; root.appearanceMessage = error; } } }
    }

    Process {
        id: appearanceActionProcess
        running: false
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = this.text.trim().split("\n");
                for (const line of lines) {
                    const fields = line.split("\t");
                    if (fields[0] === "ok") {
                        root.appearanceMessage = fields[1] + ": " + fields[2];
                    } else if (fields[0] === "error") {
                        root.appearanceState = "failure";
                        root.appearanceMessage = fields.slice(1).join(" ");
                    }
                }
            }
        }
        stderr: StdioCollector { onStreamFinished: { const error = this.text.trim(); if (error) { root.appearanceState = "failure"; root.appearanceMessage = error; } } }
        onRunningChanged: {
            if (!running) {
                root.refreshAppearance();
                appearanceSnapshotProcess.running = true;
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.previewSeconds > 0
        onTriggered: {
            root.previewSeconds = Math.max(0, root.previewSeconds - 1);
            if (root.previewSeconds === 0) {
				if (root.previewKind === "display") root.pollDisplayPreviewStatus();
				else root.pollInputPreviewStatus();
            }
        }
    }

    Timer {
        id: inputSettleTimer
        interval: 1200
			onTriggered: {
				if (!root.visible || root.selectedSectionId !== "input") return;
				if (inputDiscoverProcess.running) {
					inputSettleTimer.restart();
					return;
				}
				root.refreshInput();
			}
    }
}
