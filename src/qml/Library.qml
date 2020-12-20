import QtQuick 2.12
import QtQuick.Controls 2.12

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
            text: qsTr("Artists (%1)").arg(indexer.artists.length)
        }
        TabButton {
            text: qsTr("Albums (%1)").arg(indexer.albums.length)
        }
        TabButton {
            text: qsTr("Songs (%1)").arg(indexer.tracks.length)
        }
        TabButton {
            text: qsTr("Genres (%1)").arg(indexer.genres.length)
        }
    }

    ListView {
        id: artistsListView
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        clip: true
        model: indexer.artists
        delegate: CustomItemDelegate {
            width: ListView.view.width
            text: modelData
            secondaryText: qsTr("%n album(s)", "", indexer.albumsForArtist(modelData).length)
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
        model: indexer.albums
        clip: true
        cellWidth: 200
        cellHeight: 240
        delegate: AlbumDelegate {
            artist: indexer.artistForAlbum(modelData)
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
        model: indexer.tracks.length
        clip: true
        delegate: CustomItemDelegate {
            readonly property url modelData: indexer.tracks[index]
            readonly property bool isPlaying: root.currentPlayUrl === modelData
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + indexer.metadata(modelData, "title")
            secondaryText: indexer.metadata(modelData, "artist") + " · " + indexer.metadata(modelData, "album")
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
        model: indexer.genres
        clip: true
        delegate: CustomItemDelegate {
            width: ListView.view.width
            text: modelData
            secondaryText: qsTr("%n track(s)", "", indexer.tracksForGenre(modelData).length)
            onClicked: {
                console.debug("Clicked:", modelData);
                root.genreSelected(modelData);
            }
        }
        visible: tabbar.currentIndex === 3

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
