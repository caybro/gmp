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
    property string genre
    property int year

    signal saved()

    // TODO make an AlbumProxyModel with album/artist props and additional ones to display overall genre, year and computed length
    GenericProxyModel {
        id: albumModel
        sourceModel: TracksModel
        filterRole: TracksModel.RoleAlbum
        filterString: root.album
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
            source: MusicIndexer.coverArtForAlbum(root.album)
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
            text: root.genre
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
            value: root.year
            textFromValue: function(value) { return value; }
        }
    }

    onAboutToShow: {
        root.genre = albumModel.data(albumModel.index(0, 0), TracksModel.RoleGenre) ?? "";
        root.year = albumModel.data(albumModel.index(0, 0), TracksModel.RoleYear) ?? 0;
    }

    onAccepted: {
        DbIndexer.saveAlbumMetadata(root.album, root.artist, albumGenreEdit.text, albumYearEdit.value, fileDialog.fileUrl);
        root.saved();
    }
}
