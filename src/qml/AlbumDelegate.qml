import QtQuick 2.12
import QtQuick.Controls 2.12

ItemDelegate {
    id: root

    property string artist: ""

    contentItem: Column {
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: indexer.coverArtForAlbum(modelData)
            asynchronous: true
            width: 150
            height: width
            sourceSize: Qt.size(width, height)
        }

        Label {
            width: parent.width
            font.pixelSize: root.font.pixelSize * 1.1
            maximumLineCount: 1
            elide: Label.ElideRight
            horizontalAlignment: Label.AlignHCenter
            text: modelData
        }
        Label {
            width: parent.width
            horizontalAlignment: Label.AlignHCenter
            text: root.artist
            visible: !!text
        }
        Label {
            width: parent.width
            horizontalAlignment: Label.AlignHCenter
            maximumLineCount: 1
            elide: Label.ElideRight
            text: "%1 · %2 𝅘𝅥 · %3".arg(indexer.yearForAlbum(modelData))
            .arg(indexer.tracksForAlbum(modelData).length)
            .arg(indexer.genreForAlbum(modelData))
        }
    }
}
