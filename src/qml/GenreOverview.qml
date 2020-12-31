import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "GenreOverviewPage"
    title: "%1 · %2".arg(genre).arg(qsTr("%n track(s)", "", listview.count))

    property string genre

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                onClicked: root.playGenre(root.genre)
                ToolTip.text: qsTr("Play Genre")
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlayGenre(root.genre)
                ToolTip.text: qsTr("Play Genre in Random Order")
                ToolTip.visible: hovered
            }
        }
    }

    signal playRequested(url playFileUrl)
    signal playGenre(string genre)
    signal shufflePlayGenre(string genre)
    signal editTrackMetadata(url track)

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
            readonly property bool isPlaying: Player.currentPlayUrl == modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + genreModel.get(index, "title")
            secondaryText: genreModel.get(index, "artist") + " · " + genreModel.get(index, "album")
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", modelData);
                root.playRequested(modelData);
            }
            onPressAndHold: {
                root.editTrackMetadata(modelData)
            }
        }
    }
}
