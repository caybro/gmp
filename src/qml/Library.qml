import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import org.gmp.model 1.0

Page {
    id: root
    objectName: "LibraryPage"
    title: priv.searchVisible ? "" : qsTr("Library")

    signal playRequested(url playFileUrl)
    signal artistSelected(string artist)
    signal albumSelected(string album, string artist)
    signal genreSelected(string genre)
    signal shufflePlay()
    signal playAlbum(string album, int index)
    signal editTrackMetadata(url track)
    signal enqueueTrack(url track)
    signal enqueueTrackNext(url track)

    QtObject {
        id: priv
        property string searchText
        property bool searchVisible
    }

    property var toolbarAction: Component {
        RowLayout {
            Layout.fillWidth: searchField.visible
            TextField {
                Layout.fillWidth: visible
                id: searchField
                placeholderText: qsTr("Type to search...")
                placeholderTextColor: "white"
                visible: false
                onTextChanged: {
                    priv.searchText = text;
                }
            }
            ToolButton {
                id: searchButton
                icon.source: "qrc:/icons/search.svg"
                onClicked: {
                    searchField.visible = !searchField.visible;
                    if (searchField.visible)
                        searchField.forceActiveFocus();
                    else {
                        searchField.clear();
                        root.parent.forceActiveFocus();
                    }
                    priv.searchVisible = searchField.visible
                }
                ToolTip.text: qsTr("Search")
                ToolTip.visible: hovered
            }
            ToolButton {
                id: shufflePlayButton
                icon.source: "qrc:/icons/shuffle.svg"
                onClicked: root.shufflePlay();
                ToolTip.text: qsTr("Shuffle Play")
                ToolTip.visible: hovered
            }
            Shortcut {
                sequence: StandardKey.Find
                context: Qt.ApplicationShortcut
                onActivated: searchButton.clicked()
            }
            Shortcut {
                sequence: StandardKey.Cancel
                context: Qt.ApplicationShortcut
                onActivated: {
                    searchField.visible = false;
                    searchField.clear();
                    priv.searchVisible = false;
                    root.parent.forceActiveFocus();
                }
            }

            Component.onDestruction: searchField.clear(); // clear when we get unloaded
        }
    }

    TabBar {
        id: tabbar
        width: parent.width
        TabButton {
            text: qsTr("Artists") + (" (" + artistsModel.count + ")" ?? "")
        }
        TabButton {
            text: qsTr("Albums") + (" (" + albumsModel.count + ")" ?? "")
        }
        TabButton {
            text: qsTr("Songs") + (" (" + tracksModel.count + ")" ?? "")
        }
        TabButton {
            text: qsTr("Genres") + (" (" + genresModel.count + ")" ?? "")
        }
    }

    Loader {
        id: loader
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: tabbar.bottom
        anchors.bottom: parent.bottom
        sourceComponent: {
            switch (tabbar.currentIndex) {
            case 0:
                return artistsListViewComponent;
            case 1:
                return albumsListViewComponent;
            case 2:
                return tracksListViewComponent;
            case 3:
                return genresListViewComponent;
            }
        }
    }

    GenericProxyModel {
        id: artistsModel
        sourceModel: ArtistsModel
        filterRole: ArtistsModel.RoleArtist
        filterString: priv.searchText
        sortRole: ArtistsModel.RoleArtist
    }

    GenericProxyModel {
        id: albumsModel
        sourceModel: AlbumsModel
        filterRole: AlbumsModel.RoleAlbum
        filterString: priv.searchText
        sortRole: AlbumsModel.RoleAlbum
    }

    GenericProxyModel {
        id: tracksModel
        sourceModel: TracksModel
        filterRole: TracksModel.RoleTitle
        filterString: priv.searchText
        sortRole: TracksModel.RoleTitle
    }

    GenericProxyModel {
        id: genresModel
        sourceModel: GenresModel
        filterRole: GenresModel.RoleGenre
        filterString: priv.searchText
        sortRole: GenresModel.RoleGenre
    }

    Component {
        id: artistsListViewComponent
        ListView {
            clip: true
            model: artistsModel
            delegate: CustomItemDelegate {
                width: ListView.view.width
                text: model.artist
                secondaryText: qsTr("%n album(s)", "", model.numAlbums)
                onClicked: {
                    console.debug("Clicked artist:", model.artist);
                    root.artistSelected(model.artist);
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: albumsListViewComponent
        GridView {
            model: albumsModel
            clip: true
            cellWidth: 200
            cellHeight: 240
            delegate: AlbumDelegate {
                onClicked: {
                    console.debug("Clicked album:", model.album);
                    root.albumSelected(model.album, model.artist);
                }
                onPlayAlbum: root.playAlbum(model.album, index)
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: tracksListViewComponent
        ListView {
            model: tracksModel
            clip: true
            delegate: CustomItemDelegate {
                readonly property bool isPlaying: Player.currentPlayUrl === model.url
                width: ListView.view.width
                text: (isPlaying ? "⯈ " : "") + model.title
                secondaryText: model.artist + " · " + model.album
                highlighted: isPlaying
                onClicked: {
                    console.debug("Clicked track:", model.url);
                    root.playRequested(model.url);
                }
                ToolButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: "qrc:/icons/more_vert.svg"
                    onClicked: {
                        trackContextMenu.trackUrl = model.url
                        trackContextMenu.artist = model.artist
                        trackContextMenu.album = model.album
                        trackContextMenu.popup()
                    }
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}

            Menu {
                id: trackContextMenu

                property url trackUrl
                property string artist
                property string album

                MenuItem {
                    text: qsTr("Edit...")
                    icon.source: "qrc:/icons/edit_note.svg"
                    onClicked: root.editTrackMetadata(trackContextMenu.trackUrl)
                }
                MenuItem {
                    text: qsTr("Add to queue")
                    icon.source: "qrc:/icons/add_to_queue.svg"
                    onClicked: root.enqueueTrack(trackContextMenu.trackUrl)
                }
                MenuItem {
                    text: qsTr("Play next")
                    icon.source: "qrc:/icons/queue_play_next.svg"
                    onClicked: root.enqueueTrackNext(trackContextMenu.trackUrl)
                }
                MenuItem {
                    text: qsTr("Visit Artist")
                    icon.source: "qrc:/icons/artist.svg"
                    onClicked: root.artistSelected(trackContextMenu.artist)
                }
                MenuItem {
                    text: qsTr("Visit Album")
                    icon.source: "qrc:/icons/album.svg"
                    onClicked: root.albumSelected(trackContextMenu.album, trackContextMenu.artist)
                }
            }
        }
    }

    Component {
        id: genresListViewComponent
        ListView {
            model: genresModel
            clip: true
            delegate: CustomItemDelegate {
                width: ListView.view.width
                text: model.genre
                secondaryText: qsTr("%n track(s)", "", model.numTracks)
                onClicked: {
                    console.debug("Clicked genre:", model.genre);
                    root.genreSelected(model.genre);
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
