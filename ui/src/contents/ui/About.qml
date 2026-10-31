import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Window {
    id: aboutWindow

    title: i18n("About LINE for KDE")
    color: Lds.bg
    width: Kirigami.Units.gridUnit * 24
    height: Kirigami.Units.gridUnit * 22
    flags: Qt.Dialog

    ColumnLayout {
        anchors.centerIn: parent
        width: Kirigami.Units.gridUnit * 16
        spacing: Lds.gap

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            implicitWidth: Kirigami.Units.gridUnit * 4
            implicitHeight: implicitWidth
            radius: Lds.radius
            color: Lds.green

            QQC2.Label {
                anchors.centerIn: parent
                text: "LINE"
                color: "#ffffff"
                font.pointSize: Lds.bodySize
                font.bold: true
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("LINE for KDE")
            color: Lds.text
            font.pointSize: Lds.bodySize
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("ver %1", AppVersion)
            color: Lds.green
            font.pointSize: Lds.smallSize
            horizontalAlignment: Text.AlignHCenter
        }

        Item {
            implicitHeight: Lds.pad
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Source code")
            color: Lds.textTertiary
            font.pointSize: Lds.smallSize
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://github.com/pyyupsk/line-kde")
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("Report an issue")
            color: Lds.textTertiary
            font.pointSize: Lds.smallSize
            horizontalAlignment: Text.AlignHCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: Qt.openUrlExternally("https://github.com/pyyupsk/line-kde/issues")
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            text: i18n("GPL-2.0-or-later")
            color: Lds.textTertiary
            font.pointSize: Lds.smallSize
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
