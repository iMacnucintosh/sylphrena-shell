import QtQuick
import M3Shapes
import qs.services

MaterialShape {
    id: root

    property int shapeIndex
    property list<int> shapes: [MaterialShape.SoftBurst, MaterialShape.Cookie9Sided, MaterialShape.Pentagon, MaterialShape.Pill, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Oval]

    implicitSize: 18
    color: Theme.palette.m3primary
    shape: shapes[shapeIndex % shapes.length]

    Timer {
        interval: 650
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: root.shapeIndex = (root.shapeIndex + 1) % root.shapes.length
    }

    RotationAnimation on rotation {
        running: root.visible
        from: 0
        to: 360
        duration: 4666
        loops: Animation.Infinite
    }
}
