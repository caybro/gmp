import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0

ItemDelegate {
    id: root

    property string artist: ""
    property string year: "????"
    property string numTracks: "?"
    property string genre: ""

    contentItem: Column {
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: DbIndexer.coverArtForAlbum(modelData)
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
            maximumLineCount: 1
            elide: Label.ElideRight
            text: root.artist
            visible: !!text
        }
        Label {
            width: parent.width
            horizontalAlignment: Label.AlignHCenter
            maximumLineCount: 1
            elide: Label.ElideRight
            text: "%1 · %2 𝅘𝅥 · %3".arg(root.year)
            .arg(root.numTracks)
            .arg(root.genre)
        }
    }
}
