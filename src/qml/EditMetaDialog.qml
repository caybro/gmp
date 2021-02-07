import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Dialog {
    id: root
    width: parent.width * 2 / 3
    title: qsTr("Edit Track Metadata")
    standardButtons: Dialog.Save | Dialog.Cancel

    property url trackUrl
    property var metadata

    signal saved()

    SqlQueryModel {
        id: helperModel
        db: DbIndexer.dbName
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        Label {
            text: qsTr("Title:")
        }
        TextField {
            id: titleEdit
            Layout.fillWidth: true
            text: root.metadata ? root.metadata[0] : ""
            placeholderText: qsTr("Track Title")
        }
        Label {
            text: qsTr("Artist:")
        }
        TextField {
            id: artistEdit
            Layout.fillWidth: true
            text: root.metadata ? root.metadata[1] : ""
            placeholderText: qsTr("Track Artist")
        }
        Label {
            text: qsTr("Album:")
        }
        TextField {
            id: albumEdit
            Layout.fillWidth: true
            text: root.metadata ? root.metadata[2] : ""
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
            value: root.metadata ? root.metadata[3] : ""
            textFromValue: function(value) { return value; }
        }
        Label {
            text: qsTr("Genre:")
        }
        TextField {
            id: genreEdit
            Layout.fillWidth: true
            text: root.metadata ? root.metadata[4] : ""
            placeholderText: qsTr("Track Genre")
        }
    }

    onAboutToShow: {
        metadata = helperModel.execRowQuery("SELECT title, artist, album, year, genre FROM Tracks WHERE url=?", [root.trackUrl]);
    }
    onAccepted: {
        DbIndexer.saveMetadata(trackUrl, titleEdit.text, artistEdit.text, albumEdit.text, yearEdit.value, genreEdit.text);
        root.saved();
    }
}
