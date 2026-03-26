import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../common"
import "../../services"
import "."

Scope {
    id: overviewScope
    readonly property var focusedMonitorData: HyprlandData.monitors.find(m => m.focused)
    readonly property string focusedMonitorName: focusedMonitorData?.name ?? Hyprland.focusedMonitor?.name ?? ""

    Variants {
        id: overviewVariants
        model: Quickshell.screens
        PanelWindow {
            id: root
            required property var modelData
            readonly property string screenName: root.screen?.name ?? ""
            readonly property var monitorData: HyprlandData.monitors.find(m => m.name === screenName)
            property bool monitorIsFocused: overviewScope.focusedMonitorName === screenName
            
            screen: modelData
            visible: GlobalStates.overviewOpen && monitorIsFocused

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: monitorIsFocused ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: root.visible ? keyHandler : null
            }

            anchors {
                top: true
                bottom: true
                left: !(Config?.options.overview.enable ?? true)
                right: !(Config?.options.overview.enable ?? true)
            }

            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            Item {
                id: keyHandler
                anchors.fill: parent
                visible: root.visible
                focus: root.visible

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape || event.key === Qt.Key_Return) {
                        GlobalStates.overviewOpen = false;
                        event.accepted = true;
                        return;
                    }

                    const workspacesPerGroup = Config.options.overview.rows * Config.options.overview.columns;
                    const currentId = root.monitorData?.activeWorkspace?.id ?? overviewScope.focusedMonitorData?.activeWorkspace?.id ?? 1;
                    const currentGroup = Math.floor((currentId - 1) / workspacesPerGroup);
                    const minWorkspaceId = currentGroup * workspacesPerGroup + 1;
                    const maxWorkspaceId = minWorkspaceId + workspacesPerGroup - 1;

                    const currentRow = Math.floor((currentId - minWorkspaceId) / Config.options.overview.columns);
                    const rowMinId = minWorkspaceId + currentRow * Config.options.overview.columns;
                    const rowMaxId = rowMinId + Config.options.overview.columns - 1;

                    let targetId = null;

                    if (event.key === Qt.Key_Left || event.key === Qt.Key_H) {
                        targetId = currentId - 1;
                        if (Config.options.overview.hideEmptyRows) {
                            if (targetId < rowMinId) targetId = rowMaxId;
                        } else {
                            if (targetId < minWorkspaceId) targetId = maxWorkspaceId;
                        }
                    } else if (event.key === Qt.Key_Right || event.key === Qt.Key_L) {
                        targetId = currentId + 1;
                        if (Config.options.overview.hideEmptyRows) {
                            if (targetId > rowMaxId) targetId = rowMinId;
                        } else {
                            if (targetId > maxWorkspaceId) targetId = minWorkspaceId;
                        }
                    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_K) {
                        targetId = currentId - Config.options.overview.columns;
                        if (targetId < minWorkspaceId) targetId += workspacesPerGroup;
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_J) {
                        targetId = currentId + Config.options.overview.columns;
                        if (targetId > maxWorkspaceId) targetId -= workspacesPerGroup;
                    } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                        const position = event.key - Qt.Key_0;
                        if (position <= workspacesPerGroup) {
                            targetId = minWorkspaceId + position - 1;
                        }
                    } else if (event.key === Qt.Key_0) {
                        if (workspacesPerGroup >= 10) {
                            targetId = minWorkspaceId + 9;
                        }
                    }

                    if (targetId !== null) {
                        Hyprland.dispatch("workspace " + targetId);
                        event.accepted = true;
                    }
                }
            }

            ColumnLayout {
                id: columnLayout
                visible: root.visible
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: Config.options.position.topMargin
                }

                Loader {
                    id: overviewLoader
                    active: root.visible && (Config?.options.overview.enable ?? true)
                    sourceComponent: OverviewWidget {
                        panelWindow: root
                        visible: true
                    }
                }
            }
        }
    }

    HyprlandFocusGrab {
        id: globalGrab
        windows: overviewVariants.instances.filter(w => w.visible)
        active: false
        onCleared: () => {
            if (!active)
                GlobalStates.overviewOpen = false;
        }
    }

    Connections {
        target: GlobalStates
        function onOverviewOpenChanged() {
            if (GlobalStates.overviewOpen) {
                grabTimer.start();
            } else {
                globalGrab.active = false;
            }
        }
    }

    Timer {
        id: grabTimer
        interval: Config.options.hacks.arbitraryRaceConditionDelay
        repeat: false
        onTriggered: globalGrab.active = GlobalStates.overviewOpen;
    }

    IpcHandler {
        target: "overview"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
    }
}
