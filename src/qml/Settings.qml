import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root
    objectName: "SettingsPage"
    title: qsTr("Settings")

    Label {
        anchors.centerIn: parent
        text: root.title
    }
}
