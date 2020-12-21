import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "AlbumView"
    title: album

    property string album
    property int currentPlaylistIndex
    property url currentPlayUrl
    onCurrentPlayUrlChanged: {
        listview.positionViewAtIndex(root.currentPlaylistIndex, ListView.Contain);
    }

    signal playAlbum(string album, int index)
    signal shufflePlayAlbum(string album)

    SqlQueryModel {
        id: albumModel
        db: DbIndexer.dbName
        query: "SELECT url, title, artist, genre, year, length FROM Tracks WHERE album='%1'".arg(root.album)
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
                source: indexer.coverArtForAlbum(root.album)  // FIXME cover art
                sourceSize: Qt.size(width, height)
            }
            Column {
                Label {
                    text: root.album
                    font.pixelSize: root.font.pixelSize * 1.2
                }
                Label {
                    text: albumModel.get(0, "artist")
                }
                Label {
                    text: albumModel.get(0, "genre")
                }
                Label {
                    text: "%1 · %2".arg(qsTr("%n track(s)", "", listview.count))
                    .arg(formatSeconds(albumModel.execHelperQuery("SELECT SUM(length) FROM Tracks WHERE album='%1'".arg(root.album))))
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
            readonly property bool isPlaying: root.currentPlayUrl == modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") +
                  (index + 1) + " · " + albumModel.get(index, "title")
            secondaryText: formatSeconds(albumModel.get(index, "length"))
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked track:", modelData);
                root.playAlbum(root.album, index);
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
