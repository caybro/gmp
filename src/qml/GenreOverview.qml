import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root
    objectName: "GenreOverview"
    title: "%1 · %2".arg(genre).arg(qsTr("%n track(s)", "", listview.count))

    readonly property var globalModel: indexer.tracksForGenre(root.genre)

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

    ListView {
        id: listview
        anchors.fill: parent
        model: globalModel.length
        delegate: CustomItemDelegate {
            readonly property url modelData: globalModel[index]
            readonly property bool isPlaying: root.currentPlayUrl === modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + indexer.metadata(modelData, "title")
            secondaryText: indexer.metadata(modelData, "artist") + " · " + indexer.metadata(modelData, "album")
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", modelData);
                root.playRequested(modelData);
            }
        }
    }
}
