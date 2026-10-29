import QtQuick
import qs.services

Text {
    id: root

    property bool animate: false
    property bool mono: false
    property real roundness: 25
    property real widthAxis: 100

    renderType: Text.NativeRendering
    textFormat: Text.PlainText
    color: Theme.palette.m3onSurface
    font.family: mono ? Theme.mono : Theme.sans
    font.pixelSize: Theme.font.bodyMedium
    font.variableAxes: mono ? ({}) : ({ ROND: roundness, wdth: widthAxis })

    Behavior on color {
        CAnim {}
    }
}
