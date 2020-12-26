import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtMultimedia 5.15

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

ToolBar {
    id: root
    objectName: "Playbar"
    contentHeight: playbarLayout.implicitHeight

    required property Audio player

    Connections {
        target: root.player.playlist
        function onCurrentItemSourceChanged() {
            const cover = DbIndexer.coverArtForFile(player.playlist.currentItemSource);
            // @disable-check M126
            if (cover != "")
                coverArt.source = cover; // FIXME add a generic extractor and/or QQuickImageProvider
            else
                coverArt.source = DbIndexer.coverArtForAlbum(root.album);
        }
    }

    signal artistSelected(string artist)
    signal albumSelected(string album)

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
    }

    readonly property var metadata: queryModel.execRowQuery("SELECT title, artist, album FROM Tracks WHERE url=?",
                                                            [player.playlist.currentItemSource])
    readonly property string artist: metadata[1] ?? "";
    readonly property string album: metadata[2] ?? "";

    Slider {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -height/2
        padding: 0
        live: false
        from: 0
        to: player.duration
        value: player.position
        visible: player.hasAudio && player.source !== ""
        onMoved: player.seek(valueAt(position))
    }

    RowLayout {
        id: playbarLayout
        anchors.fill: parent
        visible: player.hasAudio && player.source !== ""
        
        Image {
            Layout.margins: 5
            Layout.topMargin: 10
            Layout.preferredWidth: 60
            Layout.preferredHeight: 60
            id: coverArt
            sourceSize: Qt.size(width, height)
            visible: !!source
        }
        
        Column {
            Layout.margins: 5
            Layout.fillWidth: true
            Label {
                text: metadata[0] ?? ""
                font.pixelSize: Qt.application.font.pixelSize * 1.2
                maximumLineCount: 1
                elide: Text.ElideRight
                width: parent.width
            }
            Label {
                text: "<a href=\"artist:/%2\">%1</a> · <a href=\"album:/%4\">%3</a>"
                    .arg(root.artist).arg(escape(root.artist))
                    .arg(root.album).arg(escape(root.album))
                width: parent.width
                maximumLineCount: 1
                elide: Text.ElideRight
                onLinkActivated: {
                    if (link.startsWith("artist:/")) {
                        root.artistSelected(unescape(link.substring(link.indexOf("/")+1)));
                    } else if (link.startsWith("album:/")) {
                        root.albumSelected(unescape(link.substring(link.indexOf("/")+1)));
                    }
                }
            }
        }
        
        Item {
            Layout.fillWidth: true
        }
        
        Label {
            id: timeString
            text: "%1 / %2".arg(formatSeconds(player.position/1000)).arg(formatSeconds(player.duration/1000))
        }
        
        ToolButton {
            id: previousButton
            icon.source: "qrc:/icons/ic_skip_previous_48px.svg"
            visible: player.playlist && player.playlist.itemCount > 1
            onClicked: player.playlist.previous()
        }
        
        RoundButton {
            id: playButton
            icon.source: player.playing ? "qrc:/icons/ic_pause_48px.svg" : "qrc:/icons/ic_play_arrow_48px.svg"
            onClicked: player.playing ? player.pause() : player.play()
            highlighted: true
        }
        
        ToolButton {
            id: nextButton
            icon.source: "qrc:/icons/ic_skip_next_48px.svg"
            visible: player.playlist && player.playlist.itemCount > 1
            onClicked: player.playlist.next()
        }
    }
}
