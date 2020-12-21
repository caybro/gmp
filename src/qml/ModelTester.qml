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
        query: "SELECT url, title, album, artist FROM Tracks ORDER BY title"
        //query: "SELECT DISTINCT genre FROM Tracks ORDER BY genre"
    }

    Component {
        id: trackDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: queryModel.get(index, "title")
            secondaryText: queryModel.get(index, "artist") + " · " + queryModel.get(index, "album")
            onClicked: {
                console.warn("Clicked:", queryModel.get(index, "url"));
            }
        }
    }

    Component {
        id: genericDelegate
        ItemDelegate {
            width: ListView.view.width
            text: queryModel.get(index, "genre")
            onClicked: {
                console.warn("Clicked:", text);
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: queryModel
        //delegate: genericDelegate
        delegate: trackDelegate

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
