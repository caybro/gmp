import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12

ToolBar {
    id: root
    objectName: "Playbar"

    contentHeight: playbarLayout.implicitHeight

    required property var player
    required property var playlist
    required property url currentPlayUrl
    onCurrentPlayUrlChanged: {
        var cover = indexer.coverArtForFile(currentPlayUrl);
        // @disable-check M126
        if (cover != "")
            coverArt.source = cover; // FIXME add a generic extractor and/or QQuickImageProvider
        else
            coverArt.source = indexer.coverArtForAlbum(player.metaData.albumTitle);
    }

    signal artistSelected(string artist)
    signal albumSelected(string album)

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
                text: indexer.metadata(root.currentPlayUrl, "title")
                font.pixelSize: Qt.application.font.pixelSize * 1.2
                maximumLineCount: 1
                elide: Text.ElideRight
                width: parent.width
            }
            Label {
                text: "<a href=\"artist:/%1\">%1</a> · <a href=\"album:/%2\">%2</a>"
                .arg(indexer.metadata(root.currentPlayUrl, "artist"))
                .arg(indexer.metadata(root.currentPlayUrl, "album"))
                width: parent.width
                maximumLineCount: 1
                elide: Text.ElideRight
                onLinkActivated: {
                    if (link.startsWith("artist:/")) {
                        root.artistSelected(link.substring(link.indexOf("/")+1));
                    } else if (link.startsWith("album:/")) {
                        root.albumSelected(link.substring(link.indexOf("/")+1));
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
            visible: playlist && playlist.itemCount > 1
            onClicked: playlist.previous()
        }
        
        ToolButton {
            id: playButton
            icon.source: player.playing ? "qrc:/icons/ic_pause_48px.svg" : "qrc:/icons/ic_play_arrow_48px.svg"
            onClicked: player.playing ? player.pause() : player.play()
        }
        
        ToolButton {
            id: nextButton
            icon.source: "qrc:/icons/ic_skip_next_48px.svg"
            visible: playlist && playlist.itemCount > 1
            onClicked: playlist.next()
        }
    }
    ProgressBar {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        from: 0
        to: player.duration
        value: player.position
        visible: player.hasAudio && player.source !== ""
        MouseArea {
            anchors.fill: parent
            visible: player.seekable
            enabled: visible
            onClicked: {
                player.seek(player.duration/parent.width * mouse.x);
            }
        }
    }
}
