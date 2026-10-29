import QtQuick
import qs.services

ColorAnimation {
    duration: Theme.durations.slowEffects
    easing.type: Easing.BezierSpline
    easing.bezierCurve: Theme.curves.slowEffects
}
