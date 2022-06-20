import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0

ItemDelegate {
    id: root

    property string album
    property string artist: ""
    property string year: "????"
    property string numTracks: "?"
    property string genre: ""

    signal playAlbum(string album, int index)

    contentItem: Column {
        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            source: MusicIndexer.coverArtForAlbum(root.album)
            asynchronous: true
            width: 150
            height: width
            sourceSize: Qt.size(width, height)

            RoundButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 5
                width: 48
                height: 48
                icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                onClicked: {
                    root.playAlbum(root.album, 0);
                }
                highlighted: true
            }
        }

        Label {
            width: parent.width
            font.pixelSize: root.font.pixelSize * 1.1
            maximumLineCount: 1
            elide: Label.ElideRight
            horizontalAlignment: Label.AlignHCenter
            text: root.album
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
            text: "%1 · %2 𝅘𝅥 · %3".arg(root.year).arg(root.numTracks).arg(root.genre)
        }
    }
}
