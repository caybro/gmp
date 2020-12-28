import QtQuick 2.12
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtMultimedia 5.12
import QtQuick.VirtualKeyboard 2.4
import Qt.labs.settings 1.0

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

ApplicationWindow {
    id: window
    visible: true
    width: 800
    height: 600

    //    Material.primary: Material.DeepOrange
    //    Material.accent: Material.Orange

    readonly property alias currentPlayUrl: playlist.currentItemSource

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
            }

            Label {
                Layout.fillWidth: true
                horizontalAlignment: Label.AlignHCenter
                elide: Label.ElideMiddle
                text: stackView.currentItem.title
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
        visible: playlist.itemCount
        player: player
        onAlbumSelected: stackViewConnections.onAlbumSelected(album, artist)
        onArtistSelected: stackViewConnections.onArtistSelected(artist)
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
            playlist.clear();
            playlist.addItem(playFileUrl);
            player.play();
        }
        function onAlbumSelected(album, artist) {
            stackView.push("AlbumView.qml",
                           {"album": album, "artist": artist, "currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; }),
                               "currentPlaylistIndex": Qt.binding(function() { return playlist.currentIndex; })});
        }
        function onArtistSelected(artist) {
            stackView.push("AlbumsOverview.qml", {"artist": artist});
        }
        function onPlayAlbum(album, index) {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE album='%1' ORDER BY trackNo".arg(escapeSingleQuote(album)));
            playlist.addItems(urls);
            playlist.currentIndex = index;
            player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE album=?", [album]);
            playlist.duration = Number(duration);
        }
        function onShufflePlayAlbum(album) {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE album='%1'".arg(escapeSingleQuote(album)));
            playlist.addItems(urls);
            playlist.shuffle();
            player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE album=?", [album]);
            playlist.duration = Number(duration);
        }
        function onGenreSelected(genre) {
            stackView.push("GenreOverview.qml",
                           {"genre": genre, "currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })});
        }
        function onPlayGenre(genre) {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE genre='%1' ORDER BY title".arg(escapeSingleQuote(genre)));
            playlist.addItems(urls);
            player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE genre=?", [genre]);
            playlist.duration = Number(duration);
        }
        function onShufflePlayGenre(genre) {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE genre='%1'".arg(escapeSingleQuote(genre)));
            playlist.addItems(urls);
            playlist.shuffle();
            player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE genre=?", [genre]);
            playlist.duration = Number(duration);
        }
        function onShufflePlay() {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks");
            playlist.addItems(urls);
            playlist.shuffle();
            player.play();
            const duration = helperModel.execHelperQuery("SELECT SUM(length) AS duration FROM Tracks");
            playlist.duration = Number(duration);
        }
        function onShufflePlayArtist(artist) {
            playlist.clear();
            const urls = helperModel.execListQuery("SELECT url FROM Tracks WHERE artist='%1'".arg(escapeSingleQuote(artist)));
            playlist.addItems(urls);
            playlist.shuffle();
            player.play();
            const duration = helperModel.execRowQuery("SELECT SUM(length) AS duration FROM Tracks WHERE artist=?", [artist]);
            playlist.duration = Number(duration);
        }
        function onEditTrackMetadata(trackUrl) {
            console.debug("Edit track metadata:", trackUrl);
            editMetaDialog.trackUrl = trackUrl;
            editMetaDialog.open();
        }
    }

    Dialog {
        id: editMetaDialog
        width: window.width * 2 / 3

        property url trackUrl
        property var metadata

        anchors.centerIn: parent
        title: qsTr("Edit Track Metadata")
        standardButtons: Dialog.Save | Dialog.Cancel
        modal: true
        focus: true

        GridLayout {
            anchors.fill: parent
            columns: 2
            Label {
                text: qsTr("Title:")
            }
            TextField {
                id: titleEdit
                Layout.fillWidth: true
                text: editMetaDialog.metadata ? editMetaDialog.metadata[0] : ""
                placeholderText: qsTr("Track Title")
            }
            Label {
                text: qsTr("Artist:")
            }
            TextField {
                id: artistEdit
                Layout.fillWidth: true
                text: editMetaDialog.metadata ? editMetaDialog.metadata[1] : ""
                placeholderText: qsTr("Track Artist")
            }
            Label {
                text: qsTr("Album:")
            }
            TextField {
                id: albumEdit
                Layout.fillWidth: true
                text: editMetaDialog.metadata ? editMetaDialog.metadata[2] : ""
                placeholderText: qsTr("Track Album")
            }
            Label {
                text: qsTr("Year:")
            }
            TextField {
                id: yearEdit
                Layout.fillWidth: true
                text: editMetaDialog.metadata ? editMetaDialog.metadata[3] : ""
                placeholderText: qsTr("Track Year")
            }
            Label {
                text: qsTr("Genre:")
            }
            TextField {
                id: genreEdit
                Layout.fillWidth: true
                text: editMetaDialog.metadata ? editMetaDialog.metadata[4] : ""
                placeholderText: qsTr("Track Genre")
            }
        }

        onAboutToShow: {
            console.log("Dialog about to show")
            metadata = helperModel.execRowQuery("SELECT title, artist, album, year, genre FROM Tracks WHERE url=?", [trackUrl]);
        }
        onAccepted: {
            console.log("Save clicked");
            DbIndexer.saveMetadata(trackUrl, titleEdit.text, artistEdit.text, albumEdit.text, parseInt(yearEdit.text, 10), genreEdit.text);
        }
    }

    Audio {
        readonly property bool playing: playbackState === MediaPlayer.PlayingState

        id: player
        audioRole: MediaPlayer.MusicRole
        autoPlay: true
        playlist: Playlist {
            id: playlist
            property int duration
            playbackMode: Playlist.Sequential
        }
    }

    Drawer {
        id: drawer
        width: drawerLayout.childrenRect.width * 1.1
        height: window.height

        ColumnLayout {
            id: drawerLayout
            ItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Playlist")
                icon.source: "qrc:/icons/ic_queue_music_48px.svg"
                onClicked: {
                    stackView.replace(null, "Playlist.qml", {"playlist": Qt.binding(function() { return playlist; })});
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
                    stackView.replace(null, "Library.qml", {"currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })})
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
                text: "%1 · %2 · (c) %3 2020".arg(Qt.application.name).arg(Qt.application.version).arg(Qt.application.organization)
            }
        }
    }

    Connections {
        target: DbIndexer
        function onIndexingChanged() {
            console.info("!!! INDEXING CHANGED:", DbIndexer.indexing);
            if (!DbIndexer.indexing) {
                helperModel.db = DbIndexer.dbName;
                stackView.replace(null, "Library.qml", {"currentPlayUrl": Qt.binding(function() { return window.currentPlayUrl; })})
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: stackView.pop()
        Keys.onBackPressed: stackView.pop()
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
