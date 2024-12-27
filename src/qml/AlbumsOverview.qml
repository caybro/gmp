import QtQuick 2.15
import QtQuick.Controls 2.15

import org.gmp.model 1.0

Page {
    id: root
    objectName: "AlbumsOverview"
    title: "%1 · %2".arg(artist).arg(qsTr("%n album(s)", "", gridview.model.count))

    property string artist

    signal albumSelected(string album, string artist)
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

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: GenericProxyModel {
            sourceModel: AlbumsModel
            filterRole: AlbumsModel.RoleArtist
            filterString: root.artist
            sortRole: priv.alphaSort ? AlbumsModel.RoleAlbum : AlbumsModel.RoleYear
        }
        delegate: AlbumDelegate {
            onClicked: {
                console.debug("Clicked album:", model.album);
                root.albumSelected(model.album, artist);
            }
            onPlayAlbum: root.playAlbum(model.album, index)
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
