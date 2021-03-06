import QtQuick 2.15
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "AlbumViewPage"
    title: "%1 · %2".arg(album).arg(artist)

    property string album
    property string artist
    property string genre: albumModel.get(0, "genre");
    property int year: albumModel.get(0, "year");

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

    function reload() {
        albumModel.reload();
        root.genre = albumModel.get(0, "genre");
        root.year = albumModel.get(0, "year");
    }

    SqlQueryModel {
        id: albumModel
        db: DbIndexer.dbName
        query: "SELECT url, title, genre, year, length FROM Tracks WHERE (album='%1' AND artist='%2') ORDER BY trackNo"
            .arg(escapeSingleQuote(root.album)).arg(escapeSingleQuote(root.artist))
    }

    ListView {
        id: listview
        anchors.fill: parent
        model: albumModel
        clip: true
        header: RowLayout {
            spacing: 10
            Image {
                Layout.preferredWidth: 150
                Layout.preferredHeight: 150
                Layout.margins: 15
                source: DbIndexer.coverArtForAlbum(root.album)
                sourceSize: Qt.size(width, height)
            }
            Column {
                Label {
                    text: root.album
                    font.pixelSize: root.font.pixelSize * 1.2
                }
                Label {
                    text: "<a href=\"artist:/%2\">%1</a>".arg(root.artist).arg(escape(root.artist))
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
                    text: "<a href=\"genre:/%2\">%1</a>".arg(root.genre).arg(escape(root.genre))
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
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count))
                    .arg(formatSeconds(albumModel.execHelperQuery("SELECT SUM(length) FROM Tracks WHERE album='%1'".arg(escapeSingleQuote(root.album)))))
                }
                Label {
                    text: root.year
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
                        ToolTip.text: qsTr("Play Album")
                        ToolTip.visible: hovered
                    }
                    RoundButton {
                        width: 64
                        height: 64
                        icon.source: "qrc:/icons/ic_shuffle_48px.svg"
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
            readonly property bool isPlaying: Player.currentPlayUrl == modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") +
                  (index + 1) + " · " + albumModel.get(index, "title")
            secondaryText: formatSeconds(albumModel.get(index, "length"))
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked track:", modelData);
                root.playAlbum(root.album, index);
            }
            ToolButton {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                icon.source: "qrc:/icons/more_vert-black-48dp.svg"
                onClicked: root.editTrackMetadata(modelData)
                ToolTip.text: qsTr("Edit Track Metadata")
                ToolTip.visible: hovered
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
