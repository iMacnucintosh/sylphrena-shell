pragma ComponentBehavior: Bound

import QtQuick
import qs.components
import qs.services

// Same construction as the lock clock: condensed Google Sans Flex digits,
// hours in primary and minutes in secondary.
Item {
    id: root

    required property real centerScale

    function calcTopOff(metrics: TextMetrics): real {
        return metrics.tightBoundingRect.y - metrics.boundingRect.y;
    }

    implicitWidth: hours.implicitWidth + minutes.implicitWidth + Theme.spacing.small
    implicitHeight: hourMetrics.tightBoundingRect.height

    StyledText {
        id: hours

        y: -root.calcTopOff(hourMetrics)
        text: Time.hourStr
        color: Theme.palette.m3primary
        widthAxis: 30
        font.pixelSize: Math.round(298 * root.centerScale)

        TextMetrics {
            id: hourMetrics

            text: hours.text
            font: hours.font
        }
    }

    StyledText {
        id: minutes

        anchors.right: parent.right
        y: -root.calcTopOff(minuteMetrics)
        text: Time.minuteStr
        color: Theme.palette.m3secondary
        widthAxis: 30
        font.pixelSize: Math.round(298 * root.centerScale)

        TextMetrics {
            id: minuteMetrics

            text: minutes.text
            font: minutes.font
        }
    }
}
