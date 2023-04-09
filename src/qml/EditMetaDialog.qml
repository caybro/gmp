import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.gmp.model 1.0

Dialog {
    id: root
    width: parent.width * 2 / 3
    title: qsTr("Edit Track Metadata")
    standardButtons: Dialog.Save | Dialog.Cancel

    property url trackUrl
    property var metadata: ({})

    contentItem: GridLayout {
        columns: 2
        Label {
            text: qsTr("Title:")
        }
        TextField {
            id: titleEdit
            Layout.fillWidth: true
            text: root.metadata.title ?? ""
            placeholderText: qsTr("Track Title")
        }
        Label {
            text: qsTr("Artist:")
        }
        TextField {
            id: artistEdit
            Layout.fillWidth: true
            text: root.metadata.artist ?? ""
            placeholderText: qsTr("Track Artist")
        }
        Label {
            text: qsTr("Album:")
        }
        TextField {
            id: albumEdit
            Layout.fillWidth: true
            text: root.metadata.album ?? ""
            placeholderText: qsTr("Track Album")
        }
        Label {
            text: qsTr("Year:")
        }
        SpinBox {
            id: yearEdit
            from: 0
            to: 9999
            editable: true
            value: root.metadata.year ?? 0
            textFromValue: function(value) { return value; }
        }
        Label {
            text: qsTr("Genre:")
        }
        TextField {
            id: genreEdit
            Layout.fillWidth: true
            text: root.metadata.genre ?? ""
            placeholderText: qsTr("Track Genre")
        }
    }

    onAboutToShow: {
        root.metadata = TracksModel.getMetadata(root.trackUrl);
    }

    onAccepted: {
        MusicIndexer.saveMetadata(trackUrl, titleEdit.text, artistEdit.text, albumEdit.text, yearEdit.value, genreEdit.text);
    }
}
