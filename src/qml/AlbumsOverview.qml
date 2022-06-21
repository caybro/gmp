import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0

Page {
    id: root
    objectName: "AlbumsOverview"
    title: "%1 · %2".arg(artist).arg(qsTr("%n album(s)", "", gridview.count))

    property string artist

    signal albumSelected(string album, string artist, string genre, int year)
    signal shufflePlayArtist(string artist)
    signal playAlbum(string album, int index)

    QtObject {
        id: priv
        property bool alphaSort
    }

    property var toolbarAction: Component {
        Row {
            ToolButton {
                checkable: true
                checked: false
                icon.source: "qrc:/icons/sort_by_alpha-black-48dp.svg"
                onToggled: priv.alphaSort = checked;
                ToolTip.text: qsTr("Sort alphabetically")
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlayArtist(root.artist)
                ToolTip.text: qsTr("Shuffle play all the artist's songs")
                ToolTip.visible: hovered
            }
        }
    }

    GenericProxyModel {
        id: albumsModel
        sourceModel: AlbumsModel
        filterRole: AlbumsModel.RoleArtist
        filterString: root.artist
        sortRole: priv.alphaSort ? AlbumsModel.RoleAlbum : AlbumsModel.RoleYear
    }

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: albumsModel
        delegate: AlbumDelegate {
            album: model.album
            artist: root.artist
            year: model.year
            numTracks: model.numTracks
            genre: model.genre
            onClicked: {
                console.debug("Clicked album:", album);
                root.albumSelected(album, artist, genre, year);
            }
            onPlayAlbum: root.playAlbum(album, index)
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
