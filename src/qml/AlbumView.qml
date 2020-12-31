import QtQuick 2.12
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

    Connections {
        target: Player
        function onCurrentPlayUrlChanged(url) {
            listview.positionViewAtIndex(Player.currentPlaylistIndex, ListView.Contain);
        }
    }

    signal playAlbum(string album, int index)
    signal shufflePlayAlbum(string album)
    signal editTrackMetadata(url track)

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
                    text: root.artist
                }
                Label {
                    text: albumModel.get(0, "genre")
                }
                Label {
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count))
                    .arg(formatSeconds(albumModel.execHelperQuery("SELECT SUM(length) FROM Tracks WHERE album='%1'".arg(escapeSingleQuote(root.album)))))
                }
                Label {
                    text: albumModel.get(0, "year")
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
            onPressAndHold: {
                root.editTrackMetadata(modelData)
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
