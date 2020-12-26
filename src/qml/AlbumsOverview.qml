import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "AlbumsOverview"
    title: "%1 · %2".arg(artist).arg(qsTr("%n album(s)", "", gridview.count))

    property string artist

    signal albumSelected(string album)
    signal shufflePlayArtist(string artist)
    signal playAlbum(string album, int index)

    // TODO provide quick actions to sort by alphabet/oldest first/newest first

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlayArtist(root.artist)
            }
        }
    }

    SqlQueryModel {
        id: albumsModel
        db: DbIndexer.dbName
        query: "SELECT album, year, genre FROM Tracks WHERE artist='%1' GROUP BY album".arg(escapeSingleQuote(root.artist))
    }

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: albumsModel
        delegate: AlbumDelegate {
            artist: root.artist
            year: albumsModel.get(index, "year") ?? ""
            numTracks: Number(albumsModel.execRowQuery("SELECT COUNT(url) FROM Tracks WHERE (album=? AND artist=?)", [modelData, root.artist]))
            genre: albumsModel.get(index, "genre") ?? ""
            onClicked: {
                console.debug("Clicked:", modelData);
                root.albumSelected(modelData);
            }
            onPlayAlbum: root.playAlbum(album, index)
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
