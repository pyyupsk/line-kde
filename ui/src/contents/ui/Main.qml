import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import com.pyyupsk.linekde

Kirigami.ApplicationWindow {
    id: root

    title: i18n("line-kde")

    minimumWidth: Kirigami.Units.gridUnit * 20
    minimumHeight: Kirigami.Units.gridUnit * 20

    onClosing: App.saveWindowGeometry(root)

    onWidthChanged: saveWindowGeometryTimer.restart()
    onHeightChanged: saveWindowGeometryTimer.restart()
    onXChanged: saveWindowGeometryTimer.restart()
    onYChanged: saveWindowGeometryTimer.restart()

    Component.onCompleted: App.restoreWindowGeometry(root)

    // batching stops page load from overwriting the restored geometry
    Timer {
        id: saveWindowGeometryTimer
        interval: 1000
        onTriggered: App.saveWindowGeometry(root)
    }

    globalDrawer: Kirigami.GlobalDrawer {
        isMenu: !Kirigami.Settings.isMobile
        actions: [
            Kirigami.Action {
                text: i18n("Sign In")
                icon.name: "system-users"
                enabled: Core.status !== "signedIn"
                onTriggered: Core.start()
            },
            Kirigami.Action {
                text: i18n("About line-kde")
                icon.name: "help-about"
                onTriggered: root.pageStack.pushDialogLayer(Qt.resolvedUrl("About.qml"))
            },
            Kirigami.Action {
                text: i18n("Quit")
                icon.name: "application-exit"
                onTriggered: Qt.quit()
            }
        ]
    }

    contextDrawer: Kirigami.ContextDrawer {
        id: contextDrawer
    }

    pageStack.initialPage: page

    Component {
        id: chatComponent

        Kirigami.ScrollablePage {
            ListView {
                model: Core.messages
                clip: true

                delegate: QQC2.Label {
                    required property var modelData
                    width: ListView.view.width
                    text: modelData.text
                    wrapMode: Text.Wrap
                    padding: Kirigami.Units.smallSpacing
                    horizontalAlignment: modelData.mine ? Text.AlignRight : Text.AlignLeft
                }
            }

            Kirigami.PlaceholderMessage {
                anchors.centerIn: parent
                width: parent.width - Kirigami.Units.gridUnit * 4
                visible: Core.messages.length === 0
                icon.name: Core.chatError.length > 0 ? "dialog-error" : "mail-message"
                text: Core.chatError.length > 0 ? Core.chatError : i18n("No messages yet")
            }
        }
    }

    Kirigami.Page {
        id: page

        title: i18n("line-kde")

        Component.onCompleted: Core.start()

        ListView {
            anchors.fill: parent
            visible: Core.status === "signedIn"
            clip: true
            model: Core.chats

            delegate: Delegates.RoundedItemDelegate {
                required property var modelData
                width: ListView.view.width
                text: modelData.name.length > 0 ? modelData.name : modelData.mid
                icon.name: modelData.type === "ROOM" ? "system-users" : "user-group-new"
                onClicked: {
                    Core.openChat(modelData.mid);
                    root.pageStack.push(chatComponent, {
                        title: modelData.name
                    });
                }
            }
        }

        ColumnLayout {
            anchors.centerIn: parent
            visible: Core.status !== "signedIn"
            spacing: Kirigami.Units.largeSpacing

            Image {
                Layout.alignment: Qt.AlignHCenter
                visible: Core.status === "waiting"
                source: Core.qrSource
                sourceSize.width: Kirigami.Units.gridUnit * 10
                fillMode: Image.PreserveAspectFit
                smooth: false
            }

            Kirigami.Heading {
                Layout.alignment: Qt.AlignHCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: {
                    switch (Core.status) {
                    case "signedIn":
                        return i18n("Signed in as %1", Core.userName);
                    case "waiting":
                        return Core.pincode.length > 0 ? i18n("Enter the PIN %1 on your phone", Core.pincode) : i18n("Scan this code with LINE");
                    case "error":
                        return Core.errorText;
                    case "starting":
                        return i18n("Starting…");
                    default:
                        return i18n("Sign in to LINE");
                    }
                }
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                visible: Core.status === "idle" || Core.status === "error"
                text: i18n("Sign In")
                onClicked: Core.start()
            }
        }
    }
}
