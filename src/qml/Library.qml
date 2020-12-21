import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "LibraryPage"
    title: qsTr("Library")

    property url currentPlayUrl: ""

    signal playRequested(url playFileUrl)
    signal artistSelected(string artist)
    signal albumSelected(string album)
    signal genreSelected(string genre)
    signal shufflePlay()

    property var toolbarAction: Component {
        Row {
            width: searchField.visible ? searchField.width + searchButton.width + shufflePlayButton.width
                                       : searchButton.width + shufflePlayButton.width
            Behavior on width { PropertyAnimation {duration: 100} }
            TextField {
                id: searchField
                placeholderText: qsTr("Type to search...")
                visible: false
                onTextChanged: {
                    switch (tabbar.currentIndex) {
                    case 0:
                        artistsListView.model = indexer.filterArtists(text);
                        break;
                    case 1:
                        albumsListView.model = indexer.filterAlbums(text);
                        break;
                    case 2:
                        tracksListView.model = indexer.filterTracks(text);
                        break;
                    case 3:
                        genresListView.model = indexer.filterGenres(text);
                        break;
                    }
                }
                onActiveFocusChanged: {
                    if (!activeFocus) {
                        visible = false;
                        clear();
                    }
                }
            }
            ToolButton {
                id: searchButton
                icon.source: "qrc:/icons/ic_search_48px.svg"
                onClicked: {
                    searchField.visible = !searchField.visible;
                    if (searchField.visible)
                        searchField.forceActiveFocus();
                }
            }
            ToolButton {
                id: shufflePlayButton
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlay();
            }
            Component.onDestruction: searchField.clear(); // clear when we get unloaded
        }
    }

    TabBar {
        id: tabbar
        width: parent.width
        TabButton {
            text: qsTr("Artists (%1)").arg(artistsListView.count)
        }
        TabButton {
            text: qsTr("Albums (%1)").arg(albumsListView.count)
        }
        TabButton {
            text: qsTr("Songs (%1)").arg(tracksListView.count)
        }
        TabButton {
            text: qsTr("Genres (%1)").arg(genresListView.count)
        }
    }

    ListView {
        id: artistsListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        clip: true
        model: SqlQueryModel {
            id: artistsModel
            db: DbIndexer.dbName
            query: "SELECT DISTINCT artist, (SELECT COUNT(DISTINCT s.album) FROM Tracks AS s WHERE s.artist=t.artist) AS count FROM Tracks AS t ORDER BY artist"
        }
        delegate: CustomItemDelegate {
            width: ListView.view.width
            text: modelData
            secondaryText: qsTr("%n album(s)", "", artistsModel.get(index, "count"))
            onClicked: {
                console.debug("Clicked:", modelData);
                root.artistSelected(modelData);
            }
        }
        visible: tabbar.currentIndex === 0

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    GridView {
        id: albumsListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        model: SqlQueryModel {
            id: albumsModel
            db: DbIndexer.dbName
            query: "SELECT DISTINCT album, artist, year, genre, (SELECT COUNT(DISTINCT s.url) FROM Tracks AS s WHERE s.album=t.album) AS count FROM Tracks AS t ORDER BY album"
        }
        clip: true
        cellWidth: 200
        cellHeight: 240
        delegate: AlbumDelegate {
            artist: albumsModel.get(index, "artist")
            year: albumsModel.get(index, "year")
            numTracks: albumsModel.get(index, "count")
            genre: albumsModel.get(index, "genre")

            onClicked: {
                console.debug("Clicked:", modelData);
                root.albumSelected(modelData);
            }
        }
        visible: tabbar.currentIndex === 1

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    ListView {
        id: tracksListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        model: SqlQueryModel {
            id: tracksModel
            db: DbIndexer.dbName
            query: "SELECT url, title, album, artist FROM Tracks ORDER BY title"
        }
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: root.currentPlayUrl == modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + tracksModel.get(index, "title")
            secondaryText: tracksModel.get(index, "artist") + " · " + tracksModel.get(index, "album")
            highlighted: isPlaying
            onClicked: {
                console.warn("Clicked:", modelData);
                root.playRequested(modelData);
            }
        }
        visible: tabbar.currentIndex === 2

        ScrollIndicator.vertical: ScrollIndicator {}
    }

    ListView {
        id: genresListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        model: SqlQueryModel {
            id: genresModel
            db: DbIndexer.dbName
            query: "SELECT DISTINCT genre, (SELECT COUNT(s.url) FROM Tracks AS s WHERE s.genre=t.genre) AS count FROM Tracks AS t ORDER BY genre"
        }
        clip: true
        delegate: CustomItemDelegate {
            width: ListView.view.width
            text: modelData
            secondaryText: qsTr("%n track(s)", "", genresModel.get(index, "count"))
            onClicked: {
                console.debug("Clicked:", modelData);
                root.genreSelected(modelData);
            }
        }
        visible: tabbar.currentIndex === 3

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
