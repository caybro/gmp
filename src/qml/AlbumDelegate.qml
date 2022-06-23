import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0

ItemDelegate {
    id: root

    signal playAlbum(string album, int index)

    contentItem: Column {
        AlbumCover {
            image: model.coverImage
            anchors.horizontalCenter: parent.horizontalCenter

            RoundButton {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 5
                width: 48
                height: 48
                icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                onClicked: root.playAlbum(model.album, 0)
                highlighted: true
            }
        }

        Label {
            width: parent.width
            font.pixelSize: root.font.pixelSize * 1.1
            maximumLineCount: 1
            elide: Label.ElideRight
            horizontalAlignment: Label.AlignHCenter
            text: model.album
        }
        Label {
            width: parent.width
            horizontalAlignment: Label.AlignHCenter
            maximumLineCount: 1
            elide: Label.ElideRight
            text: model.artist
            visible: !!text
        }
        Label {
            width: parent.width
            horizontalAlignment: Label.AlignHCenter
            maximumLineCount: 1
            elide: Label.ElideRight
            text: "%1 · %2 𝅘𝅥 · %3".arg(model.year ?? "????").arg(model.numTracks ?? "?").arg(model.genre ?? "")
        }
    }
}
