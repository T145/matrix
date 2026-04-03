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
    property string digitFont:   root.configuration.digitFont   !== undefined ? root.configuration.digitFont   : "Hack Nerd Font Mono"
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
        "ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ0123456789Z:\"¦꞊╌-.|+<>*",
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

    // Pre-compute font strings to avoid repeated concatenation in the paint loop
    property string kanaFontStr:  fontSize + "px " + fontFamily
    property string digitFontStr: fontSize + "px " + digitFont

    // Cached fade overlay string — rebuilt reactively only when fadeRate changes
    property string fadeOverlay: "rgba(0,0,0," + fadeRate.toFixed(3) + ")"

    // Pre-computed trail colour look-up table — indexed by trail position.
    // Rebuilt only when matrixColor changes; avoids per-character Math.round()
    // calls and rgb() string concatenation in the paint loop.
    property var trailColorLUT: []
    function rebuildColorLUT() {
        var lut = [];
        var tLen = trailLength;
        var r = mcR, g = mcG, b = mcB;
        for (var t = 0; t < tLen; t++) {
            var frac = 1.0 - (t / tLen);
            var brightness = 0.3 + frac * 0.7;
            lut.push("rgb(" + Math.round(r * brightness) + ","
                            + Math.round(g * brightness) + ","
                            + Math.round(b * brightness) + ")");
        }
        trailColorLUT = lut;
    }
    onMcRChanged: rebuildColorLUT()
    onMcGChanged: rebuildColorLUT()
    onMcBChanged: rebuildColorLUT()
    Component.onCompleted: rebuildColorLUT()

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

        // Draw all characters of one font class (kana or non-kana).
        // Font must already be set on ctx before calling.
        function drawPass(ctx, wantKana, fs, w, h, tLen) {
            var lut = root.trailColorLUT;

            for (var i = 0; i < columns.length; i++) {
                var col = columns[i];
                if (col.trail.length === 0) continue;

                var x = i * fs;

                // Trail characters (index 1 → end)
                for (var t = col.trail.length - 1; t >= 1; t--) {
                    var entry = col.trail[t];
                    if (entry.isKana !== wantKana) continue;

                    var ty = entry.row * fs;
                    if (ty < 0 || ty > h) continue;

                    drawChar(ctx, entry.ch, x, ty, lut[t], false, entry.mirror);
                }

                // Head character (index 0)
                var head = col.trail[0];
                if (head.isKana !== wantKana) continue;
                var hy = head.row * fs;
                if (hy >= 0 && hy <= h) {
                    drawChar(ctx, head.ch, x, hy, root.headColor, true, head.mirror);
                }
            }
        }

        // Draw a single character, center-aligned in its cell,
        // optionally mirrored and glowing.
        // Font must be set by the caller (two-pass draw sets it once per pass).
        // The broken bar (¦) is always right-aligned per the film.
        function drawChar(ctx, ch, x, y, color, glow, mirror) {
            var fs = root.fontSize;
            var rightAlign = (ch === "\u00A6");
            var ax = rightAlign ? x + fs : x + fs * 0.5;
            var align = rightAlign ? "right" : "center";

            if (root.mirrorChars) {
                ctx.save();
                ctx.translate(ax, y);
                ctx.textAlign = align;

                if (mirror) {
                    ctx.scale(-1, 1);
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
                ctx.textAlign = align;

                if (glow && root.glowEnabled) {
                    ctx.shadowBlur  = root.glowRadius;
                    ctx.shadowColor = root.matrixColor;
                }

                ctx.fillStyle = color;
                ctx.fillText(ch, ax, y);

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
            ctx.fillStyle = root.fadeOverlay;
            ctx.fillRect(0, 0, w, h);

            ctx.textBaseline = "top";

            // --- Phase 1: advance state ------------------------------------------
            for (var i = 0; i < columns.length; i++) {
                var col = columns[i];
                col.acc += col.speed;

                while (col.acc >= 1.0) {
                    col.acc -= 1.0;

                    var ch = randomChar();
                    var code = ch.charCodeAt(0);
                    // isKana: true katakana status (for font selection)
                    // mirror: whether to flip horizontally (katakana always, some digits randomly)
                    var isKana = code >= 0xFF66 && code <= 0xFF9F;
                    var isMirrorableDigit = (code >= 0x0032 && code <= 0x0037) || code === 0x0039;
                    col.trail.unshift({
                        ch: ch, row: col.y, isKana: isKana,
                        mirror: isKana || (isMirrorableDigit && Math.random() < 0.5)
                    });
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

            // --- Phase 2: draw (two-pass — font set once per pass) ---------------
            // Pass 1: katakana characters (CJK font — set once)
            ctx.font = root.kanaFontStr;
            drawPass(ctx, true, fs, w, h, tLen);

            // Pass 2: digit/Latin/symbol characters (digit font — set once)
            ctx.font = root.digitFontStr;
            drawPass(ctx, false, fs, w, h, tLen);
        }
    }

    // ---------------------------------------------------------------------------
    // React to live configuration changes
    // ---------------------------------------------------------------------------
    onFontSizeChanged:   canvas.initColumns()
    onFontFamilyChanged: canvas.initColumns()
    onDigitFontChanged:  canvas.initColumns()
    onSpeedChanged:      timer.interval = Math.round(1000 / root.speed)
    onCharSetChanged:    { root.chars = root.charSets[Math.min(root.charSet, root.charSets.length - 1)]; }
}
