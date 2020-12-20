import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

Page {
    id: root
    objectName: "AlbumView"
    title: album

    readonly property var globalModel: indexer.tracksForAlbum(root.album)
    property string album
    property int currentPlaylistIndex
    property url currentPlayUrl
    onCurrentPlayUrlChanged: {
        console.debug("Current URL:", currentPlayUrl)
        listview.positionViewAtIndex(root.currentPlaylistIndex, ListView.Contain);
    }

    signal playAlbum(string album, int index)
    signal shufflePlayAlbum(string album)

    ListView {
        id: listview
        anchors.fill: parent
        model: globalModel.length
        clip: true
        header: RowLayout {
            spacing: 10
            Image {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                Layout.margins: 15
                source: indexer.coverArtForAlbum(root.album)
                sourceSize: Qt.size(width, height)
            }
            Column {
                Label {
                    text: root.album
                    font.pixelSize: root.font.pixelSize * 1.2
                }
                Label {
                    text: indexer.artistForAlbum(root.album)
                }
                Label {
                    text: indexer.genreForAlbum(root.album)
                }
                Label {
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count)).arg(formatSeconds(indexer.albumLength(root.album)))
                }
                Label {
                    text: indexer.yearForAlbum(root.album)
                }
                Row {
                    spacing: 10
                    RoundButton {
                        width: 64
                        height: 64
                        icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                        onClicked: {
                            root.playAlbum(root.album, 0);
                            listview.positionViewAtBeginning();
                        }
                        highlighted: true
                    }
                    RoundButton {
                        width: 64
                        height: 64
                        icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                        onClicked: {
                            root.shufflePlayAlbum(root.album);
                            listview.positionViewAtBeginning();
                        }
                    }
                }
            }
        }

        delegate: CustomItemDelegate {
            readonly property url modelData: globalModel[index]
            readonly property bool isPlaying: root.currentPlayUrl === modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") +
                  (index + 1) + " · " + indexer.metadata(modelData, "title")
            secondaryText: formatSeconds(indexer.metadata(modelData, "length"))
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked track:", modelData);
                root.playAlbum(root.album, index);
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
