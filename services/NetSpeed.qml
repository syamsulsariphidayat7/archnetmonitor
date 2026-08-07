pragma Singleton
pragma ComponentBehavior: Bound

import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Polls /proc/net/dev and exposes live download/upload speeds for the
 * default-route interface, plus a formatting helper. Used by the Resources
 * popup so the bar itself stays identical to upstream.
 */
Singleton {
    id: root

    readonly property int updateIntervalMs: Math.max(1, Config?.options.bar.netSpeed.updateInterval ?? 1000)
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real rxBytes: 0
    property real txBytes: 0
    property string netIface: ""
    property string downloadText: "--"
    property string uploadText: "--"
    property string downloadTextCompact: "--"
    property string uploadTextCompact: "--"

    function formatSpeed(bytesPerSec, compact = false) {
        const bits = Config?.options.bar.netSpeed.bits ?? false;
        const value = bits ? bytesPerSec * 8 : bytesPerSec;
        if (!isFinite(value) || value <= 0)
            return "0";

        const gb = 1024 * 1024 * 1024;
        const mb = 1024 * 1024;
        const kb = 1024;

        function scaled(divisor, fullUnit, compactLetter) {
            const num = value / divisor;
            const text = num >= 100 ? String(Math.round(num)) : num.toFixed(1);
            return compact ? text + compactLetter : text + " " + fullUnit + "/s";
        }

        if (value >= gb)
            return scaled(gb, bits ? "Gb" : "GB", "G");
        if (value >= mb)
            return scaled(mb, bits ? "Mb" : "MB", "M");
        if (value >= kb)
            return scaled(kb, bits ? "Kb" : "KB", "K");
        return compact ? String(Math.round(value)) : String(Math.round(value)) + " " + (bits ? "b" : "B") + "/s";
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
        running: Config?.options.bar.netSpeed.enable ?? false
        repeat: true
        onTriggered: {
            fileNetDev.reload();
            const stats = root.parseNetDev(fileNetDev.text());
            if (root.lastRxBytes > 0 && root.lastTxBytes > 0) {
                root.rxBytes = Math.max(0, stats.rx - root.lastRxBytes);
                root.txBytes = Math.max(0, stats.tx - root.lastTxBytes);
                const rxSpeed = root.rxBytes * 1000 / root.updateIntervalMs;
                const txSpeed = root.txBytes * 1000 / root.updateIntervalMs;
                root.downloadText = root.formatSpeed(rxSpeed, false);
                root.uploadText = root.formatSpeed(txSpeed, false);
                root.downloadTextCompact = root.formatSpeed(rxSpeed, true);
                root.uploadTextCompact = root.formatSpeed(txSpeed, true);
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
                const iface = text.trim();
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
}
