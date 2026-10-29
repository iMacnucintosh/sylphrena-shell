import QtQuick
import qs.services

StyledText {
    id: root

    property real fill: 0
    property int grade: Theme.light ? 0 : -25
    property int iconSize: Theme.font.iconMedium

    mono: true
    font.family: Theme.icons
    font.pixelSize: iconSize
    font.variableAxes: ({ FILL: fill, wght: 400, GRAD: grade, opsz: Math.max(20, Math.min(48, iconSize)) })
}
