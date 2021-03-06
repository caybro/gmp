import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3 as OldDialogs

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Dialog {
    id: root
    width: parent.width * 2 / 3
    title: qsTr("Edit Album Metadata")
    standardButtons: Dialog.Save | Dialog.Cancel

    property string album
    property string artist
    property var metadata

    signal saved()

    SqlQueryModel {
        id: helperModel
        db: DbIndexer.dbName
    }

    OldDialogs.FileDialog {
        id: fileDialog
        nameFilters: [qsTr("Image Files (*.png *.jpg *.jpeg)")]
        selectExisting: true
        selectMultiple: false
        folder: shortcuts.home
        title: qsTr("Select new album cover")
        onFileUrlChanged: if (!!fileUrl) cover.source = fileUrl;
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        Image {
            id: cover
            Layout.preferredWidth: 100
            Layout.preferredHeight: 100
            Layout.columnSpan: 2
            source: DbIndexer.coverArtForAlbum(root.album)
            sourceSize: Qt.size(width, height)

            MouseArea {
                anchors.fill: parent
                onClicked: fileDialog.open()
                cursorShape: Qt.PointingHandCursor
            }
        }
        Label {
            text: qsTr("Genre:")
        }
        TextField {
            Layout.fillWidth: true
            id: albumGenreEdit
            text: root.metadata ? root.metadata[0] : ""
            placeholderText: qsTr("Album Genre")
        }
        Label {
            text: qsTr("Year:")
        }
        SpinBox {
            id: albumYearEdit
            from: 0
            to: 9999
            editable: true
            value: root.metadata ? root.metadata[1] : ""
            textFromValue: function(value) { return value; }
        }
    }

    onAboutToShow: {
        metadata = helperModel.execRowQuery("SELECT genre, year FROM Tracks WHERE album=? AND artist=?", [root.album, root.artist]);
    }
    onAccepted: {
        DbIndexer.saveAlbumMetadata(root.album, root.artist, albumGenreEdit.text, albumYearEdit.value, fileDialog.fileUrl);
        root.saved();
    }
}
