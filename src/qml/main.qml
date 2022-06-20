import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12
import QtQuick.VirtualKeyboard 2.12
import Qt.labs.settings 1.1
import Qt.labs.platform 1.1 as Platform

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

ApplicationWindow {
    id: window
    visible: true
    width: isMobileOS ? Screen.width : 800
    height: isMobileOS ? Screen.height : 600

    readonly property bool isMobileOS: ["ios", "android", "winrt"].includes(Qt.platform.os)

    function formatSeconds(secs) {
        var sec_num = parseInt(secs, 10);
        var hours   = Math.floor(sec_num / 3600);
        var minutes = Math.floor((sec_num % 3600) / 60);
        var seconds = Math.floor(sec_num % 60);

        if (hours   < 10) {hours   = "0"+hours;}
        if (minutes < 10) {minutes = "0"+minutes;}
        if (seconds < 10) {seconds = "0"+seconds;}
        return (hours !== "00" ? hours + ':' : "") + minutes + ':' + seconds;
    }

    function escapeSingleQuote(input) {
        return String(input).replace(/'/g, "''");
    }

    Component.onCompleted: {
        parseTimer.start();
    }

    Timer {
        id: parseTimer
        interval: 100
        onTriggered: {
            DbIndexer.parse();
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
                icon.source: stackView.depth > 1 ? "qrc:/icons/ic_arrow_back_48px.svg" : "qrc:/icons/ic_menu_48px.svg"
                font.pixelSize: Qt.application.font.pixelSize * 1.5
                onClicked: {
                    if (stackView.depth > 1) {
                        stackView.pop()
                    } else {
                        drawer.open()
                    }
                }
                ToolTip.text: stackView.depth > 1 ? qsTr("Back") : qsTr("Menu")
                ToolTip.visible: hovered
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Label.AlignHCenter
                elide: Label.ElideMiddle
                text: stackView.currentItem.title ?? "";
                font.pixelSize: Qt.application.font.pixelSize * 1.5
            }

            Loader {
                id: toolbarAction
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
                                                    qsTr("Now playing %1 on %2 by %3".arg(title).arg(album).arg(artist)));
    }

    SqlQueryModel {
        id: helperModel
        db: "" // inited later when parsing finishes
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
            stackView.push("AlbumView.qml", {"album": album, "artist": artist});
        }
        function onArtistSelected(artist) {
            stackView.push("AlbumsOverview.qml", {"artist": artist});
        }
        function onPlayAlbum(album, index) {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE album='%1' ORDER BY trackNo".arg(escapeSingleQuote(album)));
            Player.playlist.addItems(urls);
            Player.currentPlaylistIndex = index;
            Player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE album=?", [album]);
            Player.playlist.duration = Number(duration);
        }
        function onShufflePlayAlbum(album) {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE album='%1'".arg(escapeSingleQuote(album)));
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE album=?", [album]);
            Player.playlist.duration = Number(duration);
        }
        function onGenreSelected(genre) {
            stackView.push("GenreOverview.qml", {"genre": genre});
        }
        function onPlayGenre(genre) {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE genre='%1' ORDER BY title".arg(escapeSingleQuote(genre)));
            Player.playlist.addItems(urls);
            Player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE genre=?", [genre]);
            Player.playlist.duration = Number(duration);
        }
        function onShufflePlayGenre(genre) {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE genre='%1'".arg(escapeSingleQuote(genre)));
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE genre=?", [genre]);
            Player.playlist.duration = Number(duration);
        }
        function onShufflePlay() {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks");
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
            const duration = helperModel.execHelperQuery("SELECT SUM(length) AS duration FROM Tracks");
            Player.playlist.duration = Number(duration);
        }
        function onShufflePlayArtist(artist) {
            Player.playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE artist='%1'".arg(escapeSingleQuote(artist)));
            Player.playlist.addItems(urls);
            Player.playlist.shuffle();
            Player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE artist=?", [artist]);
            Player.playlist.duration = Number(duration);
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
    }

    EditMetaDialog {
        id: editMetaDialog
        anchors.centerIn: parent
        focus: visible
        modal: true
        onSaved: {
            console.debug("!!! META DIALOG SAVED")
            console.debug("Current stack page:", stackView.currentItem.objectName)
        }
        onClosed: {
            stackView.focus = true;
        }
    }

    EditAlbumMetaDialog {
        id: editAlbumMetaDialog
        anchors.centerIn: parent
        focus: visible
        modal: true
        onSaved: {
            console.debug("!!! ALBUM META DIALOG SAVED")
            console.debug("Current stack page:", stackView.currentItem.objectName)
        }
        onClosed: {
            stackView.focus = true;
        }
    }

    Drawer {
        id: drawer
        width: 400
        height: window.height

        ColumnLayout {
            id: drawerLayout
            anchors.fill: parent
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Playlist")
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
                text: qsTr("Library")
                icon.source: "qrc:/icons/ic_library_music_48px.svg"
                onClicked: {
                    stackView.replace(null, "Library.qml");
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
                text: "%1 · %2 · (c) %3 2020-2021".arg(Qt.application.name).arg(Qt.application.version).arg(Qt.application.organization)
            }
        }
    }

    Connections {
        target: DbIndexer
        function onIndexingChanged() {
            console.info("!!! INDEXING CHANGED:", DbIndexer.indexing);
            if (!DbIndexer.indexing) {
                helperModel.db = DbIndexer.dbName;
                stackView.replace(null, "Library.qml");
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: stackView.pop()
        Keys.onBackPressed: stackView.pop()
        Keys.onPressed: {
            if (event.matches(StandardKey.Back)) {
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
            name: Player.playing ? "media-playback-start" : "media-playback-stop"
        }
        tooltip: Qt.application.displayName
        onActivated: {
            window.show();
            window.raise();
            window.requestActivate();
        }
        menu: Platform.Menu {
            Platform.MenuItem {
                visible: Player.playlist.itemCount > 0
                enabled: Player.canPlayPrevious
                text: "⏮ " + qsTr("P&revious")
                onTriggered: Player.playlist.previous()
            }
            Platform.MenuItem {
                visible: Player.playlist.itemCount > 0
                text: Player.playing ? "⏸ " + qsTr("&Pause") : "⯈ " + qsTr("&Play")
                onTriggered: Player.playing ? Player.pause() : Player.play()
            }
            Platform.MenuItem {
                visible: Player.playlist.itemCount > 0
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
}
