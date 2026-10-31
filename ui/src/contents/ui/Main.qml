import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.kirigamiaddons.delegates as Delegates
import com.pyyupsk.linekde

Kirigami.ApplicationWindow {
    id: root

    // LINE Design System palette and scale (designsystem.line.me/LDSM)
    QtObject {
        id: lds

        readonly property color green: "#06c755"
        readonly property color blue: "#4d73ff"
        readonly property color red: "#ff334b"
        readonly property color bg: "#1a1a1a"
        readonly property color surface: "#1f1f1f"
        readonly property color surfaceAlt: "#2a2a2a"
        readonly property color line: "#3f3f3f"
        readonly property color text: "#ffffff"
        readonly property color textSecondary: "#c8c8c8"
        readonly property color textTertiary: "#949494"
        readonly property int radius: 12
        readonly property int radiusSmall: 8
        readonly property int gap: 12
        readonly property int pad: 16
        readonly property int headingSize: 20
        readonly property int bodySize: 15
        readonly property int smallSize: 12
    }

    title: i18n("LINE for KDE")
    color: lds.bg

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
        id: settingsComponent

        Kirigami.ScrollablePage {
            title: i18n("Settings")

            ColumnLayout {
                spacing: 0

                Delegates.RoundedItemDelegate {
                    Layout.fillWidth: true
                    text: i18n("Language")
                    icon.name: "set-language"
                    contentItem: RowLayout {
                        spacing: lds.gap

                        Kirigami.Icon {
                            source: "set-language"
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: implicitWidth
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("Language")
                            color: lds.text
                            font.pointSize: lds.bodySize
                        }

                        QQC2.Label {
                            text: i18n("English")
                            color: lds.textTertiary
                            font.pointSize: lds.bodySize
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: lds.line
                }

                Delegates.RoundedItemDelegate {
                    Layout.fillWidth: true
                    onClicked: root.pageStack.pushDialogLayer(Qt.resolvedUrl("About.qml"))

                    contentItem: RowLayout {
                        spacing: lds.gap

                        Kirigami.Icon {
                            source: "help-about"
                            implicitWidth: Kirigami.Units.iconSizes.smallMedium
                            implicitHeight: implicitWidth
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: i18n("About LINE for KDE")
                            color: lds.text
                            font.pointSize: lds.bodySize
                        }

                        Kirigami.Icon {
                            source: "arrow-right"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: implicitWidth
                        }
                    }
                }
            }
        }
    }

    Component {
        id: chatComponent

        Kirigami.ScrollablePage {
            footer: Rectangle {
                color: lds.surface
                implicitHeight: composer.implicitHeight + lds.gap * 2

                RowLayout {
                    id: composer
                    anchors.fill: parent
                    anchors.margins: lds.gap
                    spacing: lds.gap

                    QQC2.TextField {
                        id: composerField
                        Layout.fillWidth: true
                        placeholderText: i18n("Message")
                        font.pointSize: lds.bodySize
                        background: Rectangle {
                            color: lds.surfaceAlt
                            radius: height / 2
                            border.width: 1
                            border.color: composerField.activeFocus ? lds.green : lds.line
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
                            color: sendButton.enabled ? lds.green : lds.surfaceAlt
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
                spacing: lds.gap
                topMargin: lds.pad
                bottomMargin: lds.pad

                section.property: "day"
                section.delegate: QQC2.Label {
                    width: ListView.view ? ListView.view.width : 0
                    horizontalAlignment: Text.AlignHCenter
                    text: section
                    color: lds.textTertiary
                    font.pointSize: lds.smallSize
                    topPadding: lds.gap
                    bottomPadding: lds.gap
                }

                onCountChanged: positionViewAtEnd()

                delegate: RowLayout {
                    id: bubbleRow
                    required property var modelData
                    width: ListView.view.width
                    layoutDirection: modelData.mine ? Qt.RightToLeft : Qt.LeftToRight
                    spacing: lds.gap

                    Rectangle {
                        visible: !bubbleRow.modelData.mine
                        Layout.alignment: Qt.AlignTop
                        implicitWidth: Kirigami.Units.gridUnit * 2
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: lds.line

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: bubbleRow.modelData.fromName.charAt(0).toUpperCase()
                            color: lds.textSecondary
                            font.bold: true
                            font.pointSize: lds.smallSize
                        }
                    }

                    ColumnLayout {
                        Layout.maximumWidth: bubbleRow.width * 0.68
                        spacing: 4

                        QQC2.Label {
                            visible: !bubbleRow.modelData.mine
                            text: bubbleRow.modelData.fromName
                            color: lds.textSecondary
                            font.pointSize: lds.smallSize
                        }

                        Rectangle {
                            implicitWidth: Math.min(bubbleText.implicitWidth + lds.pad * 2, bubbleRow.width * 0.68)
                            implicitHeight: bubbleText.implicitHeight + lds.pad
                            radius: lds.radius

                            color: bubbleRow.modelData.mine ? lds.green : lds.surfaceAlt

                            QQC2.Label {
                                id: bubbleText
                                anchors.fill: parent
                                anchors.margins: lds.pad / 2
                                text: bubbleRow.modelData.text
                                textFormat: Text.PlainText
                                wrapMode: Text.Wrap
                                color: bubbleRow.modelData.mine ? "#ffffff" : lds.text
                                font.pointSize: lds.bodySize
                            }
                        }

                        QQC2.Label {
                            text: Qt.formatTime(new Date(bubbleRow.modelData.time), "HH:mm")
                            color: lds.textTertiary
                            font.pointSize: lds.smallSize
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
                onTriggered: root.pageStack.push(settingsComponent, { title: i18n("Settings") })
            },
            Kirigami.Action {
                text: i18n("About")
                icon.name: "help-about"
                onTriggered: root.pageStack.pushDialogLayer(Qt.resolvedUrl("About.qml"))
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
                leftPadding: lds.pad
                rightPadding: lds.pad
                topPadding: lds.gap
                bottomPadding: lds.gap

                contentItem: RowLayout {
                    spacing: lds.gap

                    Rectangle {
                        implicitWidth: Kirigami.Units.gridUnit * 2.75
                        implicitHeight: implicitWidth
                        radius: width / 2
                        color: lds.line

                        QQC2.Label {
                            anchors.centerIn: parent
                            text: chatRow.modelData.name.charAt(0).toUpperCase()
                            color: lds.textSecondary
                            font.bold: true
                            font.pointSize: lds.bodySize
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.name.length > 0 ? chatRow.modelData.name : chatRow.modelData.mid
                            color: lds.text
                            font.bold: true
                            font.pointSize: lds.bodySize
                            elide: Text.ElideRight
                        }

                        QQC2.Label {
                            Layout.fillWidth: true
                            text: chatRow.modelData.lastText
                            textFormat: Text.PlainText
                            color: lds.textSecondary
                            font.pointSize: lds.smallSize
                            elide: Text.ElideRight
                        }
                    }

                    ColumnLayout {
                        spacing: 4

                        QQC2.Label {
                            Layout.alignment: Qt.AlignRight
                            text: chatRow.modelData.lastTime > 0 ? Qt.formatTime(new Date(chatRow.modelData.lastTime), "HH:mm") : ""
                            color: lds.textTertiary
                            font.pointSize: lds.smallSize
                        }

                        Rectangle {
                            Layout.alignment: Qt.AlignRight
                            visible: chatRow.modelData.unread > 0
                            implicitWidth: unreadLabel.implicitWidth + lds.gap
                            implicitHeight: unreadLabel.implicitHeight + 4
                            radius: height / 2
                            color: lds.green

                            QQC2.Label {
                                id: unreadLabel
                                anchors.centerIn: parent
                                text: chatRow.modelData.unread
                                color: "#ffffff"
                                font.pointSize: lds.smallSize
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
                    spacing: lds.gap

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: "LINE"
                        color: lds.green
                        font.pointSize: 26
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        enabled: false
                        placeholderText: i18n("Email address")
                        font.pointSize: lds.bodySize
                    }

                    QQC2.TextField {
                        Layout.fillWidth: true
                        enabled: false
                        placeholderText: i18n("Password")
                        echoMode: TextInput.Password
                        font.pointSize: lds.bodySize
                    }

                    QQC2.Button {
                        Layout.fillWidth: true
                        enabled: false
                        text: i18n("Log in")
                        font.pointSize: lds.bodySize
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: i18n("LINE for KDE signs in with a QR code only, so no password is ever stored")
                        color: lds.textTertiary
                        font.pointSize: lds.smallSize
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: lds.line
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 2

                ColumnLayout {
                    anchors.centerIn: parent
                    width: Kirigami.Units.gridUnit * 14
                    spacing: lds.gap

                    QQC2.Label {
                        Layout.fillWidth: true
                        text: i18n("QR code login")
                        color: lds.text
                        font.pointSize: lds.headingSize
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                    }

                    QQC2.Label {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        color: lds.textSecondary
                        font.pointSize: lds.smallSize
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
                        radius: lds.radius
                        color: "#ffffff"

                        Image {
                            anchors.fill: parent
                            anchors.margins: lds.gap
                            source: Core.qrSource
                            fillMode: Image.PreserveAspectFit
                            smooth: false
                        }
                    }

                    QQC2.Button {
                        Layout.alignment: Qt.AlignHCenter
                        visible: Core.status === "idle" || Core.status === "error"
                        text: Core.status === "error" ? i18n("Try Again") : i18n("Sign In")
                        font.pointSize: lds.bodySize
                        onClicked: Core.start()
                    }
                }
            }
        }
    }
}
