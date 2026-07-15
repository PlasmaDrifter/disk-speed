import QtQuick
import QtQuick.Layouts
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.components as PlasmaComponents3
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kirigami as Kirigami

PlasmoidItem {
    id: root

    readonly property color trackColor: plasmoid.configuration.trackColor
    readonly property real smoothingAlpha: Math.max(0.05, Math.min(1, (plasmoid.configuration.smoothingPercent || 30) / 100))
    // Match the bar's glide time to the poll interval so it animates
    // continuously the whole time instead of snapping fast then sitting
    // frozen until the next sample (which reads as jumpy).
    readonly property int animDuration: (plasmoid.configuration.updateInterval || 2) * 1000

    // Smoothed (EMA) read/write throughput per drive, MiB/s.
    property real read1: 0
    property real write1: 0
    property real read2: 0
    property real write2: 0
    property real read3: 0
    property real write3: 0
    property real read4: 0
    property real write4: 0

    // Whether we've received at least one real sample per drive yet, so the
    // first EMA update snaps directly to the instantaneous value instead of
    // blending from a false baseline of 0.
    property var primed: ({})   // { deviceName: true }

    // Previous /proc/diskstats sample per configured device name.
    property var prevStats: ({})   // { deviceName: { read, write, time } }

    function formatRate(mibps) {
        if (mibps >= 1024) return (mibps / 1024).toFixed(2) + " GiB/s"
        return mibps.toFixed(1) + " MiB/s"
    }

    toolTipMainText: ""
    toolTipSubText: ""

    function parseDiskStats(text) {
        var lines = text.split("\n")
        var map = {}
        for (var i = 0; i < lines.length; i++) {
            var parts = lines[i].trim().split(/\s+/)
            if (parts.length < 10) continue
            var devName = parts[2]
            var sectorsRead = parseFloat(parts[5]) || 0
            var sectorsWritten = parseFloat(parts[9]) || 0
            map[devName] = { read: sectorsRead, write: sectorsWritten }
        }
        return map
    }

    // Returns instantaneous {read, write} MiB/s for a device, based on the
    // delta since the previous sample. Updates prevStats as a side effect.
    function instantRateFor(devName, statMap, now) {
        if (!devName || devName.length === 0 || !(devName in statMap)) {
            return { read: 0, write: 0 }
        }

        var cur = statMap[devName]
        var prev = prevStats[devName]
        var result = { read: 0, write: 0 }

        if (prev) {
            var deltaSec = (now - prev.time) / 1000
            var deltaRead = cur.read - prev.read
            var deltaWrite = cur.write - prev.write
            if (deltaSec > 0 && deltaRead >= 0 && deltaWrite >= 0) {
                result.read = (deltaRead * 512) / deltaSec / (1024 * 1024)
                result.write = (deltaWrite * 512) / deltaSec / (1024 * 1024)
            }
        }

        prevStats[devName] = { read: cur.read, write: cur.write, time: now }
        return result
    }

    // Exponential smoothing, but asymmetric: rises are smoothed heavily (to
    // kill jumpiness during bursty writes), while falls are let through much
    // faster so the bar doesn't linger showing "activity" for seconds after
    // the real I/O has actually stopped. A single symmetric EMA can't do
    // both — smoothing rises enough to look steady also makes it decay too
    // slowly, which reads as false/stale info once the drive goes idle.
    readonly property real fallAlpha: 0.75

    function smooth(devName, instantRead, instantWrite, prevRead, prevWrite) {
        if (!(devName in primed)) {
            primed[devName] = true
            return { read: instantRead, write: instantWrite }
        }
        var riseAlpha = smoothingAlpha
        var readAlpha = instantRead < prevRead ? fallAlpha : riseAlpha
        var writeAlpha = instantWrite < prevWrite ? fallAlpha : riseAlpha
        return {
            read: readAlpha * instantRead + (1 - readAlpha) * prevRead,
            write: writeAlpha * instantWrite + (1 - writeAlpha) * prevWrite
        }
    }

    function handleOutput(text) {
        var statMap = parseDiskStats(text)
        var now = Date.now()

        var d1 = plasmoid.configuration.drive1Device
        var d2 = plasmoid.configuration.drive2Device
        var d3 = plasmoid.configuration.drive3Device
        var d4 = plasmoid.configuration.drive4Device

        var i1 = instantRateFor(d1, statMap, now)
        var i2 = instantRateFor(d2, statMap, now)
        var i3 = instantRateFor(d3, statMap, now)
        var i4 = instantRateFor(d4, statMap, now)

        var s1 = smooth(d1, i1.read, i1.write, read1, write1)
        var s2 = smooth(d2, i2.read, i2.write, read2, write2)
        var s3 = smooth(d3, i3.read, i3.write, read3, write3)
        var s4 = smooth(d4, i4.read, i4.write, read4, write4)

        read1 = s1.read; write1 = s1.write
        read2 = s2.read; write2 = s2.write
        read3 = s3.read; write3 = s3.write
        read4 = s4.read; write4 = s4.write
    }

    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        onNewData: (sourceName, data) => {
            var stdout = data["stdout"]
            if (stdout) {
                root.handleOutput(stdout)
            }
            disconnectSource(sourceName)
        }
        function exec(cmd) {
            connectSource(cmd)
        }
    }

    Timer {
        interval: (plasmoid.configuration.updateInterval || 2) * 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: executable.exec("cat /proc/diskstats")
    }

    // A single labeled vertical bar: name on top, stacked read+write segments
    // filling bottom-up (read on the bottom, write on top), rate text below.
    // A single labeled horizontal bar: name on left, rate text on right,
    // progress bar below with stacked read+write segments.
    component HorizontalBar: ColumnLayout {
        id: barRoot
        property string label: ""
        property real readRate: 0
        property real writeRate: 0
        property real maxRate: 100
        property color readColor: "#2ecc71"
        property color writeColor: "#e74c3c"

        readonly property real total: maxRate > 0 ? (readRate + writeRate) / maxRate : 0
        readonly property real scaleFactor: total > 1 ? 1 / total : 1

        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing / 2

        RowLayout {
            Layout.fillWidth: true
            PlasmaComponents3.Label {
                text: barRoot.label
                Layout.fillWidth: true
                elide: Text.ElideRight
            }
            PlasmaComponents3.Label {
                text: root.formatRate(barRoot.readRate + barRoot.writeRate)
                font.bold: true
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 0.55
            radius: height / 2
            color: root.trackColor
            clip: true

            Rectangle {
                id: readSegV
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: parent.radius
                color: barRoot.readColor
                width: barRoot.maxRate > 0
                    ? Math.min(1, (barRoot.readRate / barRoot.maxRate) * barRoot.scaleFactor) * parent.width
                    : 0
                Behavior on width { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
            Rectangle {
                anchors.left: readSegV.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: barRoot.writeColor
                width: barRoot.maxRate > 0
                    ? Math.min(1, (barRoot.writeRate / barRoot.maxRate) * barRoot.scaleFactor) * parent.width
                    : 0
                Behavior on width { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
        }
    }

    fullRepresentation: ColumnLayout {
        id: fullRepItem
        readonly property var appletInterface: Plasmoid.self

        Layout.minimumWidth: Kirigami.Units.gridUnit * 12
        Layout.minimumHeight: Kirigami.Units.gridUnit * 10
        Layout.preferredWidth: plasmoid.configuration.popupWidth
        Layout.preferredHeight: plasmoid.configuration.popupHeight
        Layout.margins: Kirigami.Units.smallSpacing
        spacing: Kirigami.Units.smallSpacing * 2

        onWidthChanged: {
            if (plasmoid.expanded && width >= Layout.minimumWidth && width !== plasmoid.configuration.popupWidth) {
                plasmoid.configuration.popupWidth = width;
            }
        }
        onHeightChanged: {
            if (plasmoid.expanded && height >= Layout.minimumHeight && height !== plasmoid.configuration.popupHeight) {
                plasmoid.configuration.popupHeight = height;
            }
        }

        HorizontalBar {
            label: plasmoid.configuration.drive1Label
            readRate: root.read1
            writeRate: root.write1
            maxRate: plasmoid.configuration.drive1MaxMiB
            readColor: plasmoid.configuration.drive1ReadColor
            writeColor: plasmoid.configuration.drive1WriteColor
        }
        HorizontalBar {
            label: plasmoid.configuration.drive2Label
            readRate: root.read2
            writeRate: root.write2
            maxRate: plasmoid.configuration.drive2MaxMiB
            readColor: plasmoid.configuration.drive2ReadColor
            writeColor: plasmoid.configuration.drive2WriteColor
        }
        HorizontalBar {
            label: plasmoid.configuration.drive3Label
            readRate: root.read3
            writeRate: root.write3
            maxRate: plasmoid.configuration.drive3MaxMiB
            readColor: plasmoid.configuration.drive3ReadColor
            writeColor: plasmoid.configuration.drive3WriteColor
        }
        HorizontalBar {
            label: plasmoid.configuration.drive4Label
            readRate: root.read4
            writeRate: root.write4
            maxRate: plasmoid.configuration.drive4MaxMiB
            readColor: plasmoid.configuration.drive4ReadColor
            writeColor: plasmoid.configuration.drive4WriteColor
        }
    }

    // Small no-label bars for the panel, sized to fit the panel's thickness
    // rather than the fixed barLength (which is used on the desktop).
    compactRepresentation: Item {
        id: compact

        readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical
        readonly property int barThickness: plasmoid.configuration.barThickness
        readonly property int barGap: 4
        readonly property int margin: 4

        Layout.fillHeight: !compact.vertical
        Layout.fillWidth: compact.vertical
        Layout.preferredWidth: compact.vertical ? -1 : (compact.barThickness * 4 + compact.barGap * 3 + compact.margin * 2)
        Layout.preferredHeight: compact.vertical ? (compact.barThickness * 4 + compact.barGap * 3 + compact.margin * 2) : -1
        Layout.minimumWidth: Layout.preferredWidth
        Layout.minimumHeight: Layout.preferredHeight

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.expanded = !root.expanded
        }

        // A single compact segment pair (no label/text), reused 4x below.
        // Deliberately NOT built via Repeater+array-model: reassigning a
        // freshly-built JS array to a Repeater's model every poll makes it
        // destroy and recreate all delegates from scratch, which resets
        // their Behavior animations and causes an instant snap instead of
        // a smooth glide. Explicit named items (like fullRepresentation
        // already uses) keep the same Rectangle instances alive across
        // updates, so the Behaviors actually animate.
        component CompactBarH: Rectangle {
            id: barH
            property real readRate: 0
            property real writeRate: 0
            property real maxRate: 100
            property color readColor: "#2ecc71"
            property color writeColor: "#e74c3c"

            readonly property real total: maxRate > 0 ? (readRate + writeRate) / maxRate : 0
            readonly property real scaleFactor: total > 1 ? 1 / total : 1

            Layout.fillHeight: true
            Layout.preferredWidth: compact.barThickness
            radius: width / 2
            color: root.trackColor
            clip: true

            Rectangle {
                id: readSegH
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                radius: parent.radius
                color: barH.readColor
                height: barH.maxRate > 0
                    ? Math.min(1, (barH.readRate / barH.maxRate) * barH.scaleFactor) * parent.height
                    : 0
                Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: readSegH.top
                color: barH.writeColor
                height: barH.maxRate > 0
                    ? Math.min(1, (barH.writeRate / barH.maxRate) * barH.scaleFactor) * parent.height
                    : 0
                Behavior on height { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
        }

        component CompactBarV: Rectangle {
            id: barV
            property real readRate: 0
            property real writeRate: 0
            property real maxRate: 100
            property color readColor: "#2ecc71"
            property color writeColor: "#e74c3c"

            readonly property real total: maxRate > 0 ? (readRate + writeRate) / maxRate : 0
            readonly property real scaleFactor: total > 1 ? 1 / total : 1

            Layout.fillWidth: true
            Layout.preferredHeight: compact.barThickness
            radius: height / 2
            color: root.trackColor
            clip: true

            Rectangle {
                id: readSegV
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                radius: parent.radius
                color: barV.readColor
                width: barV.maxRate > 0
                    ? Math.min(1, (barV.readRate / barV.maxRate) * barV.scaleFactor) * parent.width
                    : 0
                Behavior on width { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
            Rectangle {
                anchors.left: readSegV.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: barV.writeColor
                width: barV.maxRate > 0
                    ? Math.min(1, (barV.writeRate / barV.maxRate) * barV.scaleFactor) * parent.width
                    : 0
                Behavior on width { NumberAnimation { duration: root.animDuration; easing.type: Easing.Linear } }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: compact.margin
            spacing: compact.barGap
            visible: !compact.vertical

            CompactBarH {
                readRate: root.read1; writeRate: root.write1
                maxRate: plasmoid.configuration.drive1MaxMiB
                readColor: plasmoid.configuration.drive1ReadColor
                writeColor: plasmoid.configuration.drive1WriteColor
            }
            CompactBarH {
                readRate: root.read2; writeRate: root.write2
                maxRate: plasmoid.configuration.drive2MaxMiB
                readColor: plasmoid.configuration.drive2ReadColor
                writeColor: plasmoid.configuration.drive2WriteColor
            }
            CompactBarH {
                readRate: root.read3; writeRate: root.write3
                maxRate: plasmoid.configuration.drive3MaxMiB
                readColor: plasmoid.configuration.drive3ReadColor
                writeColor: plasmoid.configuration.drive3WriteColor
            }
            CompactBarH {
                readRate: root.read4; writeRate: root.write4
                maxRate: plasmoid.configuration.drive4MaxMiB
                readColor: plasmoid.configuration.drive4ReadColor
                writeColor: plasmoid.configuration.drive4WriteColor
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: compact.margin
            spacing: compact.barGap
            visible: compact.vertical

            CompactBarV {
                readRate: root.read1; writeRate: root.write1
                maxRate: plasmoid.configuration.drive1MaxMiB
                readColor: plasmoid.configuration.drive1ReadColor
                writeColor: plasmoid.configuration.drive1WriteColor
            }
            CompactBarV {
                readRate: root.read2; writeRate: root.write2
                maxRate: plasmoid.configuration.drive2MaxMiB
                readColor: plasmoid.configuration.drive2ReadColor
                writeColor: plasmoid.configuration.drive2WriteColor
            }
            CompactBarV {
                readRate: root.read3; writeRate: root.write3
                maxRate: plasmoid.configuration.drive3MaxMiB
                readColor: plasmoid.configuration.drive3ReadColor
                writeColor: plasmoid.configuration.drive3WriteColor
            }
            CompactBarV {
                readRate: root.read4; writeRate: root.write4
                maxRate: plasmoid.configuration.drive4MaxMiB
                readColor: plasmoid.configuration.drive4ReadColor
                writeColor: plasmoid.configuration.drive4WriteColor
            }
        }
    }
}
