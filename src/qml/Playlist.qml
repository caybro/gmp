import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "PlaylistPage"
    title: "%1 · %2 𝅘𝅥 · %3".arg(qsTr("Playlist")).arg(Player.playlist.itemCount)
        .arg(isEmpty ? formatSeconds(0) : formatSeconds(Player.playlist.duration))

    readonly property bool isEmpty: !Player.playlist.itemCount

    signal editTrackMetadata(url track)

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                enabled: !root.isEmpty
                onClicked: Player.playlist.shuffle()
            }
            ToolButton {
                icon.source: "qrc:/icons/clear_all-black-48dp.svg"
                enabled: !root.isEmpty
                onClicked: Player.playlist.clear()
            }
        }
    }

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
    }

    ListView {
        id: tracksListView
        anchors.fill: parent
        model: Player.playlist
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: Player.currentPlayUrl === model.source
            readonly property var metadata: queryModel.execRowQuery("SELECT title, artist, album FROM Tracks WHERE url=?", [model.source])
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + metadata[0]
            secondaryText: metadata[1] + " · " + metadata[2]
            highlighted: isPlaying
            onClicked: Player.playlist.currentIndex = index
            onPressAndHold: {
                root.editTrackMetadata(modelData)
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
