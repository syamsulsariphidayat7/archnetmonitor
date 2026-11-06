import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    StyledText {
        Layout.fillWidth: true
        Layout.leftMargin: 10
        Layout.rightMargin: 10
        wrapMode: Text.Wrap
        color: Appearance.colors.colSubtext
        font.pixelSize: Appearance.font.pixelSize.small
        text: Translation.tr("Features specific to this fork: network speed, keep awake, and transparency")
    }

    ContentSection {
        icon: "network_check"
        title: Translation.tr("Net speed")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable")
            checked: Config.options.bar.netSpeed.enable
            onCheckedChanged: {
                Config.options.bar.netSpeed.enable = checked;
            }
        }

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Update interval (ms)")
            value: Config.options.bar.netSpeed.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.bar.netSpeed.updateInterval = value;
            }
        }

        ConfigRow {
            uniform: true
            ConfigSwitch {
                buttonIcon: "speed"
                text: Translation.tr("Bits per second")
                checked: Config.options.bar.netSpeed.bits
                onCheckedChanged: {
                    Config.options.bar.netSpeed.bits = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Show speeds in bits/s (x8) instead of bytes/s")
                }
            }
            ConfigSwitch {
                buttonIcon: "compress"
                text: Translation.tr("Compact labels")
                checked: Config.options.bar.netSpeed.compact
                onCheckedChanged: {
                    Config.options.bar.netSpeed.compact = checked;
                }
                StyledToolTip {
                    text: Translation.tr("Short bar chip labels like 1.2M instead of 1.2 MB/s")
                }
            }
        }

        ContentSubsection {
            title: Translation.tr("Arrow colors")

            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Download color (e.g., #42a5f5)")
                    text: Config.options.bar.netSpeed.downloadColor
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.bar.netSpeed.downloadColor = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Upload color (e.g., #7D9C65)")
                    text: Config.options.bar.netSpeed.uploadColor
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.bar.netSpeed.uploadColor = text;
                    }
                }
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("Monitor to open on click (e.g., btop) - empty disables")
            text: Config.options.bar.netSpeed.monitor
            wrapMode: TextEdit.NoWrap
            onTextChanged: {
                Config.options.bar.netSpeed.monitor = text;
            }
        }
    }

    ContentSection {
        icon: "coffee"
        title: Translation.tr("Idle")

        ConfigSwitch {
            buttonIcon: "coffee"
            text: Translation.tr("Keep awake on boot")
            checked: Config.options.idle.inhibitByDefault
            onCheckedChanged: {
                Config.options.idle.inhibitByDefault = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically keep system awake after reboot or new Hyprland session")
            }
        }
    }

    ContentSection {
        icon: "opacity"
        title: Translation.tr("Transparency")

        ConfigSwitch {
            buttonIcon: "check"
            text: Translation.tr("Enable transparency")
            checked: Config.options.appearance.transparency.enable
            onCheckedChanged: {
                Config.options.appearance.transparency.enable = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable transparency for bar, sidebars, and other UI elements")
            }
        }

        ConfigSwitch {
            buttonIcon: "auto_awesome"
            text: Translation.tr("Automatic transparency")
            enabled: Config.options.appearance.transparency.enable
            checked: Config.options.appearance.transparency.automatic
            onCheckedChanged: {
                Config.options.appearance.transparency.automatic = checked;
            }
            StyledToolTip {
                text: Translation.tr("Automatically adjust transparency based on wallpaper vibrancy")
            }
        }

        ContentSubsection {
            title: Translation.tr("Manual settings")
            enabled: Config.options.appearance.transparency.enable &&
                     !Config.options.appearance.transparency.automatic

            ConfigSpinBox {
                icon: "opacity"
                text: Translation.tr("Background transparency (%)")
                value: Config.options.appearance.transparency.backgroundTransparency * 100
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.appearance.transparency.backgroundTransparency = value / 100;
                }
                StyledToolTip {
                    text: Translation.tr("Affects bar, sidebars, overlays")
                }
            }

            ConfigSpinBox {
                icon: "layers"
                text: Translation.tr("Content transparency (%)")
                value: Config.options.appearance.transparency.contentTransparency * 100
                from: 0
                to: 100
                stepSize: 5
                onValueChanged: {
                    Config.options.appearance.transparency.contentTransparency = value / 100;
                }
                StyledToolTip {
                    text: Translation.tr("Affects buttons, cards, popups")
                }
            }
        }

        ContentSubsection {
            id: presetsSection
            title: Translation.tr("Quick presets")
            tooltip: Translation.tr("Balanced combinations of background + content transparency")
            enabled: Config.options.appearance.transparency.enable &&
                     !Config.options.appearance.transparency.automatic

            readonly property real bgValue: Config.options.appearance.transparency.backgroundTransparency
            readonly property real contentValue: Config.options.appearance.transparency.contentTransparency
            readonly property int bgPercent: Math.round(bgValue * 100)
            readonly property int contentPercent: Math.round(contentValue * 100)

            function matchesPreset(bg, content) {
                return Math.abs(bgValue - bg) < 0.01 && Math.abs(contentValue - content) < 0.01;
            }

            readonly property bool isSubtle: matchesPreset(0.15, 0.25)
            readonly property bool isLight: matchesPreset(0.35, 0.40)
            readonly property bool isMedium: matchesPreset(0.60, 0.50)
            readonly property bool isHeavy: matchesPreset(0.80, 0.60)
            readonly property bool matchesAnyPreset: isSubtle || isLight || isMedium || isHeavy

            function presetIcon(active) {
                return active ? "radio_button_checked" : "radio_button_unchecked";
            }

            function presetColor(active) {
                return active ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2;
            }

            readonly property string statusText: getStatusText()

            function getStatusText() {
                if (matchesAnyPreset)
                    return Translation.tr("Background = bar/sidebar, content = buttons/cards inside");
                return Translation.tr("Custom: background %1%, content %2%").arg(bgPercent).arg(
                            contentPercent);
            }

            ConfigRow {
                uniform: true
                RippleButtonWithIcon {
                    materialIcon: presetsSection.presetIcon(presetsSection.isSubtle)
                    mainText: Translation.tr("Subtle")
                    colBackground: presetsSection.presetColor(presetsSection.isSubtle)
                    onClicked: {
                        Config.options.appearance.transparency.backgroundTransparency = 0.15;
                        Config.options.appearance.transparency.contentTransparency = 0.25;
                    }
                    StyledToolTip {
                        text: Translation.tr("Background 15%, content 25% - minimal transparency, solid look")
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: presetsSection.presetIcon(presetsSection.isLight)
                    mainText: Translation.tr("Light")
                    colBackground: presetsSection.presetColor(presetsSection.isLight)
                    onClicked: {
                        Config.options.appearance.transparency.backgroundTransparency = 0.35;
                        Config.options.appearance.transparency.contentTransparency = 0.40;
                    }
                    StyledToolTip {
                        text: Translation.tr("Background 35%, content 40% - noticeable but readable")
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: presetsSection.presetIcon(presetsSection.isMedium)
                    mainText: Translation.tr("Medium")
                    colBackground: presetsSection.presetColor(presetsSection.isMedium)
                    onClicked: {
                        Config.options.appearance.transparency.backgroundTransparency = 0.60;
                        Config.options.appearance.transparency.contentTransparency = 0.50;
                    }
                    StyledToolTip {
                        text: Translation.tr("Background 60%, content 50% - balanced transparency")
                    }
                }
                RippleButtonWithIcon {
                    materialIcon: presetsSection.presetIcon(presetsSection.isHeavy)
                    mainText: Translation.tr("Heavy")
                    colBackground: presetsSection.presetColor(presetsSection.isHeavy)
                    onClicked: {
                        Config.options.appearance.transparency.backgroundTransparency = 0.80;
                        Config.options.appearance.transparency.contentTransparency = 0.60;
                    }
                    StyledToolTip {
                        text: Translation.tr("Background 80%, content 60% - very transparent")
                    }
                }
            }

            RowLayout {
                Layout.topMargin: 5
                StyledText {
                    Layout.leftMargin: 10
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    color: Appearance.colors.colSubtext
                    font.pixelSize: Appearance.font.pixelSize.smallie
                    text: presetsSection.statusText
                }
            }
        }
    }
}
