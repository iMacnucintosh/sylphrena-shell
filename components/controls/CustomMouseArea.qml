import QtQuick

MouseArea {
    property int scrollAccumulatedY: 0
    // false: wheel events are not consumed, so they reach whatever is underneath/above
    property bool wheelEnabled: true

    function onWheel(event: WheelEvent): void {
    }

    onWheel: event => {
        if (!wheelEnabled) {
            event.accepted = false;
            return;
        }
        // Update accumulated scroll
        if (Math.sign(event.angleDelta.y) !== Math.sign(scrollAccumulatedY))
            scrollAccumulatedY = 0;
        scrollAccumulatedY += event.angleDelta.y;

        // Trigger handler and reset if above threshold
        if (Math.abs(scrollAccumulatedY) >= 120) {
            onWheel(event);
            scrollAccumulatedY = 0;
        }
    }
}
