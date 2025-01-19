import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.gmp.model 1.0

Page {
    id: root
    objectName: "AlbumViewPage"
    title: "%1 · %2".arg(album).arg(artist)

    property string album
    property string artist
    readonly property string genre: albumModel.genre
    readonly property int year: albumModel.year

    signal playAlbum(string album, int index)
    signal shufflePlayAlbum(string album)
    signal editTrackMetadata(url track)
    signal editAlbumMetadata(string album, string artist)
    signal artistSelected(string artist)
    signal genreSelected(string genre)

    signal enqueueTrack(url track)
    signal enqueueTrackNext(url track)

    property var toolbarAction: Component {
        ToolButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/edit_note.svg"
            onClicked: root.editAlbumMetadata(root.album, root.artist)
            ToolTip.text: qsTr("Edit Album Metadata")
            ToolTip.visible: hovered
        }
    }

    Connections {
        target: Player
        function onCurrentPlayUrlChanged(url) {
            listview.positionViewAtIndex(Player.currentPlaylistIndex, ListView.Contain);
        }
    }

    AlbumProxyModel {
        id: albumModel
        sourceModel: TracksModel
        album: root.album
        artist: root.artist
        sortRole: TracksModel.RoleTrackNo
    }

    ListView {
        id: listview
        anchors.fill: parent
        model: albumModel
        clip: true
        header: RowLayout {
            width: parent.width
            spacing: 0

            AlbumCover {
                id: cover
                Layout.preferredWidth: height
                Layout.preferredHeight: textLayout.height
                Layout.margins: 16
                Layout.alignment: Qt.AlignTop
                image: albumModel.coverImage

                Connections {
                    target: MusicIndexer
                    function onAlbumCoverArtChanged(album, artist) {
                        if (album === root.album && artist === root.artist)
                            cover.image = albumModel.coverImage
                    }
                }
            }
            ColumnLayout {
                id: textLayout
                Layout.topMargin: 12
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: root.album
                    font.pixelSize: root.font.pixelSize * 1.3
                    elide: Text.ElideRight
                }
                GmpLabel {
                    Layout.fillWidth: true
                    text: "<a href='#'>%1</a>".arg(root.artist)
                    onLinkActivated: root.artistSelected(root.artist)
                }
                GmpLabel {
                    Layout.fillWidth: true
                    text: "<a href='#'>%1</a>".arg(root.genre)
                    onLinkActivated: root.genreSelected(root.genre)
                }
                Label {
                    Layout.fillWidth: true
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count)).arg(formatSeconds(albumModel.tracksDuration))
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: root.year
                    elide: Text.ElideRight
                }
                Row {
                    spacing: 10
                    RoundButton {
                        width: 64
                        height: 64
                        icon.source: "qrc:/icons/play.svg"
                        focusPolicy: Qt.NoFocus
                        onClicked: {
                            root.playAlbum(root.album, 0);
                            listview.positionViewAtBeginning();
                        }
                        highlighted: true
                        ToolTip.text: qsTr("Play Album")
                        ToolTip.visible: hovered
                    }
                    RoundButton {
                        width: 64
                        height: 64
                        icon.source: "qrc:/icons/shuffle.svg"
                        focusPolicy: Qt.NoFocus
                        onClicked: {
                            root.shufflePlayAlbum(root.album);
                            listview.positionViewAtBeginning();
                        }
                        ToolTip.text: qsTr("Play Album in Random Order")
                        ToolTip.visible: hovered
                    }
                }
            }
        }

        delegate: CustomItemDelegate {
            readonly property bool isPlaying: Player.currentPlayUrl === model.url
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + model.title
            secondaryText: formatSeconds(model.length)
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked track:", model.url);
                root.playAlbum(root.album, index);
            }
            ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "qrc:/icons/more_vert.svg"
                onClicked: {
                    const menu = contextMenuComponent.createObject(root, {trackUrl: model.url})
                    menu.popup()
                }
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    Component {
        id: contextMenuComponent
        Menu {
            id: contextMenu

            property url trackUrl

            MenuItem {
                text: qsTr("Edit...")
                icon.source: "qrc:/icons/edit_note.svg"
                onClicked: root.editTrackMetadata(contextMenu.trackUrl)
            }
            MenuItem {
                text: qsTr("Add to queue")
                icon.source: "qrc:/icons/add_to_queue.svg"
                onClicked: root.enqueueTrack(contextMenu.trackUrl)
            }
            MenuItem {
                text: qsTr("Play next")
                icon.source: "qrc:/icons/queue_play_next.svg"
                onClicked: root.enqueueTrackNext(contextMenu.trackUrl)
            }
            onClosed: destroy()
        }
    }
}
