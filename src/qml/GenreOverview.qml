import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "GenreOverviewPage"
    title: "%1 · %2".arg(genre).arg(qsTr("%n track(s)", "", listview.count))

    property string genre
    property url currentPlayUrl

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                onClicked: root.playGenre(root.genre)
            }
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlayGenre(root.genre)
            }
        }
    }

    signal playRequested(url playFileUrl)
    signal playGenre(string genre)
    signal shufflePlayGenre(string genre)

    SqlQueryModel {
        id: genreModel
        db: DbIndexer.dbName
        query: "SELECT url, title, artist, album FROM Tracks WHERE genre='%1' ORDER BY title".arg(escapeSingleQuote(root.genre))
    }

    ListView {
        id: listview
        anchors.fill: parent
        model: genreModel
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: root.currentPlayUrl == modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + genreModel.get(index, "title")
            secondaryText: genreModel.get(index, "artist") + " · " + genreModel.get(index, "album")
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", modelData);
                root.playRequested(modelData);
            }
        }
    }
}
