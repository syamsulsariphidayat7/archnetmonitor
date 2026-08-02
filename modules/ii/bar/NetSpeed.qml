import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io

Item {
    id: root

    readonly property int updateIntervalMs: Config.options.bar.netSpeed.updateInterval
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real rxBytes: 0
    property real txBytes: 0
    property string netIface: ""
    property string downText: "--"
    property string upText: "--"
    property color color: Appearance.colors.colOnLayer1

    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    visible: Config.options.bar.netSpeed.enable

    function formatSpeed(bytesPerSec) {
        if (!isFinite(bytesPerSec) || bytesPerSec <= 0)
            return "0";
        if (bytesPerSec >= 1024 * 1024 * 1024)
            return (bytesPerSec / (1024 * 1024 * 1024)).toFixed(1) + " GB/s";
        if (bytesPerSec >= 1024 * 1024)
            return (bytesPerSec / (1024 * 1024)).toFixed(1) + " MB/s";
        if (bytesPerSec >= 1024)
            return Math.round(bytesPerSec / 1024) + " KB/s";
        return Math.round(bytesPerSec) + " B/s";
    }

    function parseNetDev(text) {
        const ifacePattern = root.netIface ? new RegExp(`^\\s*${root.netIface}:\\s+(\\d+)\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+\\d+\\s+(\\d+)`) : null;
        for (const line of text.split("\n")) {
            if (ifacePattern) {
                const m = line.match(ifacePattern);
                if (m)
                    return { rx: Number(m[1]), tx: Number(m[2]) };
            } else {
                const m = line.match(/^\s*([a-z0-9]+):\s+(\d+)\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+\d+\s+(\d+)/);
                if (m && m[1] !== "lo")
                    return { rx: Number(m[2]), tx: Number(m[3]) };
            }
        }
        return { rx: 0, tx: 0 };
    }

    Timer {
        id: pollTimer
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            fileNetDev.reload();
            const stats = root.parseNetDev(fileNetDev.text());
            if (root.lastRxBytes > 0 && root.lastTxBytes > 0) {
                root.rxBytes = Math.max(0, stats.rx - root.lastRxBytes);
                root.txBytes = Math.max(0, stats.tx - root.lastTxBytes);
                root.downText = root.formatSpeed(root.rxBytes * 1000 / root.updateIntervalMs);
                root.upText = root.formatSpeed(root.txBytes * 1000 / root.updateIntervalMs);
            }
            root.lastRxBytes = stats.rx;
            root.lastTxBytes = stats.tx;
            interval = root.updateIntervalMs;
        }
    }

    FileView {
        id: fileNetDev
        path: "/proc/net/dev"
    }

    Process {
        id: ifaceProc
        command: ["bash", "-c", "ip route | awk '/^default/ {print $5; exit}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const iface = ifaceProc.text().trim();
                if (iface)
                    root.netIface = iface;
            }
        }
    }

    Connections {
        target: Network
        function onNetworkNameChanged() { ifaceProc.exec(ifaceProc.command); }
    }

    Component.onCompleted: ifaceProc.exec(ifaceProc.command);

    RowLayout {
        id: rowLayout
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        MaterialSymbol {
            text: "arrow_downward"
            iconSize: Appearance.font.pixelSize.smaller
            color: root.color
        }
        StyledText {
            text: root.downText
            color: root.color
            font.pixelSize: Appearance.font.pixelSize.small
        }
        MaterialSymbol {
            Layout.leftMargin: 4
            text: "arrow_upward"
            iconSize: Appearance.font.pixelSize.smaller
            color: root.color
        }
        StyledText {
            text: root.upText
            color: root.color
            font.pixelSize: Appearance.font.pixelSize.small
        }
    }
}
