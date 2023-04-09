import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Dialogs 1.3 as OldDialogs

import org.gmp.model 1.0

Dialog {
    id: root
    width: parent.width * 2 / 3
    title: qsTr("Edit Album Metadata")
    standardButtons: Dialog.Save | Dialog.Cancel

    property string album
    property string artist

    AlbumProxyModel {
        id: albumModel
        sourceModel: TracksModel
        album: root.album
        artist: root.artist
    }

    OldDialogs.FileDialog {
        id: fileDialog
        nameFilters: [qsTr("Image Files (*.png *.jpg *.jpeg)")]
        selectExisting: true
        selectMultiple: false
        folder: shortcuts.pictures
        title: qsTr("Select new album cover")
        onFileUrlChanged: if (!!fileUrl) cover.source = fileUrl;
    }

    GridLayout {
        anchors.fill: parent
        columns: 2
        Image {
            id: cover
            cache: false
            Layout.preferredWidth: 100
            Layout.preferredHeight: 100
            Layout.columnSpan: 2
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
            text: albumModel.genre
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
            value: albumModel.year
            textFromValue: function(value) { return value; }
        }
    }
    onAboutToShow: {
        cover.source = MusicIndexer.coverArtForAlbum(root.album);
    }
    onAccepted: {
        MusicIndexer.saveAlbumMetadata(root.album, root.artist, albumGenreEdit.text, albumYearEdit.value, fileDialog.fileUrl);
    }
}
