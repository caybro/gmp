import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Layouts 1.15
import QtMultimedia 5.15

import org.gmp.model 1.0

ToolBar {
    id: root
    objectName: "Playbar"
    contentHeight: playbarLayout.implicitHeight
    focusPolicy: Qt.NoFocus

    readonly property var metadata: TracksModel.getMetadata(Player.currentPlayUrl)
    readonly property string title: metadata.title ?? ""
    readonly property string artist: metadata.artist ?? ""
    readonly property string album: metadata.album ?? ""

    signal currentTrackChanged(string title, string artist, string album)
    signal artistSelected(string artist)
    signal albumSelected(string album, string artist)

    Connections {
        target: Player.playlist
        function onCurrentItemSourceChanged() {
            const trackUrl = Player.currentPlayUrl;
            const cover = MusicIndexer.coverArtForFile(trackUrl);
            // @disable-check M126
            if (cover != "")
                coverArt.source = cover;
            else
                coverArt.source = MusicIndexer.coverArtForAlbum(root.album);

            if (trackUrl != "")
                root.currentTrackChanged(root.title, root.artist, root.album);
        }
    }

    Connections {
        target: MusicIndexer
        ignoreUnknownSignals: true
        function onAlbumCoverArtChanged(album, artist) {
            if (album === root.album && artist === root.artist) {
                coverArt.source = "";
                coverArt.source = MusicIndexer.coverArtForAlbum(root.album);
            }
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
            cache: false
            sourceSize: Qt.size(width, height)
            visible: !!source
        }
        
        Column {
            Layout.margins: 5
            Layout.fillWidth: true
            Label {
                width: parent.width
                text: root.title
                font.pixelSize: Qt.application.font.pixelSize * 1.2
                maximumLineCount: 1
                elide: Text.ElideRight
            }
            RowLayout {
                width: parent.width
                GmpLabel {
                    text: "<a href='#'>%1</a>".arg(root.artist)
                    maximumLineCount: 1
                    onLinkActivated: root.artistSelected(root.artist)
                }
                Label {
                    text: "·"
                }
                GmpLabel {
                    text: "<a href='#'>%1</a>".arg(root.album)
                    maximumLineCount: 1
                    onLinkActivated: root.albumSelected(root.album, root.artist)
                }
                Item { Layout.fillWidth: true }
            }
            Label {
                width: parent.width
                text: "%1 / %2".arg(formatSeconds(Player.position/1000)).arg(formatSeconds(Player.duration/1000))
                maximumLineCount: 1
                elide: Text.ElideRight
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
