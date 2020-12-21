import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12
import QtQuick.VirtualKeyboard 2.4

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600

//    Material.primary: Material.DeepOrange
//    Material.accent: Material.Orange

    readonly property alias currentPlayUrl: playlist.currentItemSource

    Component.onCompleted: {
//        console.time("indexing media files");
//        const songCount = indexer.scanAll();
//        console.timeEnd("indexing media files");
//        console.debug("Found %1 audio files".arg(songCount));
    }

    function formatSeconds(secs) {
        var sec_num = parseInt(secs, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num % 3600) / 60);
        var seconds = Math.floor(sec_num % 60);

        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return (hours !== "00" ? hours + ':' : "") + minutes+':'+seconds;
    }

    header: ToolBar {
        contentHeight: toolButton.implicitHeight

        ToolButton {
            id: toolButton
            anchors.verticalCenter: parent.verticalCenter
            icon.source: stackView.depth > 1 ? "qrc:/icons/ic_arrow_back_48px.svg" : "qrc:/icons/ic_menu_48px.svg"
            font.pixelSize: Qt.application.font.pixelSize * 1.5
            onClicked: {
                if (stackView.depth > 1) {
                    stackView.pop()
                } else {
                    drawer.open()
                }
            }
        }

        Label {
            text: stackView.currentItem.title
            font.pixelSize: Qt.application.font.pixelSize * 1.5
            anchors.centerIn: parent
        }

        Loader {
            id: toolbarAction
            active: stackView.currentItem && typeof stackView.currentItem.toolbarAction !== 'undefined'
            sourceComponent: stackView.currentItem.toolbarAction
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
        }
    }

    footer: Playbar {
        id: playbar
        player: player
        playlist: playlist
        currentPlayUrl: window.currentPlayUrl
        onAlbumSelected: stackViewConnections.onAlbumSelected(album)
        onArtistSelected: stackViewConnections.onArtistSelected(artist)
    }

    Connections {
        id: stackViewConnections
        target: stackView.currentItem
        ignoreUnknownSignals: true
        function onPlayRequested(playFileUrl) {
            playlist.clear();
            playlist.addItem(playFileUrl);
            player.play();
        }
        function onAlbumSelected(album) {
            stackView.push("AlbumView.qml",
                           {"album": album, "currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; }),
                               "currentPlaylistIndex": Qt.binding(function() { return playlist.currentIndex; })});
        }
        function onArtistSelected(artist) {
            stackView.push("AlbumsOverview.qml", {"artist": artist});
        }
        function onPlayAlbum(album, index) {
            playlist.clear();
            playlist.addItems(indexer.tracksForAlbum(album));
            playlist.currentIndex = index;
            player.play();
        }
        function onShufflePlayAlbum(album) {
            playlist.clear();
            playlist.addItems(indexer.tracksForAlbum(album));
            playlist.shuffle();
            player.play();
        }
        function onGenreSelected(genre) {
            stackView.push("GenreOverview.qml",
                           {"genre": genre, "currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })});
        }
        function onPlayGenre(genre) {
            playlist.clear();
            playlist.addItems(indexer.tracksForGenre(genre));
            player.play();
        }
        function onShufflePlayGenre(genre) {
            playlist.clear();
            playlist.addItems(indexer.tracksForGenre(genre));
            playlist.shuffle();
            player.play();
        }
        function onShufflePlay() {
            playlist.addItems(indexer.tracks);
            playlist.shuffle();
            player.play();
        }
    }

    Audio {
        readonly property bool playing: playbackState === MediaPlayer.PlayingState

        id: player
        audioRole: MediaPlayer.MusicRole
        autoPlay: true
        playlist: Playlist {
            id: playlist
            playbackMode: Playlist.Sequential
        }
    }

    Drawer {
        id: drawer
        width: window.width * 0.5
        height: window.height

        ColumnLayout {
            anchors.fill: parent

            ItemDelegate {
                text: qsTr("Currently Playing / Playlist")
                icon.source: "qrc:/icons/ic_queue_music_48px.svg"
                width: parent.width
                onClicked: {
                    stackView.push("Playlist.qml", {"playlist": Qt.binding(function() { return playlist; })});
                    drawer.close();
                }
            }
            ItemDelegate {
                text: qsTr("Last Played")
                icon.source: "qrc:/icons/ic_history_48px.svg"
                width: parent.width
                onClicked: {
                    stackView.push("Last.qml");
                    drawer.close();
                }
            }
            ItemDelegate {
                text: qsTr("Library")
                icon.source: "qrc:/icons/ic_library_music_48px.svg"
                width: parent.width
                onClicked: {
                    stackView.push("Library.qml",
                                   {"currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })});
                    drawer.close();
                }
            }
            ItemDelegate {
                text: qsTr("Settings")
                icon.source: "qrc:/icons/ic_settings_48px.svg"
                width: parent.width
                onClicked: {
                    stackView.push("Settings.qml");
                    drawer.close();
                }
            }
            Item { Layout.fillHeight: true }
            Label {
                Layout.margins: 5
                Layout.alignment: Qt.AlignHCenter
                text: "%1 · %2 · (c) %3 2020".arg(Qt.application.name).arg(Qt.application.version).arg(Qt.application.organization)
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        Component.onCompleted: stackView.push("Library.qml",
                                              {"currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })})

    }

    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: window.height
        width: window.width

        states: State {
            name: "visible"
            when: inputPanel.active
            PropertyChanges {
                target: inputPanel
                y: window.height - inputPanel.height
            }
        }
        transitions: Transition {
            from: ""
            to: "visible"
            reversible: true
            ParallelAnimation {
                NumberAnimation {
                    properties: "y"
                    duration: 250
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
