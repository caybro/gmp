import QtQuick 2.12
import QtQuick.Controls 2.12

import org.gmp.model 1.0

Page {
    id: root
    objectName: "GenreOverviewPage"
    title: "%1 · %2".arg(genre).arg(qsTr("%n track(s)", "", listview.count))

    property string genre

    property var toolbarAction: Component {
        Row {
            ToolButton {
                icon.source: "qrc:/icons/ic_play_arrow_48px.svg"
                onClicked: root.playGenre(root.genre)
                ToolTip.text: qsTr("Play Genre")
                ToolTip.visible: hovered
            }
            ToolButton {
                icon.source: "qrc:/icons/ic_shuffle_48px.svg"
                onClicked: root.shufflePlayGenre(root.genre)
                ToolTip.text: qsTr("Play Genre in Random Order")
                ToolTip.visible: hovered
            }
        }
    }

    signal playRequested(url playFileUrl)
    signal playGenre(string genre)
    signal shufflePlayGenre(string genre)
    signal editTrackMetadata(url track)


    ListView {
        id: listview
        anchors.fill: parent
        model: GenericProxyModel {
            sourceModel: TracksModel
            filterRole: TracksModel.RoleGenre
            filterRegExp: new RegExp("^" + root.genre + "$", 'g')
            sortRole: TracksModel.RoleTitle
        }
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
    }
}
