import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.12
import QtMultimedia 5.15

import org.gmp.model 1.0
import org.gmp.indexer 1.0

ToolBar {
    id: root
    objectName: "Playbar"
    contentHeight: playbarLayout.implicitHeight
    focusPolicy: Qt.NoFocus

    readonly property var metadata: TracksModel.getMetadata(Player.currentPlayUrl)
    readonly property string title: metadata.title ?? "";
    readonly property string artist: metadata.artist ?? "";
    readonly property string album: metadata.album ?? "";

    signal currentTrackChanged(string title, string artist, string album)
    signal artistSelected(string artist)
    signal albumSelected(string album, string artist)

    Connections {
        target: Player.playlist
        function onCurrentItemSourceChanged() {
            const trackUrl = Player.currentPlayUrl;
            const cover = DbIndexer.coverArtForFile(trackUrl);
            // @disable-check M126
            if (cover != "")
                coverArt.source = cover;
            else
                coverArt.source = DbIndexer.coverArtForAlbum(root.album);

            if (trackUrl != "")
                root.currentTrackChanged(root.title, root.artist, root.album);
        }
    }

    Slider {
        id: slider
        focusPolicy: Qt.NoFocus
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: -height/2
        padding: 0
        live: false
        from: 0
        to: Player.duration
        value: Player.position
        visible: Player.hasAudio && Player.source !== ""
        enabled: Player.seekable
        onMoved: Player.seek(valueAt(position))

        ToolTip {
            parent: slider.handle
            visible: slider.pressed
            text: formatSeconds(slider.value/1000)
        }
    }

    RowLayout {
        id: playbarLayout
        anchors.fill: parent
        visible: Player.hasAudio && Player.source !== ""
        
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
                text: root.title
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
                        root.artistSelected(root.artist);
                    } else if (link.startsWith("album:/")) {
                        root.albumSelected(root.album, root.artist);
                    }
                }
                HoverHandler {
                    acceptedButtons: Qt.NoButton
                    acceptedDevices: PointerDevice.GenericPointer
                    cursorShape: Qt.PointingHandCursor
                }
            }
            Label {
                width: parent.width
                maximumLineCount: 1
                elide: Text.ElideRight
                text: "%1 / %2".arg(formatSeconds(Player.position/1000)).arg(formatSeconds(Player.duration/1000))
            }
        }
        
        Item {
            Layout.fillWidth: true
        }
        
        ToolButton {
            icon.source: "qrc:/icons/ic_skip_previous_48px.svg"
            enabled: Player.canPlayPrevious
            onClicked: Player.playlist.previous()
            ToolTip.text: qsTr("Previous Track")
            ToolTip.visible: hovered
            focusPolicy: Qt.NoFocus
        }
        
        RoundButton {
            icon.source: Player.playing ? "qrc:/icons/ic_pause_48px.svg" : "qrc:/icons/ic_play_arrow_48px.svg"
            onClicked: Player.playing ? Player.pause() : Player.play()
            highlighted: true
            ToolTip.text: Player.playing ? qsTr("Pause") : qsTr("Play")
            ToolTip.visible: hovered
            focusPolicy: Qt.NoFocus
        }
        
        ToolButton {
            icon.source: "qrc:/icons/ic_skip_next_48px.svg"
            enabled: Player.canPlayNext
            onClicked: Player.playlist.next()
            ToolTip.text: qsTr("Next Track")
            ToolTip.visible: hovered
            focusPolicy: Qt.NoFocus
        }
    }
}
