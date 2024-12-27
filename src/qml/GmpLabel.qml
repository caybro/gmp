import QtQuick 2.15
import QtQuick.Controls 2.5
import QtQuick.Controls.Material 2.15

Label {
    elide: Text.ElideRight
    linkColor: !!hoveredLink ? Material.accent : Material.foreground
    Behavior on linkColor { ColorAnimation { duration: 100 } }

    HoverHandler {
        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : undefined
    }
}
