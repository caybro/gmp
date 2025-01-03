import QtQuick 2.15
import QtQuick.Controls 2.15

import org.gmp.model 1.0

Page {
    id: root
    objectName: "GenreOverviewPage"
    title: "%1 · %2".arg(genre).arg(qsTr("%n track(s)", "", listview.model.count))

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

    signal enqueueTrack(url track)
    signal enqueueTrackNext(url track)

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
                onClicked: {
                    contextMenu.trackUrl = model.url
                    contextMenu.popup()
                }
            }
        }
        ScrollIndicator.vertical: ScrollIndicator {}
    }

    Menu {
        id: contextMenu

        property url trackUrl

        MenuItem {
            text: qsTr("Edit...")
            icon.source: "qrc:/icons/create-black-48dp.svg"
            onClicked: root.editTrackMetadata(contextMenu.trackUrl)
        }
        MenuItem {
            text: qsTr("Add to queue")
            icon.source: "qrc:/icons/add_to_queue.svg"
            onClicked: root.enqueueTrack(contextMenu.trackUrl)
        }
        MenuItem {
            text: qsTr("Play next")
            icon.source: "qrc:/icons/queue_play_next.svg"
            onClicked: root.enqueueTrackNext(contextMenu.trackUrl)
        }
    }
}
