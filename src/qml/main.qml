import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtMultimedia 5.15
import QtQuick.VirtualKeyboard 2.15
import Qt.labs.settings 1.1
import Qt.labs.platform 1.1 as Platform

import org.gmp.model 1.0

ApplicationWindow {
    id: window
    visible: true
    width: isMobileOS ? Screen.width : 800
    height: isMobileOS ? Screen.height : 600

    readonly property bool isMobileOS: ["ios", "android", "winrt"].includes(Qt.platform.os)

    title: Player.playing ? "%1 - %2".arg(playbar.title).arg(playbar.artist) : Qt.application.displayName

    function formatSeconds(secs) {
        const sec_num = parseInt(secs, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num % 3600) / 60);
        var seconds = Math.floor(sec_num % 60);

        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return (hours !== "00" ? hours + ':' : "") + minutes + ':' + seconds;
    }

    Component.onCompleted: {
        if (!MusicIndexer.indexing) {
            stackView.replace(null, "Library.qml");
        }
    }

    Connections {
        target: MusicIndexer
        function onIndexingChanged() {
            if (!MusicIndexer.indexing) {
                stackView.replace(null, "Library.qml");
            }
        }
    }

    Settings {
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
    }

    header: ToolBar {
        RowLayout {
            width: parent.width
            ToolButton {
                icon.source: stackView.depth > 1 ? "qrc:/icons/ic_arrow_back_48px.svg"
                                                 : "qrc:/icons/ic_menu_48px.svg"
                font.pixelSize: Qt.application.font.pixelSize * 1.5
                onClicked: stackView.depth > 1 ? stackView.pop() : drawer.open()
                onPressAndHold: drawer.open()
                ToolTip.text: stackView.depth > 1 ? qsTr("Back") : qsTr("Menu")
                ToolTip.visible: hovered
            }

            Label {
                anchors.centerIn: parent
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignCenter
                horizontalAlignment: Label.AlignHCenter
                elide: Label.ElideMiddle
                text: stackView.currentItem.title ?? ""
                font.pixelSize: Qt.application.font.pixelSize * 1.5
            }

            Loader {
                Layout.fillWidth: stackView.currentItem && stackView.currentItem.title === ""
                active: stackView.currentItem && typeof stackView.currentItem.toolbarAction !== 'undefined'
                sourceComponent: stackView.currentItem.toolbarAction
            }
        }
    }

    footer: Playbar {
        id: playbar
        visible: Player.playlist.itemCount
        onAlbumSelected: stackViewConnections.onAlbumSelected(album, artist)
        onArtistSelected: stackViewConnections.onArtistSelected(artist)
        onCurrentTrackChanged: trayIcon.showMessage(Qt.application.name,
                                                    qsTr("Now playing: '%1' on '%2' by '%3'".arg(title).arg(album).arg(artist)));
    }

    Connections {
        id: stackViewConnections
        target: stackView.currentItem
        ignoreUnknownSignals: true

        function onPlayRequested(playFileUrl) {
            Player.playlist.clear();
            Player.playlist.addItem(playFileUrl);
            Player.play();
        }
        function onAlbumSelected(album, artist) {
            stackView.push("AlbumView.qml", {album, artist});
        }
        function onArtistSelected(artist) {
            stackView.push("AlbumsOverview.qml", {artist});
        }
        function onPlayAlbum(album, index) {
            Player.playlist.clear();
            const urls = MusicIndexer.tracksByAlbum(album, true);
            Player.playlist.addItems(urls);
            Player.currentPlaylistIndex = index;
            Player.play();
        }
        function onShufflePlayAlbum(album) {
            Player.playlist.clear();
            const urls = MusicIndexer.tracksByAlbum(album);
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
        }
        function onGenreSelected(genre) {
            stackView.push("GenreOverview.qml", {genre});
        }
        function onPlayGenre(genre) {
            Player.playlist.clear();
            const urls = MusicIndexer.tracksByGenre(genre, true);
            Player.playlist.addItems(urls);
            Player.play();
        }
        function onShufflePlayGenre(genre) {
            Player.playlist.clear();
            const urls = MusicIndexer.tracksByGenre(genre);
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
        }
        function onShufflePlay() {
            Player.playlist.clear();
            const urls = MusicIndexer.allTracks();
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
        }
        function onShufflePlayArtist(artist) {
            Player.playlist.clear();
            const urls = MusicIndexer.tracksByArtist(artist);
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
        }
        function onEditTrackMetadata(trackUrl) {
            console.debug("Edit track metadata:", trackUrl);
            editMetaDialog.trackUrl = trackUrl;
            editMetaDialog.open();
        }
        function onEditAlbumMetadata(album, artist) {
            console.debug("Edit album metadata:", album, artist)
            editAlbumMetaDialog.album = album;
            editAlbumMetaDialog.artist = artist;
            editAlbumMetaDialog.open();
        }
        function onEnqueueTrack(trackUrl) {
            console.debug("Enqueue track:", trackUrl)
            Player.playlist.addItem(trackUrl)
            if (!Player.playing)
                Player.play()
        }
        function onEnqueueTrackNext(trackUrl) {
            console.debug("Enqueue track next:", trackUrl)
            Player.playlist.insertItem(Player.playlist.itemCount ? Player.playlist.currentIndex + 1 : 0, trackUrl)
            if (!Player.playing)
                Player.play()
        }
        function onDequeueTrack(trackIndex) {
            console.debug("Dequeue track:", trackIndex)
            Player.playlist.removeItem(trackIndex)
        }
    }

    EditMetaDialog {
        id: editMetaDialog
        anchors.centerIn: parent
        focus: visible
        modal: true
        onClosed: stackView.focus = true
    }

    EditAlbumMetaDialog {
        id: editAlbumMetaDialog
        anchors.centerIn: parent
        focus: visible
        modal: true
        onClosed: stackView.focus = true
    }

    Drawer {
        id: drawer
        width: Math.max(400, window.width/3)
        height: window.height

        ColumnLayout {
            id: drawerLayout
            anchors.fill: parent
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Library")
                icon.source: "qrc:/icons/ic_library_music_48px.svg"
                onClicked: {
                    stackView.replace(null, "Library.qml");
                    drawer.close();
                }
            }
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Playlist (%1)").arg(Player.playlist.itemCount)
                icon.source: "qrc:/icons/ic_queue_music_48px.svg"
                onClicked: {
                    stackView.replace(null, "Playlist.qml");
                    drawer.close();
                }
            }
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Last Played")
                icon.source: "qrc:/icons/ic_history_48px.svg"
                onClicked: {
                    stackView.replace(null, "Last.qml"); // TODO implement me
                    drawer.close();
                }
            }
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Settings")
                icon.source: "qrc:/icons/ic_settings_48px.svg"
                onClicked: {
                    stackView.replace(null, "Settings.qml");
                    drawer.close();
                }
            }
            Item { Layout.fillHeight: true }
            Label {
                Layout.margins: 5
                Layout.fillWidth: true
                horizontalAlignment: Label.AlignHCenter
                elide: Label.ElideMiddle
                text: "%1 · %2 · (c) %3 2020-2023".arg(Qt.application.name).arg(Qt.application.version).arg(Qt.application.organization)
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        focus: true
        Keys.onPressed: {
            if (event.matches(StandardKey.Back) || event.matches(StandardKey.Cancel)) {
                stackView.pop();
            }
        }
        initialItem: BusyIndicator {
            anchors.centerIn: parent
            running: true
            width: 200
            height: 200
        }
    }

    InputPanel {
        id: inputPanel
        z: 99
        x: 0
        y: window.height
        width: window.width
        enabled: window.isMobileOS
        visible: enabled

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
            NumberAnimation {
                properties: "y"
                duration: 250
                easing.type: Easing.InOutQuad
            }
        }
    }

    Platform.SystemTrayIcon {
        id: trayIcon
        visible: available && !window.isMobileOS
        icon {
            mask: true
            name: Player.playing ? "media-playback-start-symbolic" : "media-playback-stop-symbolic"
        }
        tooltip: Qt.application.displayName
        onActivated: {
            window.show();
            window.raise();
            window.requestActivate();
        }
        menu: Platform.Menu {
            Platform.MenuItem {
                enabled: Player.canPlayPrevious
                text: "⏮ " + qsTr("P&revious")
                onTriggered: Player.playlist.previous()
            }
            Platform.MenuItem {
                enabled: Player.playlist.itemCount > 0
                text: Player.playing ? "⏸ " + qsTr("&Pause") : "⯈ " + qsTr("&Play")
                onTriggered: Player.playing ? Player.pause() : Player.play()
            }
            Platform.MenuItem {
                enabled: Player.canPlayNext
                text: "⏭ " + qsTr("&Next")
                onTriggered: Player.playlist.next()
            }
            Platform.MenuSeparator {}
            Platform.MenuItem {
                text: qsTr("&Show")
                visible: !window.visible
                onTriggered: {
                    window.show();
                    window.raise();
                    window.requestActivate();
                }
            }
            Platform.MenuItem {
                text: qsTr("&Hide")
                visible: window.visible
                onTriggered: {
                    window.hide();
                }
            }
            Platform.MenuItem {
                text: qsTr("&Quit")
                onTriggered: Qt.quit()
                role: Platform.MenuItem.QuitRole
            }
        }
    }

    Shortcut {
        context: Qt.ApplicationShortcut
        sequence: "Ctrl+L"
        onActivated: {
            stackView.replace(null, "Library.qml")
        }
    }
}
