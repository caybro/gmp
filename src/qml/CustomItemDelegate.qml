import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.impl 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Controls.Material.impl 2.12

ItemDelegate {
    id: control

    property string secondaryText: ""
    property string tertiaryText: ""

    contentItem: Column {
        width: control.width
        spacing: 5
        IconLabel {
            width: parent.width
            spacing: control.spacing
            mirrored: control.mirrored
            display: control.display
            alignment: control.display === IconLabel.IconOnly || control.display === IconLabel.TextUnderIcon ? Qt.AlignCenter : Qt.AlignLeft

            icon: control.icon
            text: control.text.replace('&', '&&')
            font: control.font
            color: control.enabled ? control.Material.foreground : control.Material.hintTextColor
        }
        IconLabel {
            width: parent.width
            spacing: control.spacing
            mirrored: control.mirrored
            display: control.display
            alignment: control.display === IconLabel.IconOnly || control.display === IconLabel.TextUnderIcon ? Qt.AlignCenter : Qt.AlignLeft

            text: control.secondaryText.replace('&', '&&')
            font.family: control.font.family
            font.bold: control.font.bold
            font.italic: control.font.italic
            font.weight: control.font.weight
            font.pixelSize: control.font.pixelSize * 0.9
            color: control.enabled ? control.Material.foreground : control.Material.hintTextColor
        }
        IconLabel {
            width: parent.width
            spacing: control.spacing
            mirrored: control.mirrored
            display: control.display
            alignment: control.display === IconLabel.IconOnly || control.display === IconLabel.TextUnderIcon ? Qt.AlignCenter : Qt.AlignLeft

            text: control.tertiaryText
            font.family: control.font.family
            font.bold: control.font.bold
            font.italic: control.font.italic
            font.weight: control.font.weight
            font.pixelSize: control.font.pixelSize * 0.8
            color: control.enabled ? control.Material.foreground : control.Material.hintTextColor
        }
    }
}
