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

    property var toolbarAction: Component {
        ToolButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            icon.source: "qrc:/icons/create-black-48dp.svg"
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
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                Layout.margins: 15
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
                Layout.topMargin: 12
                Layout.fillWidth: true
                Label {
                    Layout.fillWidth: true
                    text: root.album
                    font.pixelSize: root.font.pixelSize * 1.2
                    elide: Text.ElideRight
                }
                Label {
                    Layout.fillWidth: true
                    text: "<a href=\"artist:/%2\">%1</a>".arg(root.artist).arg(escape(root.artist))
                    elide: Text.ElideRight
                    onLinkActivated: {
                        if (link.startsWith("artist:/")) {
                            root.artistSelected(root.artist);
                        }
                    }
                    HoverHandler {
                        acceptedButtons: Qt.NoButton
                        acceptedDevices: PointerDevice.GenericPointer
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: "<a href=\"genre:/%2\">%1</a>".arg(root.genre).arg(escape(root.genre))
                    elide: Text.ElideRight
                    onLinkActivated: {
                        if (link.startsWith("genre:/")) {
                            root.genreSelected(root.genre);
                        }
                    }
                    HoverHandler {
                        acceptedButtons: Qt.NoButton
                        acceptedDevices: PointerDevice.GenericPointer
                        cursorShape: Qt.PointingHandCursor
                    }
                }
                Label {
                    Layout.fillWidth: true
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count)).arg(formatSeconds(MusicIndexer.albumTracksDuration(root.album)))
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
                        icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
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
                        icon.source: "qrc:/icons/ic_shuffle_48px.svg"
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
                icon.source: "qrc:/icons/more_vert-black-48dp.svg"
                onClicked: root.editTrackMetadata(model.url)
                ToolTip.text: qsTr("Edit Track Metadata")
                ToolTip.visible: hovered
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
