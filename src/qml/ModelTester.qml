import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Window {
    id: root
    width: 800
    height: 600
    visible: true

    Component.onCompleted: {
        DbIndexer.parse();
        console.info("!!! DB name:", DbIndexer.dbName)
    }

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
        //query: "SELECT url, title, album, artist FROM Tracks ORDER BY title" // all tracks
        //query: "SELECT DISTINCT genre, (SELECT COUNT(s.url) FROM Tracks AS s WHERE s.genre=t.genre) AS count FROM Tracks AS t ORDER BY genre" // genres
        //query: "SELECT DISTINCT album, artist, year, genre FROM Tracks ORDER BY album, year" // all albums
        query: "SELECT DISTINCT album, year, genre, (SELECT COUNT(s.url) FROM Tracks AS s WHERE s.album=t.album) AS count FROM Tracks AS t WHERE artist='%1' ORDER by year DESC, album".arg("Team")
    }

    Component {
        id: trackDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: queryModel.get(index, "title")
            secondaryText: queryModel.get(index, "artist") + " · " + queryModel.get(index, "album")
            onClicked: {
                console.warn("Clicked:", modelData);
            }
        }
    }

    Component {
        id: albumDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: queryModel.get(index, "album")
            secondaryText: queryModel.get(index, "artist") + " · " + queryModel.get(index, "year")
            onClicked: {
                console.warn("Clicked:", text);
            }
        }
    }

    Component {
        id: artistAlbumsDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: queryModel.get(index, "album")
            secondaryText: queryModel.get(index, "genre") + " · " + queryModel.get(index, "year") + " · " + queryModel.get(index, "count")
            onClicked: {
                console.warn("Clicked:", text);
            }
        }
    }

    Component {
        id: genreDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: modelData
            secondaryText: queryModel.get(index, "count")
            onClicked: {
                console.warn("Clicked:", text);
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: queryModel
        //delegate: genreDelegate
        //delegate: trackDelegate
        //delegate: albumDelegate
        delegate: artistAlbumsDelegate

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
