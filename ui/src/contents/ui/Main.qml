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
            footer: RowLayout {
                spacing: Kirigami.Units.smallSpacing

                QQC2.TextField {
                    id: composer
                    Layout.fillWidth: true
                    placeholderText: i18n("Message")
                    onAccepted: sendButton.send()
                }

                QQC2.Button {
                    id: sendButton
                    icon.name: "document-send"
                    enabled: composer.text.length > 0
                    onClicked: send()
                    function send() {
                        Core.sendMessage(composer.text);
                        composer.text = "";
                    }
                }
            }

            ListView {
                model: Core.messages
                clip: true

                section.property: "day"
                section.delegate: QQC2.Label {
                    width: ListView.view ? ListView.view.width : 0
                    horizontalAlignment: Text.AlignHCenter
                    text: section
                    font: Kirigami.Theme.smallFont
                    opacity: 0.6
                    topPadding: Kirigami.Units.smallSpacing
                }

                onCountChanged: positionViewAtEnd()

                delegate: RowLayout {
                    id: bubbleRow
                    required property var modelData
                    width: ListView.view.width
                    layoutDirection: modelData.mine ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: Kirigami.Units.smallSpacing

                    Rectangle {
                        visible: !bubbleRow.modelData.mine
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: Kirigami.Units.gridUnit * 2
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: Kirigami.Theme.alternateBackgroundColor

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: bubbleRow.modelData.fromName.charAt(0).toUpperCase()
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.maximumWidth: bubbleRow.width * 0.7
                        spacing: Kirigami.Units.smallSpacing / 2

                        QQC2.Label {
                            visible: !bubbleRow.modelData.mine
                            text: bubbleRow.modelData.fromName
                            font: Kirigami.Theme.smallFont
                            opacity: 0.7
                        }

                        Rectangle {
                            implicitWidth: Math.min(bubbleText.implicitWidth + Kirigami.Units.largeSpacing * 2, bubbleRow.width * 0.7)
                            implicitHeight: bubbleText.implicitHeight + Kirigami.Units.smallSpacing * 5
                            radius: Kirigami.Units.largeSpacing
                            color: bubbleRow.modelData.mine ? "#06c755" : Kirigami.Theme.alternateBackgroundColor

                            QQC2.Label {
                                id: bubbleText
                                anchors.fill: parent
                                anchors.margins: Kirigami.Units.smallSpacing * 2
                                text: bubbleRow.modelData.text
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                color: bubbleRow.modelData.mine ? "#ffffff" : Kirigami.Theme.textColor
                            }
                        }

                        QQC2.Label {
                            text: Qt.formatTime(new Date(bubbleRow.modelData.time), "HH:mm")
                            font: Kirigami.Theme.smallFont
                            opacity: 0.55
                        }
                    }
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
                id: chatRow
                required property var modelData
                width: ListView.view.width

                contentItem: RowLayout {
                    spacing: Kirigami.Units.largeSpacing

                    Rectangle {
                        implicitWidth: Kirigami.Units.gridUnit * 2.5
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: Kirigami.Theme.alternateBackgroundColor

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: chatRow.modelData.name.charAt(0).toUpperCase()
                            font.bold: true
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.name.length > 0 ? chatRow.modelData.name : chatRow.modelData.mid
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.lastText
                            textFormat: Text.PlainText
                            opacity: 0.65
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        spacing: 0

                        QQC2.Label {
                            Layout.alignment: Qt.AlignRight
                            text: chatRow.modelData.lastTime > 0 ? Qt.formatTime(new Date(chatRow.modelData.lastTime), "HH:mm") : ""
                            font: Kirigami.Theme.smallFont
                            opacity: 0.6
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: chatRow.modelData.unread > 0
                            implicitWidth: unreadLabel.implicitWidth + Kirigami.Units.smallSpacing * 2
                            implicitHeight: unreadLabel.implicitHeight + Kirigami.Units.smallSpacing
                            radius: height / 2
                            color: "#06c755"

                            QQC2.Label {
                                id: unreadLabel
                                anchors.centerIn: parent
                                text: chatRow.modelData.unread
                                color: "#ffffff"
                                font: Kirigami.Theme.smallFont
                            }
                        }
                    }
                }

                onClicked: {
                    Core.openChat(chatRow.modelData.mid);
                    root.pageStack.push(chatComponent, {
                        title: chatRow.modelData.name
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
