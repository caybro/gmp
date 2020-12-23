import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "PlaylistPage"
    title: "%1 · %2 𝅘𝅥 · %3".arg(qsTr("Playlist")).arg(playlist.itemCount)
        .arg(isEmpty ? formatSeconds(0) : formatSeconds(playlist.duration))

    readonly property bool isEmpty: !playlist.itemCount
    property var playlist

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                enabled: !root.isEmpty
                onClicked: playlist.shuffle()
            }
            ToolButton {
                icon.source: "qrc:/icons/clear_all-black-48dp.svg"
                enabled: !root.isEmpty
                onClicked: playlist.clear()
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
        model: root.playlist
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: playlist.currentItemSource === model.source
            readonly property var metadata: queryModel.execRowQuery("SELECT title, artist, album FROM Tracks WHERE url=?", [model.source])
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + metadata[0]
            secondaryText: metadata[1] + " · " + metadata[2]
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", model.source);
                playlist.currentIndex = index;
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
