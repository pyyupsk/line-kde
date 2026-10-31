import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import com.pyyupsk.linekde

Window {
    id: aboutWindow

    title: i18n("About LINE for KDE")
    color: Lds.bg
    width: Kirigami.Units.gridUnit * 24
    height: Kirigami.Units.gridUnit * 22
    flags: Qt.Dialog

    Component.onCompleted: App.restoreWindowGeometry(aboutWindow, "about")
    onClosing: App.saveWindowGeometry(aboutWindow, "about")
    onWidthChanged: geometryTimer.restart()
    onHeightChanged: geometryTimer.restart()
    onXChanged: geometryTimer.restart()
    onYChanged: geometryTimer.restart()

    Timer {
        id: geometryTimer
        interval: 1000
        onTriggered: App.saveWindowGeometry(aboutWindow, "about")
    }

    ColumnLayout {
        id: layout
        anchors.centerIn: parent
        width: Kirigami.Units.gridUnit * 16
        spacing: Lds.gap

        Image {
            Layout.alignment: Qt.AlignHCenter
            source: Qt.resolvedUrl("assets/line-logo.svg")
            sourceSize.width: Kirigami.Units.gridUnit * 4
            fillMode: Image.PreserveAspectFit
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
