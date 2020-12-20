import QtQuick 2.12
import QtQuick.Controls 2.12

Page {
    id: root
    objectName: "AlbumsOverview"
    title: "%1 · %2".arg(artist).arg(qsTr("%n album(s)", "", gridview.count))

    property string artist

    signal albumSelected(string album)

    GridView {
        id: gridview
        anchors.fill: parent
        cellWidth: 200
        cellHeight: 240
        model: indexer.albumsForArtist(root.artist)
        delegate: AlbumDelegate {
            onClicked: {
                console.debug("Clicked:", modelData);
                root.albumSelected(modelData);
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
