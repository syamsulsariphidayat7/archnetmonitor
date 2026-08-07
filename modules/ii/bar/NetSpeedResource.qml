import qs.modules.common
import qs.modules.common.widgets
import qs.services
import QtQuick
import QtQuick.Layouts
import Quickshell

// Compact, always-visible net speed chip for the Resources widget in the bar.
// Styled after Resource.qml but shows distinct colored ↓/↑ arrows with fixed
// width number slots (reserved via TextMetrics for the largest expected
// string, e.g. "150 MB/s") so the chip never resizes and the bar stays stable.
Item {
    id: root
    implicitWidth: rowLayout.implicitWidth
    implicitHeight: Appearance.sizes.barHeight
    visible: Config?.options.bar.netSpeed.enable ?? true

    property color downloadColor: Config?.options.bar.netSpeed.downloadColor ?? "#42a5f5"
    property color uploadColor: Config?.options.bar.netSpeed.uploadColor ?? "#ffa726"

    // Largest number we reserve room for. Bump if your link can exceed it.
    property string reserveUnitText: {
        const bits = Config?.options.bar.netSpeed.bits ?? false;
        const compact = Config?.options.bar.netSpeed.compact ?? false;
        return compact ? "150M" : `150 ${bits ? "Mb/s" : "MB/s"}`;
    }

    RowLayout {
        id: rowLayout
        spacing: 2
        anchors.verticalCenter: parent.verticalCenter

        MaterialSymbol {
            font.weight: Font.DemiBold
            fill: 1
            text: "arrow_downward"
            iconSize: Appearance.font.pixelSize.normal
            color: root.downloadColor
        }
        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: downReserveMetrics.width
            implicitHeight: downText.implicitHeight
            clip: true

            TextMetrics {
                id: downReserveMetrics
                text: root.reserveUnitText
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.small
                }
            }
            StyledText {
                id: downText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: Config?.options.bar.netSpeed.compact ?? false
                    ? NetSpeed.downloadTextCompact : NetSpeed.downloadText
            }
        }

        MaterialSymbol {
            font.weight: Font.DemiBold
            fill: 1
            text: "arrow_upward"
            iconSize: Appearance.font.pixelSize.normal
            color: root.uploadColor
        }
        Item {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: upReserveMetrics.width
            implicitHeight: upText.implicitHeight
            clip: true

            TextMetrics {
                id: upReserveMetrics
                text: root.reserveUnitText
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.small
                }
            }
            StyledText {
                id: upText
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                color: Appearance.colors.colOnLayer1
                font.pixelSize: Appearance.font.pixelSize.small
                text: Config?.options.bar.netSpeed.compact ?? false
                    ? NetSpeed.uploadTextCompact : NetSpeed.uploadText
            }
        }
    }

    MouseArea {
        id: clickArea
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton

        onClicked: {
            const monitor = Config?.options.bar.netSpeed.monitor;
            if (!monitor)
                return;
            Quickshell.execDetached(["bash", "-c", `${Config.options.apps.terminal} -e ${monitor}`]);
        }
    }
}
