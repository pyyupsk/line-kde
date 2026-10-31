import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import com.pyyupsk.linekde

Kirigami.ApplicationWindow {
    id: root

    title: i18n("LINE for KDE")
    color: Lds.bg

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
                text: i18n("Sign Out")
                icon.name: "system-log-out"
                enabled: Core.status === "signedIn"
                onTriggered: {
                    Core.signOut();
                    if (root.pageStack.depth > 1) {
                        root.pageStack.pop(root.pageStack.initialPage);
                    }
                }
            },
            Kirigami.Action {
                text: i18n("About LINE for KDE")
                icon.name: "help-about"
                onTriggered: aboutWindow.show()
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

    About {
        id: aboutWindow
    }

    Settings {
        id: settingsWindow
        onAboutRequested: aboutWindow.show()
    }

    pageStack.initialPage: page




    Component {
        id: chatComponent

        Kirigami.ScrollablePage {
            footer: Rectangle {
                color: Lds.surface
                implicitHeight: composer.implicitHeight + Lds.gap * 2

                RowLayout {
                    id: composer
                    anchors.fill: parent
                    anchors.margins: Lds.gap
                    spacing: Lds.gap

                    QQC2.TextField {
                        id: composerField
                        Layout.fillWidth: true
                        placeholderText: i18n("Message")
                        font.pointSize: Lds.bodySize
                        background: Rectangle {
                            color: Lds.surfaceAlt
                            radius: height / 2
                            border.width: 1
                            border.color: composerField.activeFocus ? Lds.green : Lds.line
                        }
                        onAccepted: sendButton.send()
                    }

                    QQC2.Button {
                        id: sendButton
                        Layout.preferredWidth: implicitHeight
                        Layout.preferredHeight: Kirigami.Units.gridUnit * 2
                        enabled: composerField.text.length > 0
                        icon.name: "document-send"
                        onClicked: send()
                        background: Rectangle {
                            color: sendButton.enabled ? Lds.green : Lds.surfaceAlt
                            radius: height / 2
                        }
                        contentItem: Kirigami.Icon {
                            source: "document-send"
                            color: "#ffffff"
                            isMask: true
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: implicitWidth
                        }

                        function send() {
                            Core.sendMessage(composerField.text);
                            composerField.text = "";
                        }
                    }
                }
            }

            ListView {
                model: Core.messages
                clip: true
                spacing: Lds.gap
                topMargin: Lds.pad
                bottomMargin: Lds.pad

                section.property: "day"
                section.delegate: QQC2.Label {
                    width: ListView.view ? ListView.view.width : 0
                    horizontalAlignment: Text.AlignHCenter
                    text: section
                    color: Lds.textTertiary
                    font.pointSize: Lds.smallSize
                    topPadding: Lds.gap
                    bottomPadding: Lds.gap
                }

                onCountChanged: positionViewAtEnd()

                delegate: RowLayout {
                    id: bubbleRow
                    required property var modelData
                    width: ListView.view.width
                    layoutDirection: modelData.mine ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: Lds.gap

                    Rectangle {
                        visible: !bubbleRow.modelData.mine
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: Kirigami.Units.gridUnit * 2
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: Lds.line

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: bubbleRow.modelData.fromName.charAt(0).toUpperCase()
                            color: Lds.textSecondary
                            font.bold: true
                            font.pointSize: Lds.smallSize
                        }
                    }

                    ColumnLayout {
                        Layout.maximumWidth: bubbleRow.width * 0.68
                        spacing: 4

                        QQC2.Label {
                            visible: !bubbleRow.modelData.mine
                            text: bubbleRow.modelData.fromName
                            color: Lds.textSecondary
                            font.pointSize: Lds.smallSize
                        }

                        Rectangle {
                            implicitWidth: Math.min(bubbleText.implicitWidth + Lds.pad * 2, bubbleRow.width * 0.68)
                            implicitHeight: bubbleText.implicitHeight + Lds.pad
                            radius: Lds.radius

                            color: bubbleRow.modelData.mine ? Lds.green : Lds.surfaceAlt

                            QQC2.Label {
                                id: bubbleText
                                anchors.fill: parent
                                anchors.margins: Lds.pad / 2
                                text: bubbleRow.modelData.text
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                color: bubbleRow.modelData.mine ? "#ffffff" : Lds.text
                                font.pointSize: Lds.bodySize
                            }
                        }

                        QQC2.Label {
                            text: Qt.formatTime(new Date(bubbleRow.modelData.time), "HH:mm")
                            color: Lds.textTertiary
                            font.pointSize: Lds.smallSize
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

        title: i18n("LINE for KDE")

        actions: [
            Kirigami.Action {
                text: i18n("Settings")
                icon.name: "settings-configure"
                onTriggered: settingsWindow.show()
            },
            Kirigami.Action {
                text: i18n("About")
                icon.name: "help-about"
                onTriggered: aboutWindow.show()
            }
        ]

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
                leftPadding: Lds.pad
                rightPadding: Lds.pad
                topPadding: Lds.gap
                bottomPadding: Lds.gap

                contentItem: RowLayout {
                    spacing: Lds.gap

                    Rectangle {
                        implicitWidth: Kirigami.Units.gridUnit * 2.75
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: Lds.line

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: chatRow.modelData.name.charAt(0).toUpperCase()
                            color: Lds.textSecondary
                            font.bold: true
                            font.pointSize: Lds.bodySize
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.name.length > 0 ? chatRow.modelData.name : chatRow.modelData.mid
                            color: Lds.text
                            font.bold: true
                            font.pointSize: Lds.bodySize
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.lastText
                            textFormat: Text.PlainText
                            color: Lds.textSecondary
                            font.pointSize: Lds.smallSize
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        spacing: 4

                        QQC2.Label {
                            Layout.alignment: Qt.AlignRight
                            text: chatRow.modelData.lastTime > 0 ? Qt.formatTime(new Date(chatRow.modelData.lastTime), "HH:mm") : ""
                            color: Lds.textTertiary
                            font.pointSize: Lds.smallSize
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: chatRow.modelData.unread > 0
                            implicitWidth: unreadLabel.implicitWidth + Lds.gap
                            implicitHeight: unreadLabel.implicitHeight + 4
                            radius: height / 2
                            color: Lds.green

                            QQC2.Label {
                                id: unreadLabel
                                anchors.centerIn: parent
                                text: chatRow.modelData.unread
                                color: "#ffffff"
                                font.pointSize: Lds.smallSize
                                font.bold: true
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

        RowLayout {
            anchors.fill: parent
            visible: Core.status !== "signedIn"
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 3

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 17
                    spacing: Lds.gap

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "LINE"
                        color: Lds.green
                        font.pointSize: 26
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        enabled: false
                        placeholderText: i18n("Email address")
                        font.pointSize: Lds.bodySize
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        enabled: false
                        placeholderText: i18n("Password")
                        echoMode: TextInput.Password
                        font.pointSize: Lds.bodySize
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        enabled: false
                        text: i18n("Log in")
                        font.pointSize: Lds.bodySize
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: i18n("LINE for KDE signs in with a QR code only, so no password is ever stored")
                        color: Lds.textTertiary
                        font.pointSize: Lds.smallSize
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Lds.line
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 14
                    spacing: Lds.gap

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("QR code login")
                        color: Lds.text
                        font.pointSize: Lds.headingSize
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: Lds.textSecondary
                        font.pointSize: Lds.smallSize
                        text: {
                            switch (Core.status) {
                            case "error":
                                return Core.errorText;
                            case "starting":
                                return i18n("Starting…");
                            case "waiting":
                                return Core.pincode.length > 0 ? i18n("Enter the PIN %1 on your phone", Core.pincode) : i18n("Open LINE on your phone, tap the QR code icon in the search box, and scan this code");
                            default:
                                return i18n("Sign in with LINE on your phone");
                            }
                        }
                    }

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        visible: Core.status === "waiting"
                        implicitWidth: Kirigami.Units.gridUnit * 11
                        implicitHeight: implicitWidth
                        radius: Lds.radius
                        color: "#ffffff"

                        Image {
                            anchors.fill: parent
                            anchors.margins: Lds.gap
                            source: Core.qrSource
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }

                    QQC2.Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: Core.status === "idle" || Core.status === "error"
                        text: Core.status === "error" ? i18n("Try Again") : i18n("Sign In")
                        font.pointSize: Lds.bodySize
                        onClicked: Core.start()
                    }
                }
            }
        }
    }
}
