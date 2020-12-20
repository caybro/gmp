import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

Page {
    id: root
    objectName: "Playlist"
    title: qsTr("Playlist")

    property var playlist

    ListView {
        id: tracksListView
        anchors.fill: parent
        model: root.playlist
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: playlist.currentItemSource === model.source
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + indexer.metadata(model.source, "title")
            secondaryText: indexer.metadata(model.source, "artist") + " · " + indexer.metadata(model.source, "album")
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", model.source);
                playlist.currentIndex = index;
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
