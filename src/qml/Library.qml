import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0
import org.gmp.indexer 1.0

Page {
    id: root
    objectName: "LibraryPage"
    title: qsTr("Library")

    signal playRequested(url playFileUrl)
    signal artistSelected(string artist)
    signal albumSelected(string album, string artist)
    signal genreSelected(string genre)
    signal shufflePlay()
    signal playAlbum(string album, int index)
    signal editTrackMetadata(url track)

    QtObject {
        id: priv
        property string searchText
    }

    property var toolbarAction: Component {
        Row {
            width: searchField.visible ? searchField.width + searchButton.width + shufflePlayButton.width
                                       : searchButton.width + shufflePlayButton.width
            Behavior on width { PropertyAnimation { duration: 100 } }
            TextField {
                id: searchField
                placeholderText: qsTr("Type to search...")
                visible: false
                onTextChanged: {
                    priv.searchText = text;
                }
            }
            ToolButton {
                id: searchButton
                icon.source: "qrc:/icons/ic_search_48px.svg"
                onClicked: {
                    searchField.visible = !searchField.visible;
                    if (searchField.visible)
                        searchField.forceActiveFocus();
                    else {
                        searchField.clear();
                        root.parent.forceActiveFocus();
                    }
                }
                ToolTip.text: qsTr("Search")
                ToolTip.visible: hovered
            }
            ToolButton {
                id: shufflePlayButton
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
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
                sequence: "Esc"
                context: Qt.ApplicationShortcut
                onActivated: {
                    searchField.visible = false;
                    searchField.clear();
                    root.parent.forceActiveFocus();
                }
            }

            Component.onDestruction: searchField.clear(); // clear when we get unloaded
        }
    }

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
    }

    TabBar {
        id: tabbar
        width: parent.width
        TabButton {
            text: qsTr("Artists") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT artist) FROM Tracks") + ")" ?? "")
        }
        TabButton {
            text: qsTr("Albums") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT album) FROM Tracks") + ")" ?? "")
        }
        TabButton {
            text: qsTr("Songs") + (" (" + queryModel.execHelperQuery("SELECT COUNT(url) FROM Tracks") + ")" ?? "")
        }
        TabButton {
            text: qsTr("Genres") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT genre) FROM Tracks") + ")" ?? "")
        }
        TabButton {
            text: "Music"
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
            case 4:
                return newMusicComponent;
            }
        }
    }

    Component {
        id: newMusicComponent
        ListView {
            clip: true
            model: ArtistsModel
            delegate: CustomItemDelegate {
                width: ListView.view.width
                text: model.artist
                secondaryText: model.numAlbums
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: artistsListViewComponent
        ListView {
            clip: true
            model: ArtistsModel
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
            id: albumsListView
            model: AlbumsModel
            clip: true
            cellWidth: 200
            cellHeight: 240
            delegate: AlbumDelegate {
                album: model.album
                artist: model.artist
                year: model.year
                numTracks: model.numTracks
                genre: model.genre

                onClicked: {
                    console.debug("Clicked album:", album);
                    root.albumSelected(album, artist);
                }
                onPlayAlbum: root.playAlbum(album, index)
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: tracksListViewComponent
        ListView {
            id: tracksListView
            model: TracksModel
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
                    icon.source: "qrc:/icons/more_vert-black-48dp.svg"
                    onClicked: root.editTrackMetadata(model.url)
                    ToolTip.text: qsTr("Edit Track Metadata")
                    ToolTip.visible: hovered
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: genresListViewComponent
        ListView {
            id: genresListView
            model: SqlQueryModel {
                id: genresModel
                db: DbIndexer.dbName
                query: "SELECT genre, (SELECT COUNT(s.url) FROM Tracks AS s WHERE s.genre=t.genre) AS count FROM Tracks AS t %1 GROUP BY genre"
                .arg(priv.searchText ? "WHERE genre LIKE '%%1%'".arg(escapeSingleQuote(priv.searchText)) : "")
            }
            clip: true
            delegate: CustomItemDelegate {
                width: ListView.view.width
                text: modelData
                secondaryText: qsTr("%n track(s)", "", genresModel.get(index, "count") ?? 0)
                onClicked: {
                    console.debug("Clicked genre:", modelData);
                    root.genreSelected(modelData);
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
