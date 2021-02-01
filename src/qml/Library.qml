import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

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
                onActivated: searchButton.clicked()
            }

            Component.onDestruction: searchField.clear(); // clear when we get unloaded
        }
    }

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
    }

    Component.onCompleted: {
        artistsButton.text = qsTr("Artists") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT artist) FROM Tracks") + ")" ?? "");
        albumsButton.text = qsTr("Albums") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT album) FROM Tracks") + ")" ?? "");
        songsButton.text = qsTr("Songs") + (" (" + queryModel.execHelperQuery("SELECT COUNT(url) FROM Tracks") + ")" ?? "");
        genresButton.text = qsTr("Genres") + (" (" + queryModel.execHelperQuery("SELECT COUNT(DISTINCT genre) FROM Tracks") + ")" ?? "");
    }

    TabBar {
        id: tabbar
        width: parent.width
        TabButton {
            id: artistsButton
        }
        TabButton {
            id: albumsButton
        }
        TabButton {
            id: songsButton
        }
        TabButton {
            id: genresButton
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

    Component {
        id: artistsListViewComponent
        ListView {
            id: artistsListView
            clip: true
            model: SqlQueryModel {
                id: artistsModel
                db: DbIndexer.dbName
                query: "SELECT artist, (SELECT COUNT(DISTINCT s.album) FROM Tracks AS s WHERE s.artist=t.artist) AS count FROM Tracks AS t %1 GROUP BY artist"
                .arg(priv.searchText ? "WHERE artist LIKE '%%1%'".arg(escapeSingleQuote(priv.searchText)) : "")
            }
            delegate: CustomItemDelegate {
                width: ListView.view.width
                text: modelData
                secondaryText: qsTr("%n album(s)", "", Number(artistsModel.get(index, "count")))
                onClicked: {
                    console.debug("Clicked artist:", modelData);
                    root.artistSelected(modelData);
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }

    Component {
        id: albumsListViewComponent
        GridView {
            id: albumsListView
            model: SqlQueryModel {
                id: albumsModel
                db: DbIndexer.dbName
                query: "SELECT album, artist, year, genre, (SELECT COUNT(DISTINCT s.url) FROM Tracks AS s WHERE s.album=t.album) AS count FROM Tracks AS t %1 GROUP BY album"
                .arg(priv.searchText ? "WHERE album LIKE '%%1%'".arg(escapeSingleQuote(priv.searchText)) : "")
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
                    console.debug("Clicked album:", modelData);
                    root.albumSelected(modelData, artist);
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
            model: SqlQueryModel {
                id: tracksModel
                db: DbIndexer.dbName
                query: "SELECT url, title, album, artist FROM Tracks %1 ORDER BY title"
                .arg(priv.searchText ? "WHERE title LIKE '%%1%'".arg(escapeSingleQuote(priv.searchText)) : "")
            }
            clip: true
            delegate: CustomItemDelegate {
                readonly property bool isPlaying: Player.currentPlayUrl == modelData
                width: ListView.view.width
                text: (isPlaying ? "⯈ " : "") + tracksModel.get(index, "title")
                secondaryText: tracksModel.get(index, "artist") + " · " + tracksModel.get(index, "album")
                highlighted: isPlaying
                onClicked: {
                    console.debug("Clicked track:", modelData);
                    root.playRequested(modelData);
                }
                ToolButton {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    icon.source: "qrc:/icons/more_vert-black-48dp.svg"
                    onClicked: root.editTrackMetadata(modelData)
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
                secondaryText: qsTr("%n track(s)", "", genresModel.get(index, "count"))
                onClicked: {
                    console.debug("Clicked genre:", modelData);
                    root.genreSelected(modelData);
                }
            }

            ScrollIndicator.vertical: ScrollIndicator {}
        }
    }
}
