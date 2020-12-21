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

    SqlQueryModel {
        id: albumsModel
        db: DbIndexer.dbName
        query: "SELECT album, artist, year, genre, (SELECT COUNT(DISTINCT s.url) FROM Tracks AS s WHERE s.album=t.album) AS count FROM Tracks AS t WHERE artist='%1' GROUP BY album".arg(root.artist)
    }

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: albumsModel
        delegate: AlbumDelegate {
            artist: modelData
            year: albumsModel.get(index, "year")
            numTracks: albumsModel.get(index, "count")
            genre: albumsModel.get(index, "genre")
            onClicked: {
                console.debug("Clicked:", modelData);
                root.albumSelected(modelData);
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
