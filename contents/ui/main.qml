import QtQuick 2.15
import org.kde.plasma.plasmoid 2.0

WallpaperItem {
    id: root
    anchors.fill: parent

    // ---------------------------------------------------------------------------
    // Configuration bindings (with safe defaults)
    // ---------------------------------------------------------------------------
    property int    fontSize:    root.configuration.fontSize    !== undefined ? root.configuration.fontSize    : 16
    property string fontFamily:  root.configuration.fontFamily  !== undefined ? root.configuration.fontFamily  : "Noto Sans Mono CJK JP"
    property int    speed:       root.configuration.speed       !== undefined ? root.configuration.speed       : 30
    property color  matrixColor: root.configuration.matrixColor !== undefined ? root.configuration.matrixColor : "#00ff41"
    property color  headColor:   root.configuration.headColor   !== undefined ? root.configuration.headColor   : "#ccffcc"
    property real   fadeRate:    root.configuration.fadeRate     !== undefined ? root.configuration.fadeRate     : 0.05
    property bool   mirrorChars: root.configuration.mirrorChars !== undefined ? root.configuration.mirrorChars : true
    property bool   glowEnabled: root.configuration.glowEnabled !== undefined ? root.configuration.glowEnabled : true
    property int    glowRadius:  root.configuration.glowRadius  !== undefined ? root.configuration.glowRadius  : 8
    property int    charSet:     root.configuration.charSet     !== undefined ? root.configuration.charSet     : 0

    // ---------------------------------------------------------------------------
    // Character sets
    // ---------------------------------------------------------------------------
    property var charSets: [
        "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789",
        "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ",
        "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%&*<>="
    ]

    property string chars: charSets[Math.min(charSet, charSets.length - 1)]

    // Number of explicitly-drawn green trail characters behind the head.
    // Beyond this the canvas fade handles the long tail to black.
    property int trailLength: 12

    // Pre-compute matrix green RGB components for trail colour blending
    property int mcR: Math.round(matrixColor.r * 255)
    property int mcG: Math.round(matrixColor.g * 255)
    property int mcB: Math.round(matrixColor.b * 255)

    // ---------------------------------------------------------------------------
    // Canvas renderer
    // ---------------------------------------------------------------------------
    Canvas {
        id: canvas
        anchors.fill: parent

        property var columns: []
        property bool initialized: false

        function randomChar() {
            return root.chars.charAt(Math.floor(Math.random() * root.chars.length));
        }

        // (Re-)initialize column state
        function initColumns() {
            var cols = Math.floor(canvas.width / root.fontSize);
            var rows = Math.floor(canvas.height / root.fontSize);
            columns = [];
            for (var i = 0; i < cols; i++) {
                columns.push({
                    y:     Math.floor(Math.random() * -rows),
                    speed: 0.3 + Math.random() * 1.2,
                    acc:   Math.random(),
                    trail: []   // [{ch, row}] — most recent first
                });
            }
            initialized = true;

            var ctx = getContext("2d");
            if (ctx) {
                ctx.fillStyle = "#000000";
                ctx.fillRect(0, 0, width, height);
            }
        }

        // Draw a single character, optionally mirrored and glowing.
        // When mirrorChars is on, every character goes through save/restore
        // (same pattern as original) but only katakana get the scale flip.
        function drawChar(ctx, ch, x, y, color, glow, mirror) {
            var fs = root.fontSize;

            if (root.mirrorChars) {
                ctx.save();
                ctx.translate(x + fs, y);
                if (mirror) {
                    ctx.scale(-1, 1);
                } else {
                    ctx.textAlign = "right";
                }

                if (glow && root.glowEnabled) {
                    ctx.shadowBlur  = root.glowRadius;
                    ctx.shadowColor = root.matrixColor;
                }

                ctx.fillStyle = color;
                ctx.fillText(ch, 0, 0);

                ctx.shadowBlur = 0;
                ctx.restore();
            } else {
                if (glow && root.glowEnabled) {
                    ctx.shadowBlur  = root.glowRadius;
                    ctx.shadowColor = root.matrixColor;
                }

                ctx.fillStyle = color;
                ctx.fillText(ch, x, y);

                ctx.shadowBlur = 0;
            }
        }

        Timer {
            id: timer
            interval: Math.round(1000 / root.speed)
            running:  true
            repeat:   true
            onTriggered: canvas.requestPaint()
        }

        onWidthChanged:  if (width  > 0 && height > 0) initColumns()
        onHeightChanged: if (width  > 0 && height > 0) initColumns()
        Component.onCompleted: if (width > 0 && height > 0) initColumns()

        // ---------------------------------------------------------------------------
        // Main paint loop
        // ---------------------------------------------------------------------------
        onPaint: {
            if (!initialized || columns.length === 0) return;

            var ctx = getContext("2d");
            if (!ctx) return;

            var w    = width;
            var h    = height;
            var fs   = root.fontSize;
            var rows = Math.floor(h / fs) + 1;
            var tLen = root.trailLength;

            // --- Fade overlay ----------------------------------------------------
            ctx.fillStyle = "rgba(0, 0, 0, " + root.fadeRate.toFixed(3) + ")";
            ctx.fillRect(0, 0, w, h);

            ctx.font         = fs + "px " + root.fontFamily;
            ctx.textBaseline = "top";

            // --- Phase 1: advance state ------------------------------------------
            for (var i = 0; i < columns.length; i++) {
                var col = columns[i];
                col.acc += col.speed;

                while (col.acc >= 1.0) {
                    col.acc -= 1.0;

                    // Push new head character into the trail (tag katakana at creation)
                    var ch = randomChar();
                    var code = ch.charCodeAt(0);
                    col.trail.unshift({ ch: ch, row: col.y, kana: code >= 0xFF66 && code <= 0xFF9F });
                    if (col.trail.length > tLen) col.trail.length = tLen;

                    col.y++;

                    // Reset when far enough off screen
                    if (col.y > rows + Math.floor(Math.random() * rows * 0.4)) {
                        col.y     = Math.floor(Math.random() * -rows * 0.5);
                        col.speed = 0.3 + Math.random() * 1.2;
                        col.trail = [];
                    }
                }
            }

            // --- Phase 2: draw ---------------------------------------------------
            for (var i = 0; i < columns.length; i++) {
                var col = columns[i];
                if (col.trail.length === 0) continue;

                var x = i * fs;

                // Draw green trail (index 1 → end, newest to oldest)
                // Brightness fades linearly from full green to ~30 % green
                for (var t = col.trail.length - 1; t >= 1; t--) {
                    var entry = col.trail[t];
                    var ty    = entry.row * fs;

                    if (ty < 0 || ty > h) continue;

                    var frac = 1.0 - (t / tLen);   // 1.0 (newest) → ~0.0 (oldest)
                    var brightness = 0.3 + frac * 0.7;  // 1.0 → 0.3

                    var cr = Math.round(root.mcR * brightness);
                    var cg = Math.round(root.mcG * brightness);
                    var cb = Math.round(root.mcB * brightness);
                    var color = "rgb(" + cr + "," + cg + "," + cb + ")";

                    drawChar(ctx, entry.ch, x, ty, color, false, entry.kana);
                }

                // Draw head character (index 0) in bright white with glow
                var head = col.trail[0];
                var hy   = head.row * fs;
                if (hy >= 0 && hy <= h) {
                    drawChar(ctx, head.ch, x, hy, root.headColor, true, head.kana);
                }
            }
        }
    }

    // ---------------------------------------------------------------------------
    // React to live configuration changes
    // ---------------------------------------------------------------------------
    onFontSizeChanged:   canvas.initColumns()
    onFontFamilyChanged: canvas.initColumns()
    onSpeedChanged:      timer.interval = Math.round(1000 / root.speed)
    onCharSetChanged:    { root.chars = root.charSets[Math.min(root.charSet, root.charSets.length - 1)]; }
}
