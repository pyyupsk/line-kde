import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Window {
    id: settingsWindow

    signal aboutRequested()

    title: i18n("Settings")
    color: Lds.bg
    width: Kirigami.Units.gridUnit * 26
    height: Kirigami.Units.gridUnit * 20
    flags: Qt.Dialog

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            Layout.fillWidth: true
            implicitHeight: Lds.pad
        }

        QQC2.Label {
            Layout.fillWidth: true
            Layout.leftMargin: Lds.pad
            text: i18n("Basic")
            color: Lds.textTertiary
            font.pointSize: Lds.smallSize
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Lds.pad
            Layout.rightMargin: Lds.pad
            Layout.topMargin: Lds.gap
            spacing: Lds.gap

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("Language")
                color: Lds.text
                font.pointSize: Lds.bodySize
            }

            QQC2.Label {
                text: i18n("English")
                color: Lds.textTertiary
                font.pointSize: Lds.bodySize
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: Lds.gap
            implicitHeight: 1
            color: Lds.line
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: Lds.pad
            Layout.rightMargin: Lds.pad
            Layout.topMargin: Lds.gap
            spacing: Lds.gap

            QQC2.Label {
                Layout.fillWidth: true
                text: i18n("About LINE for KDE")
                color: Lds.text
                font.pointSize: Lds.bodySize

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: settingsWindow.aboutRequested()
                }
            }

            Kirigami.Icon {
                source: "arrow-right"
                implicitWidth: Kirigami.Units.iconSizes.small
                implicitHeight: implicitWidth
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
