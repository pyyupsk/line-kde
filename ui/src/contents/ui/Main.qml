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

        property string pin: Core.pincode
        property int qrSecondsLeft: 0
        property bool qrExpired: false

        onQrSecondsLeftChanged: qrExpired = qrSecondsLeft <= 0 && Core.status === "waiting"

        Connections {
            target: Core
            function onChanged() {
                if (Core.status === "waiting") {
                    page.qrSecondsLeft = 120;
                    page.qrExpired = false;
                }
            }
        }

        Timer {
            interval: 1000
            repeat: true
            running: Core.status === "waiting" && page.qrSecondsLeft > 0
            onTriggered: page.qrSecondsLeft -= 1
        }

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
                            font.weight: Font.DemiBold
                            font.pointSize: Lds.titleSize
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

        ColumnLayout {
            anchors.centerIn: parent
            width: Kirigami.Units.gridUnit * 15
            visible: Core.status !== "signedIn"
            spacing: Lds.gap

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("LINE")
                color: Lds.green
                font.pointSize: Lds.displaySize
                font.weight: Font.Heavy
                horizontalAlignment: Text.AlignHCenter
            }

            QQC2.Label {
                Layout.fillWidth: true
                text: page.pin.length > 0 ? i18n("One more step") : i18n("QR code login")
                color: Lds.text
                font.pointSize: Lds.headingSize
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            QQC2.Label {
                Layout.fillWidth: true
                visible: page.pin.length === 0
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
                        if (page.qrExpired)
                            return i18n("This QR code is no longer valid. Please update the QR code.");
                        if (Core.pincode.length > 0)
                            return i18n("Enter the PIN %1 on your phone", Core.pincode);
                        return i18n("Open LINE on your phone, tap the QR code icon in the search box, and scan this code");
                    default:
                        return i18n("Sign in with LINE on your phone");
                    }
                }
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: Core.status === "waiting" && page.pin.length === 0
                opacity: page.qrExpired ? 0.25 : 1
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

            QQC2.Label {
                Layout.fillWidth: true
                visible: page.pin.length > 0
                text: i18n("Type this PIN on your phone")
                color: Lds.textSecondary
                font.pointSize: Lds.smallSize
                horizontalAlignment: Text.AlignHCenter
            }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                visible: page.pin.length > 0
                implicitWidth: Kirigami.Units.gridUnit * 11
                implicitHeight: pinLabel.implicitHeight + Lds.pad * 2
                radius: Lds.radius
                color: "transparent"
                border.width: 1
                border.color: Lds.line

                QQC2.Label {
                    id: pinLabel
                    anchors.centerIn: parent
                    text: page.pin
                    color: Lds.text
                    font.pointSize: Lds.displaySize
                    font.weight: Font.Heavy
                    font.letterSpacing: 10
                }
            }

            QQC2.Button {
                Layout.alignment: Qt.AlignHCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 11
                Layout.preferredHeight: Lds.buttonHeight
                visible: Core.status === "idle" || Core.status === "error" || page.qrExpired
                text: page.qrExpired ? i18n("Update") : (Core.status === "error" ? i18n("Try Again") : i18n("Sign In"))
                font.pointSize: Lds.bodySize
                onClicked: Core.restartLogin()

                background: Rectangle {
                    color: Lds.green
                    radius: Lds.radiusSmall
                }

                contentItem: QQC2.Label {
                    text: parent.text
                    color: "#ffffff"
                    font.pointSize: Lds.bodySize
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}
