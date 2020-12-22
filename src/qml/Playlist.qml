import QtQuick 2.12
import QtQuick.Controls 2.12
import QtMultimedia 5.12

import org.gmp.model 1.0
import org.gmp.sqlext 1.0

Page {
    id: root
    objectName: "Playlist"
    title: qsTr("Playlist")

    property var playlist

    SqlQueryModel {
        id: queryModel
        db: DbIndexer.dbName
    }

    ListView {
        id: tracksListView
        anchors.fill: parent
        model: root.playlist
        clip: true
        delegate: CustomItemDelegate {
            readonly property bool isPlaying: playlist.currentItemSource === model.source
            width: ListView.view.width
            text: (isPlaying ? "⯈ " : "") + (index + 1) + " · " + queryModel.execHelperQuery("SELECT title FROM Tracks WHERE url='%1'".arg(model.source))
            secondaryText: queryModel.execHelperQuery("SELECT artist FROM Tracks WHERE url='%1'".arg(model.source)) + " · " +
                           queryModel.execHelperQuery("SELECT album FROM Tracks WHERE url='%1'".arg(model.source))
            highlighted: isPlaying
            onClicked: {
                console.debug("Clicked:", model.source);
                playlist.currentIndex = index;
            }
        }

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
