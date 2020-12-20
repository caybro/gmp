import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import org.gmp.model 1.0

Window {
    id: root
    width: 800
    height: 600
    visible: true

    Component {
        id: trackDelegate
        CustomItemDelegate {
            width: ListView.view.width
            text: model.title
            secondaryText: model.artist + " · " + model.album
            onClicked: {
                console.warn("Clicked:", model.url);
            }
        }
    }

    Component {
        id: genericDelegate
        ItemDelegate {
            width: ListView.view.width
            text: modelData
            onClicked: {
                console.warn("Clicked:", modelData);
            }
        }
    }

    ListView {
        anchors.fill: parent
        model: TrackModel.genres
        delegate: genericDelegate

        ScrollIndicator.vertical: ScrollIndicator {}
    }
}
