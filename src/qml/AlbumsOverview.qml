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
            year: albumsModel.get(index, "year")
            numTracks: albumsModel.execHelperQuery("SELECT COUNT(url) FROM Tracks WHERE (album='%1' AND artist='%2')"
                                                   .arg(escapeSingleQuote(modelData)).arg(escapeSingleQuote(root.artist)))
            genre: albumsModel.get(index, "genre")
            onClicked: {
                console.debug("Clicked:", modelData);
                root.albumSelected(modelData);
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
