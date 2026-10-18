pragma Singleton
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Wayland

/**
 * Wraps the Wayland idle inhibitor. Seeded from Config.options.idle.inhibitByDefault
 * on a new Hyprland instance, otherwise restored from Persistent state.
 */
Singleton {
    id: root

    property alias inhibit: idleInhibitor.enabled
    inhibit: false

    Connections {
        target: Persistent
        function onReadyChanged() {
            if (!Persistent.ready)
                return;
            if (!Persistent.isNewHyprlandInstance) {
                root.inhibit = Persistent.states.idle.inhibit;
            } else {
                root.inhibit = Config.options?.idle?.inhibitByDefault ?? false;
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    Connections {
        target: Config
        function onReadyChanged() {
            if (Config.ready && Persistent.ready && Persistent.isNewHyprlandInstance) {
                root.inhibit = Config.options?.idle?.inhibitByDefault ?? false;
                Persistent.states.idle.inhibit = root.inhibit;
            }
        }
    }

    function toggleInhibit(active = null) {
        if (active !== null) {
            root.inhibit = active;
        } else {
            root.inhibit = !root.inhibit;
        }
        Persistent.states.idle.inhibit = root.inhibit;
    }

    IdleInhibitor {
        id: idleInhibitor
        window: PanelWindow {
            // Inhibitor requires a "visible" surface
            // Actually not lol
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            // Just in case...
            anchors {
                right: true
                bottom: true
            }
            // Make it not interactable
            mask: Region {
                item: null
            }
        }
    }
}
