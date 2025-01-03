import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

import org.gmp.model 1.0

Page {
    id: root
    objectName: "PlaylistPage"
    title: "%1 · %2 𝅘𝅥 · %3".arg(qsTr("Playlist")).arg(Player.playlist.itemCount)
        .arg(isEmpty ? formatSeconds(0) : formatSeconds(Player.playlist.duration))

    readonly property bool isEmpty: !Player.playlist.itemCount

    signal editTrackMetadata(url track)

    signal dequeueTrack(int index)

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                enabled: !root.isEmpty
                onClicked: Player.playlist.shuffle()
                ToolTip.text: qsTr("Shuffle Playlist")
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: "qrc:/icons/clear_all-black-48dp.svg"
                enabled: !root.isEmpty
                onClicked: Player.playlist.clear()
                ToolTip.text: qsTr("Clear Playlist")
                ToolTip.visible: hovered
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: Player.playlist
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: Player.currentPlayUrl === model.source
            readonly property var metadata: TracksModel.getMetadata(model.source)
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + metadata.title
            secondaryText: metadata.artist + " · " + metadata.album
            highlighted: isPlaying
            onClicked: Player.playlist.currentIndex = index

            ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "qrc:/icons/more_vert-black-48dp.svg"
                onClicked: {
                    contextMenu.trackUrl = model.source
                    contextMenu.trackIndex = index
                    contextMenu.popup()
                }
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    Menu {
        id: contextMenu

        property url trackUrl
        property int trackIndex

        MenuItem {
            text: qsTr("Edit...")
            icon.source: "qrc:/icons/create-black-48dp.svg"
            onClicked: root.editTrackMetadata(contextMenu.trackUrl)
        }
        MenuItem {
            text: qsTr("Remove")
            icon.source: "qrc:/icons/remove_from_queue.svg"
            onClicked: root.dequeueTrack(contextMenu.trackIndex)
        }
    }
}
