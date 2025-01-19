import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

import Qt.labs.platform 1.1

import org.gmp.model 1.0

Page {
    id: root
    objectName: "SettingsPage"
    title: qsTr("Settings")

    padding: 20

    property var settings

    contentItem: ColumnLayout {
        RowLayout {
            Layout.fillWidth: true
            Label {
                text: qsTr("Music directory: %1").arg(MusicIndexer.rootPaths)
            }
            Button {
                text: qsTr("Change...")
                onClicked: folderDialog.open()
            }
        }
        // RowLayout {
        //     Layout.fillWidth: true
        //     Label {
        //         text: qsTr("Volume:")
        //     }
        //     Slider {
        //         Layout.fillWidth: true
        //         id: volumeSlider
        //         // readonly property real volume: QtMultimedia.convertVolume(volumeSlider.value,
        //         //                                                           QtMultimedia.LogarithmicVolumeScale,
        //         //                                                           QtMultimedia.LinearVolumeScale)
        //         value: settings.volume
        //         onMoved: settings.setValue("volume", value)
        //     }
        // }
        Item { Layout.fillHeight: true }
    }

    FolderDialog {
        id: folderDialog
        currentFolder: MusicIndexer.rootPaths[0]
        onAccepted: {
            if (!!folder) {
                MusicIndexer.rootPaths = [folder]
                MusicIndexer.parse()
            }
        }
    }
}
