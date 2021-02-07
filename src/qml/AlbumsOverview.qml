import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "AlbumsOverview"
    title: "%1 · %2".arg(artist).arg(qsTr("%n album(s)", "", gridview.count))

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

    SqlQueryModel {
        id: albumsModel
        db: DbIndexer.dbName
        query: "SELECT album, year, genre FROM Tracks WHERE artist='%1' GROUP BY album ORDER BY %2"
            .arg(escapeSingleQuote(root.artist)).arg(priv.alphaSort ? "album" : "year")
    }

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: albumsModel
        delegate: AlbumDelegate {
            artist: root.artist
            year: albumsModel.get(index, "year") ?? "";
            numTracks: Number(albumsModel.execRowQuery("SELECT COUNT(url) FROM Tracks WHERE (album=? AND artist=?)", [modelData, root.artist]))
            genre: albumsModel.get(index, "genre") ?? "";
            onClicked: {
                console.debug("Clicked album:", modelData);
                root.albumSelected(modelData, root.artist);
            }
            onPlayAlbum: root.playAlbum(album, index)
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
